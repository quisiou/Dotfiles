/* quickshell/src/get_gpu_info.c */


#define _DEFAULT_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <fcntl.h>
#include <signal.h>
#include <dirent.h>
#include <dlfcn.h>

#define PATH_BUF 1024

/* ---------- backend interface ---------- */

typedef struct {
    const char *name;
    int  (*init)(void);
    int  (*read)(double *usage, double *temp); /* 0 = success */
    void (*shutdown)(void);
} GpuBackend;

static volatile sig_atomic_t running = 1;
static void handle_signal(int sig) { (void)sig; running = 0; }

/* ---------- vendor detection (universal across all GPUs) ---------- */

static int vendor_matches(const char *device_path, const char *vendor_id) {
    char vpath[PATH_BUF], buf[16] = {0};
    int n = snprintf(vpath, sizeof(vpath), "%s/vendor", device_path);
    if (n < 0 || (size_t)n >= sizeof(vpath)) return 0; /* path too long, bail safely */

    FILE *f = fopen(vpath, "r");
    if (!f) return 0;
    if (!fgets(buf, sizeof(buf), f)) { fclose(f); return 0; }
    fclose(f);
    return strncmp(buf, vendor_id, strlen(vendor_id)) == 0;
}

/* Finds the first /sys/class/drm/cardN/device matching vendor_id.
   Writes the device path into out_path. Returns 1 if found. */
static int find_card_device(const char *vendor_id, char *out_path, size_t out_len) {
    DIR *dir = opendir("/sys/class/drm");
    if (!dir) return 0;

    struct dirent *entry;
    int found = 0;

    while ((entry = readdir(dir)) != NULL && !found) {
        if (strncmp(entry->d_name, "card", 4) != 0) continue;
        /* skip cardN-XXX connector entries, only want bare cardN */
        if (strchr(entry->d_name, '-') != NULL) continue;

        char path[PATH_BUF];
        int n = snprintf(path, sizeof(path), "/sys/class/drm/%s/device", entry->d_name);
        if (n < 0 || (size_t)n >= sizeof(path)) continue; /* path too long, skip safely */

        if (vendor_matches(path, vendor_id)) {
            snprintf(out_path, out_len, "%s", path);
            found = 1;
        }
    }

    closedir(dir);
    return found;
}

/* ============================================================ */
/* NVIDIA backend (NVML via dlopen, no headers/linking required) */
/* ============================================================ */

typedef int    nvmlReturn_t;
typedef void  *nvmlDevice_t;
typedef struct { unsigned int gpu; unsigned int memory; } nvmlUtilization_t;

#define NVML_TEMPERATURE_GPU 0
#define NVML_SUCCESS 0

typedef nvmlReturn_t (*nvmlInit_t)(void);
typedef nvmlReturn_t (*nvmlShutdown_t)(void);
typedef nvmlReturn_t (*nvmlDeviceGetHandleByIndex_t)(unsigned int, nvmlDevice_t *);
typedef nvmlReturn_t (*nvmlDeviceGetUtilizationRates_t)(nvmlDevice_t, nvmlUtilization_t *);
typedef nvmlReturn_t (*nvmlDeviceGetTemperature_t)(nvmlDevice_t, int, unsigned int *);

static void *nv_handle = NULL;
static nvmlDevice_t nv_device;
static nvmlInit_t nvmlInit_fn;
static nvmlShutdown_t nvmlShutdown_fn;
static nvmlDeviceGetHandleByIndex_t nvmlDeviceGetHandleByIndex_fn;
static nvmlDeviceGetUtilizationRates_t nvmlDeviceGetUtilizationRates_fn;
static nvmlDeviceGetTemperature_t nvmlDeviceGetTemperature_fn;

static void *load_nvml(void) {
    const char *candidates[] = {
        "libnvidia-ml.so.1",                        /* standard distros */
        "/run/opengl-driver/lib/libnvidia-ml.so.1",  /* NixOS */
        NULL
    };
    for (int i = 0; candidates[i] != NULL; i++) {
        void *h = dlopen(candidates[i], RTLD_LAZY);
        if (h) return h;
    }
    return NULL;
}

static int nvidia_init(void) {
    nv_handle = load_nvml();
    if (!nv_handle) return 1;

    nvmlInit_fn = (nvmlInit_t)dlsym(nv_handle, "nvmlInit_v2");
    nvmlShutdown_fn = (nvmlShutdown_t)dlsym(nv_handle, "nvmlShutdown");
    nvmlDeviceGetHandleByIndex_fn =
        (nvmlDeviceGetHandleByIndex_t)dlsym(nv_handle, "nvmlDeviceGetHandleByIndex_v2");
    nvmlDeviceGetUtilizationRates_fn =
        (nvmlDeviceGetUtilizationRates_t)dlsym(nv_handle, "nvmlDeviceGetUtilizationRates");
    nvmlDeviceGetTemperature_fn =
        (nvmlDeviceGetTemperature_t)dlsym(nv_handle, "nvmlDeviceGetTemperature");

    if (!nvmlInit_fn || !nvmlShutdown_fn || !nvmlDeviceGetHandleByIndex_fn ||
        !nvmlDeviceGetUtilizationRates_fn || !nvmlDeviceGetTemperature_fn) {
        dlclose(nv_handle);
        return 1;
    }

    if (nvmlInit_fn() != NVML_SUCCESS) {
        dlclose(nv_handle);
        return 1;
    }

    if (nvmlDeviceGetHandleByIndex_fn(0, &nv_device) != NVML_SUCCESS) {
        nvmlShutdown_fn();
        dlclose(nv_handle);
        return 1;
    }

    return 0;
}

