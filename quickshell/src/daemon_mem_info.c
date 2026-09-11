/* quickshell/src/get_mem_info.c */


#define _DEFAULT_SOURCE
#include <fcntl.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

static int read_meminfo(int fd, long *total, long *avail) {
    char buf[4096];
    ssize_t n = pread(fd, buf, sizeof(buf) - 1, 0);
    if (n <= 0) return 0;
    buf[n] = '\0';

    long t = -1, a = -1;
    const char *p = buf;
    while (*p && (t < 0 || a < 0)) {
        if (t < 0 && sscanf(p, "MemTotal: %ld kB", &t) == 1) {
            p = strchr(p, '\n');
            if (!p) break;
            p++;
            continue;
        }
        if (a < 0 && sscanf(p, "MemAvailable: %ld kB", &a) == 1) {
            p = strchr(p, '\n');
            if (!p) break;
            p++;
            continue;
        }
        const char *nl = strchr(p, '\n');
        if (!nl) break;
        p = nl + 1;
    }

    *total = t;
    *avail = a;
    return (t >= 0 && a >= 0);
}

int main(int argc, char *argv[]) {
    int interval_ms = 1000;
    if (argc > 1) {
        interval_ms = atoi(argv[1]);
        if (interval_ms <= 0) interval_ms = 1000;
    }

    setvbuf(stdout, NULL, _IOLBF, 0);

    int fd = open("/proc/meminfo", O_RDONLY);
    if (fd < 0) return 1;

    while (1) {
        long total = 0, avail = 0;

        if (read_meminfo(fd, &total, &avail) && total > 0) {
            printf("{\"used\": %.2f, \"total\": %.2f}\n",
                   (double)(total - avail) / (1024 * 1024),
                   (double)total / (1024 * 1024));
            fflush(stdout);
        }

        usleep(interval_ms * 1000);
    }

    close(fd);
    return 0;
}
