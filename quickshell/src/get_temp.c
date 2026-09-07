/* eww/src/get_temp.c */


#include <stdio.h>
#include <string.h>
#include <dirent.h>

#define BASE_PATH "/sys/class/hwmon"

double read_val(const char* folder, const char* file) {
    char path[600];
    snprintf(path, sizeof(path), "%s/%s", folder, file);
    FILE* f = fopen(path, "r");
    if (!f) return 0;
    double val = 0;
    if (fscanf(f, "%lf", &val) != 1) val = 0;
    fclose(f);
    return val / 1000; // Convert millidegrees to Celsius
}

int main() {
    double cpu_temp = 0;
    double gpu_temp = 0;
    DIR *dir = opendir(BASE_PATH);
    if (!dir) return 1;

    struct dirent *entry;
    while ((entry = readdir(dir)) != NULL) {
        if (entry->d_name[0] == '.') continue;

        char folder[512], name_path[517], name[64];
        snprintf(folder, sizeof(folder), "%s/%s", BASE_PATH, entry->d_name);
        snprintf(name_path, sizeof(name_path), "%s/name", folder);
        
        FILE *nf = fopen(name_path, "r");
        if (!nf) continue;
        if (!fgets(name, sizeof(name), nf)) { fclose(nf); continue; }
        fclose(nf);

        // --- CPU Global Temp ---
        if (strstr(name, "coretemp") || strstr(name, "k10temp")) {
            // Check labels for "Package" or "Tdie"
            for (int i = 1; i <= 3; i++) {
                char lbl_p[524], lbl[64], inp[64];
                snprintf(lbl_p, sizeof(lbl_p), "%s/temp%d_label", folder, i);
                snprintf(inp, sizeof(inp), "temp%d_input", i);
                
                FILE *lf = fopen(lbl_p, "r");
                if (lf) {
                    if (fgets(lbl, sizeof(lbl), lf) && (strstr(lbl, "Package") || strstr(lbl, "Tdie"))) {
                        cpu_temp = read_val(folder, inp);
                    }
                    fclose(lf);
                }
                if (cpu_temp > 0) break;
            }
            // Fallback: use temp1 if no label match
            if (cpu_temp == 0) cpu_temp = read_val(folder, "temp1_input");
        }
        
        // --- GPU Global Temp ---
        if (strstr(name, "amdgpu") || strstr(name, "nv") || strstr(name, "radeon")) {
            // Usually temp1_input is the global/edge temperature
            gpu_temp = read_val(folder, "temp1_input");
        }
    }
    closedir(dir);

    // Output JSON for Eww
    printf("{\"cpu\": %.1lf, \"gpu\": %.1lf}\n", cpu_temp, gpu_temp);

    return 0;
}