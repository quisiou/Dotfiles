/* quickshell/src/get_mem_info.c */


#define _DEFAULT_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

// Reads MemTotal and MemAvailable from an already-open /proc/meminfo handle.
// rewind() lets us reuse the same FILE* every tick instead of open/close-ing.
static int read_meminfo(FILE *f, long *total, long *avail) {
    rewind(f);
    char line[256];
    long t = -1, a = -1;

    while (fgets(line, sizeof(line), f)) {
        if (t < 0 && sscanf(line, "MemTotal: %ld kB", &t) == 1) continue;
        if (a < 0 && sscanf(line, "MemAvailable: %ld kB", &a) == 1) continue;
        if (t >= 0 && a >= 0) break;
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

    FILE *f = fopen("/proc/meminfo", "r");
    if (!f) return 1;

    while (1) {
        long total = 0, avail = 0;

        if (read_meminfo(f, &total, &avail) && total > 0) {
            int used_percentage = 100 - (int)((double)avail / total * 100);

            printf("{\"used\": %.2f, \"used_percentage\": %d, \"total\": %.2f}\n",
                   (double)(total - avail) / (1024 * 1024),
                   used_percentage,
                   (double)total / (1024 * 1024));
            fflush(stdout);
        }

        usleep(interval_ms * 1000);
    }

    fclose(f);
    return 0;
}
