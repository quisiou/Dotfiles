/* quickshell/modules/Services/Keybinds/KeybindsService.qml */


pragma Singleton

import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import QtQuick

Singleton {
    id: root

    property var keybinds: ({})

    readonly property var _categoryRegex: /^\[([^@\]]+?)(?:@(\w+))?\]\s*(.*)$/

    readonly property var _modTable: [
        { bit: 64, label: "Super" },
        { bit: 4,  label: "Ctrl"  },
        { bit: 8,  label: "Alt"   },
        { bit: 1,  label: "Shift" },
    ]

    readonly property var _keyNames: ({
        "mouse:272":  "LMB",
        "mouse:273":  "RMB",
        "mouse:274":  "MMB",
        "mouse_up":   "Scroll ↑",
        "mouse_down": "Scroll ↓",
        "escape":     "Esc",
        "tab":        "Tab",
        "print":      "PrtSc",
        "return":     "Enter",
        "space":      "Space",
        "left":       "←",
        "right":      "→",
        "up":         "↑",
        "down":       "↓",
        "super_l":    "Super",
        "super_r":    "Super",
    })

    function _prettyKey(key) {
        const lower = key.toLowerCase()

        if (root._keyNames[lower] !== undefined)
            return root._keyNames[lower]

        if (lower.startsWith("xf86"))
            return key.slice(4)

        return key.length === 1 ? key.toUpperCase() : key
    }

    function _buildKey(modmask, key) {
        const keys = []
        for (const m of root._modTable) {
            if (modmask & m.bit)
                keys.push(m.label)
        }

        const pretty = root._prettyKey(key)
        if (!keys.includes(pretty))
            keys.push(pretty)

        return keys
    }

    function _parse(text) {
        let raw
        try {
            raw = JSON.parse(text)
        } catch (e) {
            console.warn("KeybindsService: invalid JSON:", e)
            return
        }

        // Pass 1: submap name -> keys that enter it
        const entry = {}
        for (const b of raw) {
            const m = root._categoryRegex.exec(b.description ?? "")
            if (m && m[2] && b.submap === "")
                entry[m[2]] = root._buildKey(b.modmask, b.key)
        }

        // Pass 2: build the groups
        const groups = {}

        for (const b of raw) {
            const inSubmap = b.submap !== ""

            // Skip exit/switch binds inside a submap (e.g. Escape -> reset)
            if (inSubmap && b.dispatcher.includes("submap"))
                continue

            let key = root._buildKey(b.modmask, b.key)

            // Prefix with the keys that enter the submap, unless it's a universal bind
            if (inSubmap && b.submap_universal !== "true") {
                const prefix = entry[b.submap] ?? ["(" + b.submap + ")"]
                key = [...prefix, "›", ...key]
            }

            const m = root._categoryRegex.exec(b.description ?? "")
            const category = m ? m[1].trim() : "Other"
            const description = m ? m[3] : (b.description ?? "")

            if (!groups[category])
                groups[category] = []

            groups[category].push({
                description: description,
                key: key,
            })
        }

        root.keybinds = groups
    }

    Process {
        id: proc
        command: ["hyprctl", "binds", "-j"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                root._parse(text)
                console.log(JSON.stringify(root.keybinds, null, 2))
            }
        }
    }

    function reload() {
        debounce.restart()
    }

    Timer {
        id: debounce
        interval: 250
        onTriggered: {
            if (!proc.running)
                proc.running = true
        }
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name === "configreloaded")
                root.reload()
        }
    }
}
