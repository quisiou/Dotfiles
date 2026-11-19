/* quickshell/modules/Services/SystemInfo/SystemInfoService.qml */


pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // ── Data ─────────────────────────────────────────
    readonly property string user: Quickshell.env("USER") || ""
    property string hostname: ""
    property string kernel: ""
    property string distroId: ""

    // "Hyprland", "niri", "sway:wlroots" -> first segment only
    readonly property string wm: {
        const d = Quickshell.env("XDG_CURRENT_DESKTOP")
                  || Quickshell.env("XDG_SESSION_DESKTOP") || ""
        return d.split(":")[0] || "Unknown"
    }

    readonly property string session: Quickshell.env("XDG_SESSION_TYPE") || ""
    property string osName: ""

    readonly property string avatarSource: Quickshell.env("ELYSIAN_DOTS_HOME") + "/pfp.png"

    // ── Distro logo (Nerd Font glyphs) ───────────────
    readonly property var _glyphs: ({
        "nixos":    "\uf313",
        "arch":     "\uf303",
        "cachyos":  "\uf385",
        "debian":   "\uf306",
        "ubuntu":   "\uf31b",
        "fedora":   "\uf30a",
        "gentoo":   "\uf30d",
        "alpine":   "\uf300",
        "manjaro":  "\uf312"
    })
    readonly property string distroGlyph: _glyphs[distroId] ?? "\uf17c"   // generic Tux

    // ── Hardware (expanded view) ─────────────────────
    property string cpuModel: ""
    property int cpuCores: 0
    property int cpuThreads: 0
    property string cpuBoost: ""
    property string cpuInfo: ""
    property real ramGbRaw: 0
    property string gpu: ""
    property string storage: ""
    property string storageInfo: ""
    property string board: ""
    property string gpuDriver: ""
    property string renderer: ""
    property var gpus: []   // [{ name, driver, type }] from fastfetch

    readonly property var gpuRows: {
        const list = gpus.length > 0 ? gpus
            : (gpu !== "" ? [{ name: gpu, driver: gpuDriver, type: "" }] : [])
        return list.map(g => ({
            k: g.type === "Integrated" ? "iGPU" : g.type === "Discrete" ? "dGPU" : "GPU",
            v: _shortGpu(g.name),
            sub: _shortDriver(g.driver)
        }))
    }

    // MemTotal is a bit below the installed size (31 GiB on a 32 GB machine),
    // so round up to the next even number to show what you actually bought
    readonly property int ramGb: Math.ceil(ramGbRaw / 2) * 2

    property string wmVersion: ""
    property string loginShell: ""
    property string terminal: ""
    property string terminalVersion: ""

    // ── Display (expanded view) ──────────────────────
    property string panelRes: ""
    property string panelHz: ""
    property string panelScale: ""
    property string panelModel: ""
    property string edidRaw: ""
    property int panelW: 0
    property int panelH: 0
    property string panelVrr: ""
    property string panelDepth: ""
    readonly property string panelSize: _panelSize(edidRaw, panelW, panelH)

    // ── Uptime ───────────────────────────────────────
    property real uptimeSec: 0
    readonly property string uptime: {
        const m = Math.floor(uptimeSec / 60)
        const h = Math.floor(m / 60)
        const d = Math.floor(h / 24)
        if (d > 0) return d + "d " + (h % 24) + "h"
        if (h > 0) return h + "h " + (m % 60) + "m"
        return m + "m"
    }

    function refreshUptime() { uptimeProc.running = true }

    // ── Cleanup helpers ──────────────────────────────
    function _cleanCpu(s) {
        return s.replace(/\(R\)|\(TM\)|\(tm\)/g, "")
                .replace(/ w\/ .*/, "").replace(/ with .*/, "").replace(/ @ .*/, "")
                .replace(/ \d+-Core/, "").replace(/ CPU| Processor/g, "")
                .replace(/\s+/g, " ").trim()
    }
    function _cleanGpu(s) {
        return s.replace(/\s*\(rev [0-9a-f]+\)/i, "")
                .replace("Advanced Micro Devices, Inc. [AMD/ATI]", "AMD")
                .replace("NVIDIA Corporation", "NVIDIA")
                .replace("Intel Corporation", "Intel").trim()
    }
    function _shortGpu(s) {
        return s.replace(/^(NVIDIA|AMD)\s+/, "")
                .replace(/\s*\/\s*Mobile$/i, "")
                .replace(/\s+Graphics$/, "")
                .trim()
    }
    function _shortDriver(s) {
        return s.replace("(open source)", "(open)").replace(/\s+/g, " ").trim()
    }
    function _cleanGl(s) {
        const d = s.match(/(Mesa|NVIDIA)\s+[\d.]+/)
        return d ? d[0] : ""
    }
    function _cleanStorage(s) {
        return s.replace(/\s+/g, " ")
                .replace(/-[0-9A-Z]{3,5}-[0-9A-Z]{3,5}(?=\s)/, "")
                .replace(",", ".")
                .trim()
    }
    function _storInfo(tran, rota, speed, width) {
        const gt = parseFloat(speed) || 0
        const w = parseInt(width) || 0
        if (tran === "nvme") {
            if (gt <= 0 || w <= 0) return "NVMe"
            const gen = gt >= 64 ? 6 : gt >= 32 ? 5 : gt >= 16 ? 4 : gt >= 8 ? 3 : gt >= 5 ? 2 : 1
            const perLane = [0, 0.25, 0.5, 0.985, 1.969, 3.938, 7.563][gen]
            return "NVMe · PCIe " + gen + ".0 ×" + w + " · " + (perLane * w).toFixed(1) + " GB/s"
        }
        if (tran === "sata") return rota === "1" ? "SATA HDD" : "SATA SSD"
        if (tran === "usb") return "USB drive"
        return rota === "1" ? "HDD" : ""
    }
    function _cpuExtra(maxKhz, l3, drv) {
        const parts = []
        const kb = parseInt(l3) || 0
        if (kb > 0) parts.push((kb >= 1024 ? Math.round(kb / 1024) + " MB" : kb + " KB") + " L3")
        if (drv) parts.push(drv)
        return parts.join(" · ")
    }
    function _panelSize(edid, w, h) {
        const b = edid.trim().split(/\s+/).map(Number)
        if (b.length < 3 || b.some(isNaN)) return ""
        const mmW = b[0] + ((b[2] >> 4) << 8)
        const mmH = b[1] + ((b[2] & 15) << 8)
        if (!mmW || !mmH || !w || !h) return ""
        const inch = Math.sqrt(mmW * mmW + mmH * mmH) / 25.4
        return inch.toFixed(1) + "″ · " + Math.round(Math.sqrt(w * w + h * h) / inch) + " PPI"
    }

    // ── Loaders (run once, nothing changes afterwards) ─
    Process {
        command: ["uname", "-nr"]          // "myhost 6.12.4"
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const p = text.trim().split(" ")
                root.hostname = p[0] ?? ""
                root.kernel = p[1] ?? ""
            }
        }
    }

    FileView {
        path: "/etc/os-release"
        onLoaded: {
            const id = text().match(/^ID=(.*)$/m)
            const pretty = text().match(/^PRETTY_NAME=(.*)$/m)
            root.distroId = id ? id[1].replace(/"/g, "") : ""
            root.osName = pretty ? pretty[1].replace(/"/g, "") : ""
        }
    }

    Process {
        command: ["sh", "-c", `
            echo "cpu=$(grep -m1 'model name' /proc/cpuinfo | cut -d: -f2)"
            echo "cores=$(grep -m1 'cpu cores' /proc/cpuinfo | cut -d: -f2)"
            echo "cpumax=$(cat /sys/devices/system/cpu/cpu0/cpufreq/cpuinfo_max_freq 2>/dev/null)"
            echo "cpul3=$(cat /sys/devices/system/cpu/cpu0/cache/index3/size 2>/dev/null)"
            echo "cpudrv=$(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_driver 2>/dev/null)"
            echo "threads=$(nproc --all)"
            echo "ram=$(awk '/MemTotal/{print $2}' /proc/meminfo)"
            echo "gpu=$(lspci 2>/dev/null | grep -E 'VGA|3D|Display' | head -1 | sed 's/^[^ ]* [^:]*: //')"
            echo "board=$(cat /sys/devices/virtual/dmi/id/product_name 2>/dev/null)"
            echo "gpudrv=$(lspci -k 2>/dev/null | awk '/VGA|3D|Display/{f=1;next} f&&/driver in use/{print $NF;exit} f&&/^[0-9a-f]/{f=0}')"
            echo "gl=$( (glxinfo -B 2>/dev/null || eglinfo -B 2>/dev/null) | grep -m1 'version string' | sed 's/.*: //')"
            d=$(lsblk -dno NAME -e7 2>/dev/null | head -1)
            echo "storage=$(lsblk -dno MODEL,SIZE /dev/$d 2>/dev/null)"
            echo "stortran=$(lsblk -dno TRAN /dev/$d 2>/dev/null)"
            echo "storrota=$(cat /sys/block/$d/queue/rotational 2>/dev/null)"
            echo "storspeed=$(cat /sys/block/$d/device/device/max_link_speed 2>/dev/null)"
            echo "storwidth=$(cat /sys/block/$d/device/device/max_link_width 2>/dev/null)"
            echo "login=$(basename "$SHELL")"
            echo "edid=$(od -An -tu1 -j66 -N3 $(ls /sys/class/drm/card*-eDP-*/edid 2>/dev/null | head -1) 2>/dev/null)"
        `]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const v = {}
                for (const line of text.split("\n")) {
                    const i = line.indexOf("=")
                    if (i > 0) v[line.slice(0, i)] = line.slice(i + 1).trim()
                }
                const mhz = parseInt(v.cpumax) || 0
                root.cpuModel = root._cleanCpu(v.cpu ?? "")
                root.cpuCores = parseInt(v.cores) || 0
                root.cpuThreads = parseInt(v.threads) || 0
                root.cpuBoost = mhz > 0 ? (mhz / 1000000).toFixed(1) + " GHz" : ""
                root.cpuInfo = root._cpuExtra(v.cpumax ?? "", v.cpul3 ?? "", v.cpudrv ?? "")
                root.ramGbRaw = (parseInt(v.ram) || 0) / 1048576
                root.gpu = root._cleanGpu(v.gpu ?? "")
                root.board = v.board ?? ""
                root.gpuDriver = v.gpudrv ?? ""
                root.renderer = root._cleanGl(v.gl ?? "")
                root.storage = root._cleanStorage(v.storage ?? "")
                root.storageInfo = root._storInfo(
                    v.stortran ?? "", v.storrota ?? "", v.storspeed ?? "", v.storwidth ?? "")
                root.loginShell = v.login ?? ""
                root.edidRaw = v.edid ?? ""
            }
        }
    }

    Process {
        command: ["fastfetch", "-s", "terminal:gpu", "--format", "json"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const res_gpu = JSON.parse(text).find(m => m.type === "GPU")
                    root.gpus = (res_gpu?.result ?? []).map(g => ({
                        name: g.name ?? "",
                        driver: g.driver ?? "",
                        type: g.type ?? ""
                    }))

                    const res_term = JSON.parse(text).find(m => m.type === "Terminal")?.result
                    const name = res_term?.prettyName || res_term?.processName || ""
                    // Not a terminal: fastfetch found the session or compositor instead
                    if (/^(hyprland|systemd|login|init|qs|\.?quickshell.*|sh|bash|zsh|fish)$/i.test(name))
                        return
                    root.terminal = name
                    root.terminalVersion = (res_term?.version ?? "").match(/\d+(\.\d+)+/)?.[0] ?? ""
                } catch (e) {}
            }
        }
    }

    Process {
        command: ["hyprctl", "monitors", "-j"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const m = JSON.parse(text)[0]
                    root.panelRes = m.width + "×" + m.height
                    root.panelHz = Math.round(m.refreshRate) + " Hz"
                    root.panelScale = m.scale + "×"
                    root.panelModel = m.model ?? ""
                    root.panelW = m.width
                    root.panelH = m.height
                    root.panelVrr = m.vrr ? "On" : "Off"
                    root.panelDepth = (m.currentFormat ?? "").includes("2101010") ? "10-bit" : "8-bit"
                } catch (e) {}
            }
        }
    }

    Process {
        command: ["hyprctl", "version", "-j"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try { root.wmVersion = JSON.parse(text).version ?? "" } catch (e) {}
            }
        }
    }

    Process {
        id: uptimeProc
        command: ["cat", "/proc/uptime"]
        stdout: StdioCollector {
            onStreamFinished: root.uptimeSec = parseFloat(text.split(" ")[0]) || 0
        }
    }
}
