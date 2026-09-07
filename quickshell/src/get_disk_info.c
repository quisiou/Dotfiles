/* quickshell/src/get_disk_info.c */


#define _DEFAULT_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/statvfs.h>

// Reads used/total bytes (in GiB) for a given mount path.
static int read_diskinfo(const char *path, double *used_gb, double *total_gb) {
    struct statvfs ds;

    if (statvfs(path, &ds) != 0) {
        return 0;
    }

    double block_size = (double)ds.f_frsize;

    double total_bytes = (double)ds.f_blocks * block_size;
    double free_bytes  = (double)ds.f_bfree  * block_size; // physically free (incl. root-reserved)

    double used_bytes = total_bytes - free_bytes;

    double gib_div = 1024.0 * 1024.0 * 1024.0;
    *total_gb = total_bytes / gib_div;
    *used_gb  = used_bytes / gib_div;

    return 1;
}

int main(int argc, char *argv[]) {
    int interval_ms = 1000;
    if (argc > 1) {
        interval_ms = atoi(argv[1]);
        if (interval_ms <= 0) interval_ms = 1000;
    }

    const char *path = (argc > 2) ? argv[2] : "/";

    setvbuf(stdout, NULL, _IOLBF, 0);

    while (1) {
        double used_gb, total_gb;

        if (read_diskinfo(path, &used_gb, &total_gb)) {
            printf("{\"used\": %.2f, \"total\": %.2f}\n", used_gb, total_gb);
            fflush(stdout);
        } else {
            printf("{\"error\": \"could not read disk stats\"}\n");
            fflush(stdout);
        }

        usleep(interval_ms * 1000);
    }

    return 0;
}
