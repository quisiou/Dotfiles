/* quickshell/vesktop-overlay/widgets/ThemeLoader.qml */


import QtQuick
import Quickshell
import Quickshell.Io
import ElysianShell.Themes


QtObject {
    property var _file: FileView {
        path: Quickshell.env("HOME") + "/.config/elysian_themes/active_theme/colors.lua"
        watchChanges: true

        onFileChanged: reload()

        onTextChanged: {
            if (!loaded) return

            ActiveTheme.ready = false

            const colors = {}
            const tokens = {}

            for (const line of text().split("\n")) {
                const trimmed = line.trim()

                // skip blank lines and comments
                if (!trimmed || trimmed.startsWith("--")) continue

                const match = trimmed.match(/^(\w+)\s*=\s*"(.+?)"/)
                if (!match) continue

                const key = match[1]
                const val = match[2]

                console.log(JSON.stringify(key), "=", JSON.stringify(val))

                if (val.match(/^#([a-fA-F0-9]{6})$/)) {
                    colors[key] = val
                    continue
                }

                tokens[key] = val
            }

            ActiveTheme.colors = colors
            ActiveTheme.tokens = tokens
            ActiveTheme.ready = true
        }
    }
}
