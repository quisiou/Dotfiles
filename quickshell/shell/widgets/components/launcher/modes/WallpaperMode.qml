/* quickshell/shell/widgets/components/launcher/modes/WallpaperMode.qml */


import QtQuick
import Quickshell
import Quickshell.Io

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

    property string _currentWallpaper: Quickshell.env("ELYSIAN_DOTS_HOME") + "/wallpapers/Leshy.jpg"

    on_CurrentWallpaperChanged: _rebuild()

    function _rebuild() {
        const current = root._currentWallpaper
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
            "find -L " + Quickshell.env("ELYSIAN_DOTS_HOME") + "/wallpapers -type f " +
            "\\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \\) " +
            "-exec realpath {} \\;"
        ]
        stdout: SplitParser {
            onRead: function(line) {
                if (line.trim() !== "") root._files.push(line.trim())
            }
        }
        // qmllint disable signal-handler-parameters
        onExited: {
            root._files = [...root._files]
            currentQuery.running = true
            root._rebuild()
        }
        // qmllint enable signal-handler-parameters
    }

    Process {
        id: currentQuery
        running: false
        command: [
            "bash", "-c",
            "awww query | awk -F'image: ' '{print $2}' | awk '{print $1}' | xargs realpath"
        ]
        stdout: SplitParser {
            onRead: function(line) {
                if (line.trim() !== "") root._currentWallpaper = line.trim()
            }
        }
    }

    // ── Reactivity ────────────────────────────────────────────────────────────
    Process {
        id: applyProcess
        running: false
    }

    Component.onCompleted: rescan()
}