static int nvidia_read(double *usage, double *temp) {
    nvmlUtilization_t util = {0, 0};
    unsigned int t = 0;

    nvmlReturn_t r1 = nvmlDeviceGetUtilizationRates_fn(nv_device, &util);
    nvmlReturn_t r2 = nvmlDeviceGetTemperature_fn(nv_device, NVML_TEMPERATURE_GPU, &t);

    *usage = (r1 == NVML_SUCCESS) ? (double)util.gpu : 0;
    *temp  = (r2 == NVML_SUCCESS) ? (double)t : 0;
    return (r1 == NVML_SUCCESS && r2 == NVML_SUCCESS) ? 0 : 1;
}

static void nvidia_shutdown(void) {
    if (nvmlShutdown_fn) nvmlShutdown_fn();
    if (nv_handle) dlclose(nv_handle);
}

static GpuBackend nvidia_backend = { "nvidia", nvidia_init, nvidia_read, nvidia_shutdown };

/* ============================================================ */
/* AMD backend (pure sysfs, no linking, no dlopen)               */
/* ============================================================ */

static char amd_busy_path[PATH_BUF] = {0};
static char amd_temp_path[PATH_BUF] = {0};
static int  amd_busy_fd = -1;
static int  amd_temp_fd = -1;

static double read_val(const char *path) {
    FILE *f = fopen(path, "r");
    if (!f) return 0;
    double val = 0;
    if (fscanf(f, "%lf", &val) != 1) val = 0;
    fclose(f);
    return val;
}

static double read_val_fd(int fd) {
    if (fd < 0) return 0;
    char buf[32];
    ssize_t n = pread(fd, buf, sizeof(buf) - 1, 0);
    if (n <= 0) return 0;
    buf[n] = '\0';
    double val = 0;
    if (sscanf(buf, "%lf", &val) != 1) val = 0;
    return val;
}

/* Same startup-caching pattern as get_cpu.c's hwmon scan,
   but matched to the AMD card's own hwmon subdirectory. */
static int find_amd_temp_path(const char *card_device_path, char *out_path, size_t out_len) {
    char hwmon_dir[PATH_BUF];
    int n = snprintf(hwmon_dir, sizeof(hwmon_dir), "%s/hwmon", card_device_path);
    if (n < 0 || (size_t)n >= sizeof(hwmon_dir)) return 0; /* path too long, bail safely */

    DIR *dir = opendir(hwmon_dir);
    if (!dir) return 0;

    struct dirent *entry;
    int found = 0;

    while ((entry = readdir(dir)) != NULL && !found) {
        if (entry->d_name[0] == '.') continue;
        char temp_input[PATH_BUF];
        int m = snprintf(temp_input, sizeof(temp_input), "%s/%s/temp1_input", hwmon_dir, entry->d_name);
        if (m < 0 || (size_t)m >= sizeof(temp_input)) continue; /* path too long, skip safely */
        FILE *f = fopen(temp_input, "r");
        if (f) {
            fclose(f);
            snprintf(out_path, out_len, "%s", temp_input);
            found = 1;
        }
    }

    closedir(dir);
    return found;
}

static int amd_init(void) {
    char device_path[PATH_BUF];
    if (!find_card_device("0x1002", device_path, sizeof(device_path))) return 1;

    int n = snprintf(amd_busy_path, sizeof(amd_busy_path), "%s/gpu_busy_percent", device_path);
    if (n < 0 || (size_t)n >= sizeof(amd_busy_path)) return 1;

    amd_busy_fd = open(amd_busy_path, O_RDONLY);
    if (amd_busy_fd < 0) return 1;

    if (find_amd_temp_path(device_path, amd_temp_path, sizeof(amd_temp_path))) {
        amd_temp_fd = open(amd_temp_path, O_RDONLY); // -1 is fine, handled downstream
    }

    return 0;
}

static int amd_read(double *usage, double *temp) {
    *usage = read_val_fd(amd_busy_fd);
    *temp = amd_temp_fd >= 0 ? (read_val_fd(amd_temp_fd) / 1000.0) : 0;
    return 0;
}

static void amd_shutdown(void) {
    if (amd_busy_fd >= 0) close(amd_busy_fd);
    if (amd_temp_fd >= 0) close(amd_temp_fd);
}

static GpuBackend amd_backend = { "amd", amd_init, amd_read, amd_shutdown };

/* ============================================================ */
/* Intel backend - not yet implemented                           */
/* No simple sysfs busy-percent file across driver generations;  */
/* needs i915/Xe PMU perf counters or debugfs (often root-only). */
/* ============================================================ */

/* ---------- main ---------- */

int main(int argc, char *argv[]) {
    int interval_ms = 1000;
    if (argc > 1) {
        interval_ms = atoi(argv[1]);
        if (interval_ms <= 0) interval_ms = 1000;
    }

    signal(SIGINT, handle_signal);
    signal(SIGTERM, handle_signal);

    GpuBackend *backend = NULL;

    if (find_card_device("0x10de", (char[PATH_BUF]){0}, PATH_BUF) && nvidia_init() == 0) {
        backend = &nvidia_backend;
    } else if (find_card_device("0x1002", (char[PATH_BUF]){0}, PATH_BUF) && amd_init() == 0) {
        backend = &amd_backend;
    }

    if (!backend) {
        fprintf(stderr, "no supported GPU backend found\n");
        return 1;
    }

    setvbuf(stdout, NULL, _IOLBF, 0);

    while (running) {
        double usage = 0, temp = 0;
        backend->read(&usage, &temp);
        printf("{\"vendor\": \"%s\", \"perc\": %.2f, \"temp\": %.2f}\n",
               backend->name, usage, temp);
        fflush(stdout);
        usleep(interval_ms * 1000);
    }

    backend->shutdown();
    return 0;
}
