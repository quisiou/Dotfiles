/* quickshell/shell/widgets/components/launcher/modes/ColorThemeMode.qml */


import QtQuick
import Quickshell
import Quickshell.Io

Item {
    id: root

    // ── Public API — mode descriptor (duck-typed, consumed by Launcher) ────
    readonly property string prefix:      "color-theme"
    readonly property string label:       "Color Theme"
    readonly property string placeholder: "Select a color theme"
    readonly property string icon:        Quickshell.shellDir + "/assets/images/color-palette.svg"
    readonly property string displayMode: "items"

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
        entries = root._files.map(entry => ({
            id:      "ct:" + entry.path,
            name:    entry.name, // filename without ext
            comment: entry.path,
            icon:    Quickshell.shellDir + "/assets/images/preferences-desktop-color",
            action:  (function(path) {
                return () => {
                    vscPackageProcess.command = [
                        "python3",
                        Quickshell.env("HOME") + "/.config/vscodium/build_package.py"
                    ]
                    vscProcess.command = [
                        "python3",
                        Quickshell.env("HOME") + "/.config/vscodium/build_theme.py",
                        path
                    ]
                    ctProcess.command = [
                        "python3",
                        Quickshell.env("HOME") + "/.config/elysian_themes/set_theme.py",
                        path
                    ]
                    ctProcess.running = true
                }
            })(entry.path)
        }))
    }

    // ── Processes ─────────────────────────────────────────────────────────────
    Process {
        id: scanner
        command: [
            Quickshell.shellDir + "/scripts/parse_color_themes.sh",
            Quickshell.env("HOME") + "/.config/elysian_themes/themes"
        ]
        stdout: SplitParser {
            onRead: function(line) {
                if (line.trim() === "") return
                const parts = line.split("\t")
                const path = parts[0]
                const name = (parts.length > 1 && parts[1].trim() !== "")
                    ? parts[1]
                    : path.replace(/.*\//, "").replace(/\.[^.]+$/, "")
                root._files.push({ path: path, name: name })
            }
        }
        // qmllint disable signal-handler-parameters
        onExited: {
            root._files = [...root._files]
            root._rebuild()
        }
        // qmllint enable signal-handler-parameters
    }

    // Apply chain, preserved exactly from the original:
    // ctProcess (set theme) -> vscProcess (build theme) -> vscPackageProcess (build package)
    Process {
        id: vscPackageProcess
        running: false
    }

    Process {
        id: vscProcess
        running: false
        // qmllint disable signal-handler-parameters
        onExited: vscPackageProcess.running = true
        // qmllint enable signal-handler-parameters
    }

    Process {
        id: ctProcess
        running: false
        // qmllint disable signal-handler-parameters
        onExited: vscProcess.running = true
        // qmllint enable signal-handler-parameters
    }

    Component.onCompleted: rescan()
}
