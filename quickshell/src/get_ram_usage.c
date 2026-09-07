/* eww/src/get_ram_usage.c */


#include <stdio.h>

int main() {
    long total; // Total memory size
    long free;
    long avail; // Available mamory size (not used, but open to use)
    FILE *f;    // File to read info from

    if ((f = fopen("/proc/meminfo", "r")) == NULL) return 1;

    fscanf(f, "MemTotal: %ld kB\nMemFree: %ld kB\nMemAvailable: %ld kB", &total, &free, &avail);
    fclose(f);

    int used_percentage = 100 - (int)((double)avail / total * 100);
    
    printf(
        "{\"used\": %.2f,\"used_percentage\": %d, \"total\": %.2f, \"available\": %.2f}\n",
        (double)(total - avail) / (1024 * 1024),
        used_percentage,
        (double)total / (1024 * 1024),
        (double)avail / (1024 * 1024)
    );

    return 0;
}