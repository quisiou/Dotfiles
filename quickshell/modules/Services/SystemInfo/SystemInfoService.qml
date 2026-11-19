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

    // TODO: dummy path, replace with your own
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
            const m = text().match(/^ID=(.*)$/m)
            root.distroId = m ? m[1].replace(/"/g, "") : ""
        }
    }
}
