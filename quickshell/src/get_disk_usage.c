/* eww/src/get_disk_usage.c */


#include <stdio.h>
#include <sys/statvfs.h>

int main() {
    struct statvfs ds;

    // Check statistics for the root directory
    if (statvfs("/", &ds) != 0) {
        printf("{\"error\": \"could not read disk stats\"}\n");
        return 1;
    }

    // f_frsize is the fundamental block size
    double block_size = (double)ds.f_frsize;

    // Total capacity
    double total_bytes = (double)ds.f_blocks * block_size;
    
    // Total physically free blocks (includes root-reserved space)
    double free_bytes = (double)ds.f_bfree * block_size;
    
    // Blocks available to non-privileged users
    double avail_bytes = (double)ds.f_bavail * block_size;

    // Calculation used by 'df' for "Used": Total - All Free
    double used_bytes = total_bytes - free_bytes;

    // Calculation used by 'df' for "Use %": Used / (Used + Available to user)
    // This accounts for the reserved space overhead.
    double percentage = (used_bytes / (used_bytes + avail_bytes)) * 100;

    // Convert to Gibibytes (1024^3)
    double gib_div = 1024.0 * 1024.0 * 1024.0;
    double total_gb = total_bytes / gib_div;
    double used_gb = used_bytes / gib_div;

    // Output JSON
    printf(
        "{\"used\": %.2f, \"used_percentage\": %d, \"total\": %.2f}\n", 
        used_gb,
        (int)percentage, // Truncates like df, or use round() for accuracy
        total_gb
    );

    return 0;
}

