/* quickshell/shell/widgets/components/launcher/modes/WallpaperMode.qml */


import QtQuick
import Quickshell
import Quickshell.Io
import ElysianShell.Services

Item {
    id: root

    // ── Public API — mode descriptor (duck-typed, consumed by Launcher) ────
    readonly property string prefix:      "wallpaper"
    readonly property string label:       "Wallpaper"
    readonly property string placeholder: "Select image to set as wallpaper"
    readonly property string icon:        Quickshell.shellDir + "/assets/images/preferences-desktop-wallpaper.svg"
    readonly property string displayMode: "carousel"

    // ── Public API — reactive entries ───────────────────────────────────────
    property var entries: []

    // ── Public API — functions ──────────────────────────────────────────────
    function rescan() {
        root._files = []
        scanner.running = true
    }

    // ── Internal state ───────────────────────────────────────────────────────
    property var _files: []

    function _rebuild() {
        const current = LockService.currentWallpaper.replace(/^file:\/\//, "")
        const idx = root._files.indexOf(current)
        const files = idx > 0
            ? [...root._files.slice(idx), ...root._files.slice(0, idx)]
            : root._files

        entries = files.map(f => ({
            id:      "wp:" + f,
            name:    f.replace(/.*\//, "").replace(/\.[^.]+$/, ""), // filename without ext
            comment: f,
            icon:    f,
            action:  (function(path) {
                return () => {
                    applyProcess.command = [
                        "awww", "img", path,
                        "--transition-type", "fade",
                        "--transition-duration", "1"
                    ]
                    applyProcess.running = true
                }
            })(f)
        }))
    }

    // ── Processes ─────────────────────────────────────────────────────────────
    Process {
        id: scanner
        command: [
            "bash", "-c",
            "find " + Quickshell.env("HOME") + "/.config/awww/ -type f " +
            "\\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) " +
            "-exec realpath {} \\;"
        ]
        stdout: SplitParser {
            onRead: function(line) {
                if (line.trim() !== "") root._files.push(line.trim())
            }
        }
        onExited: {
            root._files = [...root._files]
            LockService.refreshWallpaper()
            root._rebuild()
        }
    }

    Process {
        id: applyProcess
        running: false
    }

    // ── Reactivity ────────────────────────────────────────────────────────────
    // Reorders the carousel whenever the active wallpaper changes elsewhere
    // (e.g. set from outside the launcher), keeping the current one first.
    Connections {
        target: LockService
        function onCurrentWallpaperChanged() { root._rebuild() }
    }

    Component.onCompleted: rescan()
}
