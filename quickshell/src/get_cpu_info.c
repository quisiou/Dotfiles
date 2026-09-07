/* quickshell/src/get_cpu_info.c */


#define _DEFAULT_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <dirent.h>
#include <fcntl.h>

#define BASE_PATH "/sys/class/hwmon"

typedef struct {
    unsigned long long user, nice, system, idle, iowait, irq, softirq, steal;
} CPUStats;

static int stat_fd = -1; // raw fd for /proc/stat
static int temp_fd = -1; // raw fd for the resolved hwmon temp file

static void get_stats(CPUStats *s) {
    if (stat_fd < 0) return;
    char buffer[256];
    ssize_t n = pread(stat_fd, buffer, sizeof(buffer) - 1, 0); // pread always re-reads from the kernel, offset 0
    if (n <= 0) return;
    buffer[n] = '\0';
    sscanf(buffer, "cpu %llu %llu %llu %llu %llu %llu %llu %llu",
        &s->user, &s->nice, &s->system, &s->idle,
        &s->iowait, &s->irq, &s->softirq, &s->steal);
}

static double read_val(void) {
    if (temp_fd < 0) return 0;
    char buffer[32];
    ssize_t n = pread(temp_fd, buffer, sizeof(buffer) - 1, 0);
    if (n <= 0) return 0;
    buffer[n] = '\0';
    double val = 0;
    if (sscanf(buffer, "%lf", &val) != 1) val = 0;
    return val / 1000.0; // millidegrees -> Celsius
}

// Runs ONCE at startup. Finds the temp*_input file for coretemp/k10temp
// and caches its full path so the main loop never has to walk hwmon again.
static int find_cpu_temp_path(char *out_path, size_t out_len) {
    DIR *dir = opendir(BASE_PATH);
    if (!dir) return 0;

    struct dirent *entry;
    int found = 0;

    while ((entry = readdir(dir)) != NULL && !found) {
        if (entry->d_name[0] == '.') continue;

        char folder[512], name_path[550], name[64];
        snprintf(folder, sizeof(folder), "%s/%s", BASE_PATH, entry->d_name);
        snprintf(name_path, sizeof(name_path), "%s/name", folder);

        FILE *nf = fopen(name_path, "r");
        if (!nf) continue;
        if (!fgets(name, sizeof(name), nf)) { fclose(nf); continue; }
        fclose(nf);

        if (!strstr(name, "coretemp") && !strstr(name, "k10temp")) continue;

        for (int i = 1; i <= 3 && !found; i++) {
            char lbl_p[560], lbl[64], inp_p[560];
            snprintf(lbl_p, sizeof(lbl_p), "%s/temp%d_label", folder, i);
            snprintf(inp_p, sizeof(inp_p), "%s/temp%d_input", folder, i);

            FILE *lf = fopen(lbl_p, "r");
            if (lf) {
                if (fgets(lbl, sizeof(lbl), lf) &&
                    (strstr(lbl, "Package") || strstr(lbl, "Tdie"))) {
                    snprintf(out_path, out_len, "%s", inp_p);
                    found = 1;
                }
                fclose(lf);
            }
        }

        if (!found) {
            char inp_p[560];
            snprintf(inp_p, sizeof(inp_p), "%s/temp1_input", folder);
            FILE *tf = fopen(inp_p, "r");
            if (tf) {
                fclose(tf);
                snprintf(out_path, out_len, "%s", inp_p);
                found = 1;
            }
        }
    }

    closedir(dir);
    return found;
}

int main(int argc, char *argv[]) {
    int interval_ms = 1000;
    if (argc > 1) {
        interval_ms = atoi(argv[1]);
        if (interval_ms <= 0) interval_ms = 1000;
    }

    setvbuf(stdout, NULL, _IOLBF, 0);

    char cpu_temp_path[560] = {0};
    int have_temp_path = find_cpu_temp_path(cpu_temp_path, sizeof(cpu_temp_path));

    stat_fd = open("/proc/stat", O_RDONLY);
    if (have_temp_path) {
        temp_fd = open(cpu_temp_path, O_RDONLY);
    }

    while (1) {
        CPUStats s1, s2;

        get_stats(&s1);
        usleep(100000); // 100ms sampling window for the usage delta
        get_stats(&s2);

        unsigned long long idle1 = s1.idle + s1.iowait;
        unsigned long long idle2 = s2.idle + s2.iowait;

        unsigned long long total1 = s1.user + s1.nice + s1.system + s1.idle +
            s1.iowait + s1.irq + s1.softirq + s1.steal;
        unsigned long long total2 = s2.user + s2.nice + s2.system + s2.idle +
            s2.iowait + s2.irq + s2.softirq + s2.steal;

        unsigned long long total_diff = total2 - total1;
        unsigned long long idle_diff = idle2 - idle1;

        double cpu_usage = 0.0;
        if (total_diff != 0) {
            cpu_usage = 100.0 * (total_diff - idle_diff) / total_diff;
        }

        double cpu_temp = temp_fd >= 0 ? read_val() : 0.0;

        printf("{\"used_percentage\": %.0f, \"used_decimals\": %.2f, \"temp\": %.1f}\n",
               cpu_usage, cpu_usage, cpu_temp);
        fflush(stdout);

        usleep(interval_ms * 1000);
    }

    if (stat_fd >= 0) close(stat_fd);
    if (temp_fd >= 0) close(temp_fd);
    return 0;
}
