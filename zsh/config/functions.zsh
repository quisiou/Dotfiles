#!/usr/bin/env zsh
# zsh/default/functions.zsh


_bthdevs_auto_completions() {
    # Grab all MAC addresses of paired devices as an array, with that extra parenthesis (...)
    _mac_addresses_paired=($(bluetoothctl devices Paired | awk '/^Device/{print $2}'))

    # Tell zsh to use them as completion options
    compadd -a _mac_addresses_paired
}
compdef _bthdevs_auto_completions bthconn bthinfo


_ask_yes_or_no() {
    if [ $# -ne 1 ]; then
        echo "Error: Too many arguments."
        return -1
    fi

    _yn_msg="$1"
    _yn_key=""
    while true; do
        printf "%s [Y/n] " "$_yn_msg"
        read _yn_key
        echo

        case "$_yn_key" in
            [Yy]*|"") return 0 ;;  # 0 = Success (Yes). Also allows Enter for default Yes.
            [Nn]*)    return 1 ;;  # 1 = Failure (No)
        esac
    done
}


# C/C++ project set-up
makecxx() {
    _mc_project_name=""
    _mc_flag_name=0

    _mc_executable_name=""
    _mc_flag_executable=0

    _mc_flag_help=0
    _mc_read_args=0

    _mc_flag_headers=0
    _mc_header_files=""  # Handled as a space-separated string instead of an array

    _mc_flag_main=0
    _mc_flag_vscode=0
    _mc_flag_c=0
    _mc_flag_version=0

    _mc_version=""
    _mc_original_c_ver=17
    _mc_original_cpp_ver=20

    _mc_file_ext="cpp"
    _mc_compiler="g++"
    _mc_compiler_loc=""

    if [ "$#" -eq 0 ]; then
        _mc_flag_help=1
    fi

    while [ "$#" -gt 0 ]; do
        if [ "$_mc_flag_help" -eq 1 ]; then
            break
        fi

        _mc_read_args=$((_mc_read_args + 1))

        case "$1" in
            -h|--help)
                _mc_flag_help=1
                shift
                ;;
            -n|--name)
                shift
                if [ "$#" -eq 0 ]; then
                    echo "Error: No value provided after --name." >&2
                    return 1
                fi
                case "$1" in
                    -*)
                        echo "Error: No value provided after --name." >&2
                        return 1
                        ;;
                esac
                _mc_flag_name=1
                _mc_project_name="$1"
                shift
                ;;
            -e|--exec)
                shift
                if [ "$#" -eq 0 ]; then
                    echo "Error: No value provided after --exec." >&2
                    return 1
                fi
                case "$1" in
                    -*)
                        echo "Error: No value provided after --exec." >&2
                        return 1
                        ;;
                esac
                _mc_flag_executable=1
                _mc_executable_name="$1"
                shift
                ;;
            -v|--version)
                shift
                if [ "$#" -eq 0 ]; then
                    echo "Error: No value provided after --version." >&2
                    return 1
                fi
                case "$1" in
                    -*)
                        echo "Error: No value provided after --version." >&2
                        return 1
                        ;;
                esac
                _mc_version="$1"
                _mc_flag_version=1
                shift
                ;;
            -H|--headers)
                _mc_flag_headers=1
                shift

                # Collect filenames until next flag or end using POSIX string accumulation
                while [ "$#" -gt 0 ]; do
                    case "$1" in
                        -*) break ;; # Found a flag, stop tracking headers
                        *)
                            _mc_header_files="$_mc_header_files $1"
                            shift
                            ;;
                    esac
                done
                ;;
            -m|--main)
                _mc_flag_main=1
                shift
                ;;
            -vs|--vscode)
                _mc_flag_vscode=1
                shift
                ;;
            -c|--c-files)
                _mc_flag_c=1
                shift
                ;;
            *) # unknown option
                echo "Unknown option: $1" >&2
                return 1
                ;;
        esac
    done

    if [ "$_mc_flag_help" -eq 1 ]; then
        if [ "$#" -gt 0 ] || [ "$_mc_read_args" -gt 1 ]; then
            echo "Error: --help must be used alone, with no other arguments." >&2
            return 1
        else
            cat <<'EOF'
