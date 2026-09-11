/* quickshell/src/get_disk_info.c */


#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/statvfs.h>

// Reads used/total bytes (in GiB) for an already-resolved mount path fd.
// fstatvfs avoids re-walking the path (directory lookups, symlink
// resolution) on every tick the way statvfs(path, ...) would; the fd was
// resolved once at startup and stays pinned to that same target.
static int read_diskinfo(int fd, double *used_gb, double *total_gb) {
    struct statvfs ds;

    if (fstatvfs(fd, &ds) != 0) {
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

    // O_PATH: just a reference to the resolved location, no read
    // permission or regular open-file overhead required — exactly what
    // fstatvfs needs and nothing more.
    int fd = open(path, O_PATH);
    if (fd < 0) {
        printf("{\"error\": \"could not open path\"}\n");
        fflush(stdout);
        return 1;
    }

    while (1) {
        double used_gb, total_gb;

        if (read_diskinfo(fd, &used_gb, &total_gb)) {
            printf("{\"used\": %.2f, \"total\": %.2f}\n", used_gb, total_gb);
            fflush(stdout);
        } else {
            printf("{\"error\": \"could not read disk stats\"}\n");
            fflush(stdout);
        }

        usleep(interval_ms * 1000);
    }

    close(fd);
    return 0;
}