Usage: makecxx -n PROJECT_NAME [OPTIONS] [FILES]
Creates a new C/C++ project environment.
Required:
    -c,     --c-files                           Create a pure C project instead of C++
    -n,     --name          PROJECT_NAME        Provide the project's name

Options:
    -e,     --exec          EXECUTABLE_NAME     Set the name for the executable (project name as default)
    -h,     --help                              Display this help message
    -H,     --headers       FILE1 FILE2 ...     Create header files together with the respective source files
    -m,     --main                              Create a main source file
    -v,     --version       VERSION             Determine the C/C++ version when compiling
    -vs,    --vscode                            Compatibility with Visual Studio Code

Examples:
    makecxx -H file1 file2 -m -n my_project
EOF
            return 0
        fi
    fi

    if [ "$_mc_flag_name" -eq 0 ]; then
        echo "Error: No project name (-n / --name) was provided." >&2
        return 1
    fi

    if [ "$_mc_flag_executable" -eq 0 ]; then
        _mc_executable_name="$_mc_project_name"
    fi

    mkdir "$_mc_project_name" || return 1
    cd "$_mc_project_name" || return 1

    mkdir src
    mkdir include

    if [ "$_mc_flag_c" -eq 0 ]; then
        if [ "$_mc_flag_version" -eq 0 ]; then
            _mc_version="++$_mc_original_cpp_ver"
        else
            _mc_original_cpp_ver="$_mc_version"
            _mc_version="++$_mc_version"
        fi
    else
        _mc_file_ext="c"
        _mc_compiler="gcc"
        if [ "$_mc_flag_version" -eq 0 ]; then
            _mc_version="$_mc_original_c_ver"
        else
            _mc_original_c_ver="$_mc_version"
        fi
    fi

    # MakeFile
    cat > "Makefile" <<EOF
CC = ${_mc_compiler}
FLAGS = -Wall -Wextra -std=c${_mc_version} -g -fsanitize=address -fPIC -O2

LOCAL_INCLUDE = ./include
SYSTEM_INCLUDE = /home/quisiou/.local/include
SYSTEM_LIB = /home/quisiou/.local/lib

INCLUDE = -I\$(LOCAL_INCLUDE) -I\$(SYSTEM_INCLUDE)
SRC = ./src
BUILD = ./.build
OBJDIR = \$(BUILD)/obj
DEPDIR = \$(BUILD)/dep
EXEC_NAME = ${_mc_executable_name}
SOURCES = \$(wildcard \$(SRC)/*.${_mc_file_ext})
OBJECTS = \$(patsubst \$(SRC)/%.${_mc_file_ext},\$(OBJDIR)/%o,\$(SOURCES))
DEPS = \$(patsubst \$(SRC)/%.${_mc_file_ext},\$(DEPDIR)/%d,\$(SOURCES))

ifeq (\$(OS),Windows_NT)
    TARGET = \$(BUILD)/\$(EXEC_NAME).exe
    MKDIR_CMD = @if not exist build mkdir build && if not exist \$(OBJDIR) mkdir \$(OBJDIR) && if not exist \$(DEPDIR) mkdir \$(DEPDIR)
    LDFLAGS = -lws2_32
else
    TARGET = \$(BUILD)/\$(EXEC_NAME)
    MKDIR_CMD = @mkdir -p \$(OBJDIR) \$(DEPDIR)
    LDFLAGS = -L\$(SYSTEM_LIB)
endif

all: \$(TARGET)

\$(TARGET): \$(OBJECTS)
    \$(CC) \$(FLAGS) -o \$@ \$^ \$(LDFLAGS)

\$(OBJDIR)/%o: \$(SRC)/%.${_mc_file_ext}
    \$(MKDIR_CMD)
    \$(CC) \$(FLAGS) \$(INCLUDE) -MMD -MP -c \$< -o \$@ -MF \$(DEPDIR)/\$*d

-include \$(DEPS)

run: \$(TARGET)
    \$(TARGET)

clean:
    rm -rf \$(BUILD)

EOF

    # Visual Studio Code configuration
    if [ "$_mc_flag_vscode" -eq 1 ]; then
        mkdir .vscode

        cat > ".vscode/c_cpp_properties.json" <<EOF
{
    "configurations": [
        {
            "name": "Linux",
            "includePath": [
                "/usr/lib/gcc/x86_64-linux-gnu/14/include",
                "\${workspaceFolder}/include"
            ],
            "defines": [],
            "cStandard": "c${_mc_original_c_ver}",
            "cppStandard": "gnu++${_mc_original_cpp_ver}",
            "intelliSenseMode": "linux-gcc-x64",
            "compilerPath": "/usr/bin/${_mc_compiler}"
        }
    ],
    "version": 4
}
EOF
    fi

    # Execute flags

    # Create header files
    if [ "$_mc_flag_headers" -eq 1 ]; then
        if [ -z "$_mc_header_files" ]; then
            echo "No header files specified" >&2
            return 1
        fi

        # Safely loop over space-separated filenames
        for fname in $_mc_header_files; do
            # POSIX translation tool to substitute '${fname^^}' safely
            _mc_upper_fname=$(echo "$fname" | tr '[a-z]' '[A-Z]')

            # Header file
            cat > "include/${fname}.h" <<EOF
#ifndef ${_mc_upper_fname}_H
#define ${_mc_upper_fname}_H

// Code here

#endif
EOF

            # Source file
            cat > "src/${fname}.${_mc_file_ext}" <<EOF
#include "${fname}.h"

// Code here
EOF
        done
    fi

    if [ "$_mc_flag_main" -eq 1 ]; then
        if [ "$_mc_flag_c" -eq 0 ]; then
            cat > "src/main.cpp" <<'EOF'
#include <iostream>

int main(int argc, char** argv) {
    std::cout << "Num args: " << argc - 1 << "; Args: " << argv << '\n';

    return 0;
}
EOF
        else
            cat > "src/main.c" <<'EOF'
#include <stdio.h>

int main(int argc, char** argv) {
    printf("Num args: %d; Args:", argc - 1);
    for (int i = 1; i < argc; i++) {
        printf(" %s", argv[i]);
    }
    printf("\n");

    return 0;
}
EOF
        fi
    fi

    # Add clangd support (&> converted to > /dev/null 2>&1)
    if [ "$_mc_flag_main" -eq 1 ] && command -v bear > /dev/null 2>&1; then
        echo "Generating compile_commands.json for clangd..."
        bear -- make
    else
        echo "Skipping compile_commands.json generation (bear not found)."
    fi
}


# Scan document to image or pdf
scandoc() {
    _sd_flag_help=0
    _sd_flag_format=0
    _sd_flag_mode=0
    _sd_flag_device=0
    _sd_flag_name=0
    _sd_flag_resolution=0

    _sd_format="png"
    _sd_mode="Color"

    # Matches the exact string found by scanimage -L
    _sd_device="hpaio:/net/ENVY_5640_series?ip=192.168.50.5"
    _sd_name="scan_$(date +%F_%H-%M-%S)"
    _sd_resolution="300"
    _sd_read_args=0

    while [ "$#" -gt 0 ]; do
        _sd_read_args=$((_sd_read_args + 1))
        case "$1" in
            -h|--help)
                _sd_flag_help=1; shift; break ;;
            -m|--mode)
                if [ "$_sd_flag_mode" -eq 1 ]; then echo "Error: Option '$1' used twice." >&2; return 1; fi
                shift
                # SANE modes are case-sensitive; usually 'Color', 'Gray', or 'Lineart'
                if [ -z "$1" ]; then echo "Error: Option -m/--mode requires an argument." >&2; return 1; fi
                _sd_flag_mode=1; _sd_mode="$1"; shift ;;
            -d|--device)
                if [ "$_sd_flag_device" -eq 1 ]; then echo "Error: Option '$1' used twice." >&2; return 1; fi
                shift
                if [ -z "$1" ]; then echo "Error: Option -d/--device requires an argument." >&2; return 1; fi
                _sd_flag_device=1; _sd_device="$1"; shift ;;
            -f|--format)
                if [ "$_sd_flag_format" -eq 1 ]; then echo "Error: Option '$1' used twice." >&2; return 1; fi
                shift
                if [ -z "$1" ]; then echo "Error: Option -f/--format requires an argument." >&2; return 1; fi
                _sd_flag_format=1; _sd_format="$1"; shift ;;
            -n|--name)
                if [ "$_sd_flag_name" -eq 1 ]; then echo "Error: Option '$1' used twice." >&2; return 1; fi
                shift
                if [ -z "$1" ]; then echo "Error: Option -n/--name requires an argument." >&2; return 1; fi
                _sd_flag_name=1; _sd_name="$1"; shift ;;
            -r|--resolution)
                if [ "$_sd_flag_resolution" -eq 1 ]; then echo "Error: Option '$1' used twice." >&2; return 1; fi
                shift
                if [ -z "$1" ]; then echo "Error: Option -r/--resolution requires an argument." >&2; return 1; fi
                _sd_flag_resolution=1; _sd_resolution="$1"; shift ;;
            *)
                echo "Error: Unknown option '$1'. Use --help." >&2
                return 1 ;;
        esac
    done

    if [ "$_sd_flag_help" -eq 1 ]; then
        cat <<EOF
Usage: scandoc [OPTIONS]
Options:
    -d, --device      Device URI (Current: $_sd_device)
    -f, --format      png, tiff, pdf (Default: png)
    -m, --mode        Color, Gray, Lineart (Default: Color)
    -n, --name        Output filename (No extension)
    -r, --resolution  DPI (Default: 300)
EOF
        return 0
    fi

    echo "Scanning from HP ENVY (hpaio)..."

    if [ "$_sd_format" = "pdf" ]; then
        # For PDF, we scan to TIFF (lossless) then convert via img2pdf
        scanimage \
            --resolution "$_sd_resolution" \
            --mode "$_sd_mode" \
            -d "$_sd_device" \
            --format=tiff \
            | img2pdf -o "$_sd_name.pdf"
    else
        scanimage \
            --resolution "$_sd_resolution" \
            --mode "$_sd_mode" \
            -d "$_sd_device" \
            --format="$_sd_format" \
            > "$_sd_name.$_sd_format"
    fi

    echo "Done! Saved as $_sd_name.$_sd_format"
}


htb() {
    _htb_flag_help=0
    _htb_flag_boot_only=0
    _htb_flag_clean_only=0
    _htb_flag_proxy=0
    _htb_flag_ssh_only=0
    _htb_flag_running=0
    _htb_read_args=0
    _htb_port_number=2222
    _htb_socks_port=1080
    _htb_qemu_pid=""

    while [ "$#" -gt 0 ]; do
        _htb_read_args=$((_htb_read_args + 1))

        case "$1" in
            -h|--help)
                _htb_flag_help=1
                shift
                break
                ;;
            -b|--boot-only)
                _htb_flag_boot_only=1
                shift
                ;;
            -c|--clean-only)
                _htb_flag_clean_only=1
                shift
                ;;
            -p|--proxy)
                _htb_flag_proxy=1
                shift
                # If next argument is entirely digits, use it as a port
                if [ "$#" -gt 0 ]; then
                    case "$1" in
                        *[!0-9]*) ;; # Contains a non-digit character, do nothing
                        *) _htb_socks_port="$1"; shift ;; # Entirely digits
                    esac
                fi
                ;;
            -r|--running)
                _htb_flag_running=1
                shift
                break
                ;;
            -s|--ssh-only)
                _htb_flag_ssh_only=1
                shift
                ;;
            *) # Unknown option
                echo "Unknown option: $1" >&2
                return 1
                ;;
        esac
    done

    if [ "$_htb_flag_help" -eq 1 ]; then
        if [ "$#" -gt 0 ] || [ "$_htb_read_args" -gt 1 ]; then
            echo "Error: --help must be used alone, with no other arguments." >&2
            return 1
        else
            cat <<'EOF'
Usage: htb [OPTIONS]
Boots up Ubuntu Server VM with a Hack The Box setup.
Options:
    -b,     --boot-only                     Only boot up VM, don't ssh into it after
    -c,     --clean-only                    Only clean up VM process (useful if it didn't terminate by itself)
    -h,     --help                          Display this help message
    -p,     --proxy         [PORT-NUMBER]   Start SOCKS5 proxy on localhost on this terminal (port 1080 by default)
    -r,     --running                       Checks whether the VM and the proxy are running
    -s,     --ssh-only                      Only SSH into VM, don't have to boot it up (it is already up)
EOF
            return 0
        fi
    fi

    if [ "$_htb_flag_running" -eq 1 ]; then
        if [ "$#" -gt 0 ] || [ "$_htb_read_args" -gt 1 ]; then
            echo "Error: --running must be used alone, with no other arguments." >&2
            return 1
        else
            if [ -f /tmp/qemu-htb.pid ]; then
                _htb_qemu_pid=$(cat /tmp/qemu-htb.pid)
                if kill -0 "$_htb_qemu_pid" 2>/dev/null; then
                    echo "[+] VM is running (PID $_htb_qemu_pid)."
                else
                    echo "[-] VM PID file exists but process not running."
                fi
            else
                echo "[-] VM is not running."
            fi

            if [ -f /tmp/qemu-htb-proxy.running ]; then
                echo "[+] Proxy seems to be running."
            else
                echo "[-] Proxy is not running."
            fi
        fi
        return 0
    fi

    if [ "$_htb_flag_proxy" -eq 1 ]; then
        if [ "$#" -gt 0 ] || [ "$_htb_read_args" -gt 1 ]; then
            echo "Error: --proxy must be used alone, with no other arguments." >&2
            return 1
        fi

        if [ ! -f /tmp/qemu-htb.pid ]; then
            echo "[-] Cannot start proxy: VM is not running." >&2
            return 1
        fi

        if nc -z localhost "$_htb_socks_port" >/dev/null 2>&1; then
            echo "[-] Proxy not started: port $_htb_socks_port already in use (maybe by proxy itself)." >&2
            return 1
        fi

        echo "[+] Starting SOCKS5 proxy on localhost:$_htb_socks_port..."
        echo "[!] Proxy will run in foreground. Keep this terminal open to maintain it."

        touch /tmp/qemu-htb-proxy.running
        trap 'rm -f /tmp/qemu-htb-proxy.running; exit' INT TERM EXIT

        ssh -N -D "$_htb_socks_port" -p "$_htb_port_number" kali@localhost

        rm -f /tmp/qemu-htb-proxy.running
        trap - INT TERM EXIT

        return 0
    fi

    # POSIX sh combination logic for complex boolean flags
    if [ "$_htb_flag_clean_only" -eq 1 ] && { [ "$_htb_flag_boot_only" -eq 1 ] || [ "$_htb_flag_ssh_only" -eq 1 ]; }; then
        echo "Error: --clean-only cannot be combined with other flags" >&2
        return 1
    fi

    if [ "$_htb_flag_boot_only" -eq 1 ] && [ "$_htb_flag_ssh_only" -eq 1 ]; then
        echo "Error: --boot-only and --ssh-only cannot be used together" >&2
        return 1
    fi

    if [ "$_htb_socks_port" -lt 1024 ] || [ "$_htb_socks_port" -gt 65535 ]; then
        echo "[-] Invalid proxy port $_htb_socks_port. Must be 1024-65535." >&2
        return 1
    fi

    if [ "$_htb_flag_clean_only" -eq 0 ]; then
        if [ "$_htb_flag_ssh_only" -eq 0 ]; then
            qemu-system-x86_64 \
                -enable-kvm \
                -m 4096 \
                -smp 4 \
                -cpu host \
                -drive file=/home/quisiou/VirtualMachine/kali.qcow2,format=qcow2,if=virtio,aio=io_uring,cache=writeback \
                -netdev user,id=net0,hostfwd=tcp::"$_htb_port_number"-:22 \
                -device virtio-net-pci,netdev=net0 \
                -device virtio-vga \
                -daemonize \
                -display none \
                -pidfile /tmp/qemu-htb.pid

            echo "[+] VM booted up correctly"
        fi

        if [ "$_htb_flag_boot_only" -eq 1 ]; then
            return 0
        fi

        if [ "$_htb_flag_ssh_only" -eq 0 ]; then
            echo "[*] Trying to SSH into VM..."
            until nc -z localhost "$_htb_port_number" >/dev/null 2>&1; do
                sleep 0.5
            done
        fi

        ssh -X -p "$_htb_port_number" kali@localhost
    fi

    if [ "$_htb_flag_boot_only" -eq 0 ] && [ "$_htb_flag_ssh_only" -eq 0 ]; then
        echo "[*] Cleaning up VM resources..."

        if [ -f /tmp/qemu-htb.pid ]; then
            _htb_qemu_pid=$(cat /tmp/qemu-htb.pid)
            if kill -0 "$_htb_qemu_pid" 2>/dev/null; then
                kill "$_htb_qemu_pid" 2>/dev/null || true
            fi
            rm -f /tmp/qemu-htb.pid
            echo "  [+] Successfully killed VM."
        else
            echo "  [-] Could not kill VM (not running)."
        fi
    fi
}


bthconn() {
    _bc_flag_help=0
    _bc_flag_address=0
    _bc_mac_address="04:52:C7:5F:C7:42"
    _bc_read_args=0
    _bc_connected=""

    while [ "$#" -gt 0 ]; do
        _bc_read_args=$((_bc_read_args + 1))

        case "$1" in
            -h|--help)
                _bc_flag_help=1
                shift
                break
                ;;
            *) # Treat as MAC address
                _bc_flag_address=1
                _bc_mac_address="$1"
                shift
                ;;
        esac
    done

    if [ "$_bc_flag_help" -eq 1 ]; then
        if [ "$#" -gt 0 ] || [ "$_bc_read_args" -gt 1 ]; then
            echo "Error: --help must be used alone, with no other arguments." >&2
            return 1
        else
            cat <<'EOF'
Usage: bthconn <MAC ADDRESS>
Connects / disconnects bluetooth device depending on its actual state.
Options:
    -h,     --help      Display this help message

Examples:
    bthconn 00:00:00:00:00:00

EOF
            return 0
        fi
    fi

    # POSIX compatible MAC address format
    case "$_bc_mac_address" in
        [0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F])
            ;; # Valid format, do nothing
        *)
            echo "Error: Incorrect MAC address format." >&2
            return 1
            ;;
    esac

    _bc_connected=$(bluetoothctl info "$_bc_mac_address" | awk -F': ' '/Connected/ {print $2}')

    if [ "$_bc_connected" = "yes" ]; then
        if _ask_yes_or_no "Disconnect device $_bc_mac_address?"; then
            bluetoothctl disconnect "$_bc_mac_address"
        else
            echo "Operation cancelled."
        fi
    else
        bluetoothctl connect "$_bc_mac_address"
    fi
}


bthinfo() {
    _bi_flag_help=0
    _bi_flag_address=0
    _bi_mac_address="04:52:C7:5F:C7:42"
    _bi_read_args=0

    while [ "$#" -gt 0 ]; do
        _bi_read_args=$((_bi_read_args + 1))

        case "$1" in
            -h|--help)
                _bi_flag_help=1
                shift
                break
                ;;
            *) # Treat as MAC address
                _bi_flag_address=1
                _bi_mac_address="$1"
                shift
                ;;
        esac
    done

    if [ "$_bi_flag_help" -eq 1 ]; then
        if [ "$#" -gt 0 ] || [ "$_bi_read_args" -gt 1 ]; then
            echo "Error: --help must be used alone, with no other arguments." >&2
            return 1
        else
            cat <<'EOF'
Usage: bthinfo <MAC ADDRESS>
Displays information on the device.
Options:
    -h,     --help      Display this help message

Examples:
    bthinfo 00:00:00:00:00:00

EOF
            return 0  # Changed to 0 since successfully printing help is a success
        fi
    fi

    # POSIX compatible MAC address format
    case "$_bi_mac_address" in
        [0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F]:[0-9a-fA-F][0-9a-fA-F])
            ;; # Valid format, do nothing
        *)
            echo "Error: Incorrect MAC address format." >&2
            return 1
            ;;
    esac

    bluetoothctl info "$_bi_mac_address"
    echo
}
