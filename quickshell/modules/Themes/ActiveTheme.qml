/* quickmodules/Themes/ActiveTheme.qml */


pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io


Singleton {
	id: root

    property bool   ready:      false
    property string wallpaper:  ""
    property var    tokens:     ({})
    property var    colors:     ({          // Have default colors in case theme does not load correctly
        "BG"                : "#161616",
		"BG_DARK"           : "#0f0f0f",
		"BG_DEEP"           : "#080808",
		"BG_DARKEST"        : "#030303",
		"BG_POPUP"          : "#1a1a1a",
		"BG_HIGHLIGHT"      : "#222222",
		"BG_FOCUSED"        : "#1e1e1e",
		"BG_ACTIVE"         : "#282828",
		"BG_HOVER"          : "#1c1c1c",
		"BG_SELECTED"       : "#2a2a2a",
		"BG_STRIPE"         : "#202020",
		"BG_OVERLAY"        : "#1f1f1f",
		"BG_TINTED"         : "#1e3a5f",
		"FG"                : "#f2f4f8",
		"FG_DARK"           : "#dde1e7",
		"FG_MUTED"          : "#a2a9b0",
		"FG_BRIGHT"         : "#e5e9f0",
		"FG_DIM"            : "#c1c7cd",
		"FG_LIGHT"          : "#d0d7df",
		"FG_SUBTLE"         : "#b0b8c1",
		"FG_DISABLED"       : "#6e7681",
		"FG_ON_ACCENT"      : "#ffffff",
		"FG_GHOST"          : "#525a65",
		"FG_HINT"           : "#5c6370",
		"DARK3"             : "#5c6370",
		"DARK4"             : "#525a65",
		"DARK5"             : "#484f58",
		"DARK6"             : "#3d444b",
		"DARK7"             : "#333940",
		"ANSI_BLACK"        : "#363b54",
		"ANSI_RED"          : "#f7768e",
		"ANSI_GREEN"        : "#73daca",
		"ANSI_YELLOW"       : "#e0af68",
		"ANSI_BLUE"         : "#7aa2f7",
		"ANSI_MAGENTA"      : "#bb9af7",
		"ANSI_CYAN"         : "#7dcfff",
		"ANSI_WHITE"        : "#787c99",
		"ACCENT"            : "#3d59a1",
		"ACCENT_SUBTLE"     : "#506fca",
		"ACCENT_MUTED"      : "#6183bb",
		"ACCENT_DIM"        : "#668ac4",
		"ACCENT_LOW"        : "#9abdf5",
		"ACCENT_HIGH"       : "#b8d1f8",
		"SECONDARY"         : "#7dcfff",
		"SECONDARY_SUBTLE"  : "#89ddff",
		"SECONDARY_MUTED"   : "#2ac3de",
		"SECONDARY_DIM"     : "#b4f9f8",
		"TERTIARY"          : "#bb9af7",
		"TERTIARY_SUBTLE"   : "#9d7cd8",
		"TERTIARY_MUTED"    : "#b267e6",
		"TERTIARY_DIM"      : "#ba3c97",
		"TERTIARY_LOW"      : "#de5971",
		"INFO"              : "#0db9d7",
		"INFO_SUBTLE"       : "#0da0ba",
		"INFO_ALT"          : "#1abc9c",
		"SUCCESS"           : "#73daca",
		"SUCCESS_SUBTLE"    : "#41a6b5",
		"SUCCESS_MUTED"     : "#9ece6a",
		"VCS_ADDED"         : "#449dab",
		"WARNING"           : "#e0af68",
		"WARNING_SUBTLE"    : "#c49a5a",
		"WARNING_MUTED"     : "#bba461",
		"WARNING_LOW"       : "#ffdb69",
		"WARNING_SURFACE"   : "#c2985b",
		"URGENT"            : "#ff9e64",
		"ERROR"             : "#db4b4b",
		"ERROR_SUBTLE"      : "#bb616b",
		"ERROR_LOW"         : "#fc7b7b",
		"ERROR_HIGH"        : "#ff5370",
		"ERROR_SURFACE"     : "#85353e",
		"ERROR_BORDER"      : "#963c47",
		"ERROR_DIM"         : "#c24242",
		"VCS_MODIFIED"      : "#6183bb",
		"VCS_DELETED"       : "#914c54",
		"VCS_IGNORED"       : "#515670",
		"BORDER"            : "#0f0f14",
		"RAINBOW_1"         : "#7aa2f7",
		"RAINBOW_2"         : "#0db9d7",
		"RAINBOW_3"         : "#7dcfff",
		"RAINBOW_4"         : "#bb9af7",
		"RAINBOW_5"         : "#e0af68",
		"RAINBOW_6"         : "#f7768e"
    })

	property var _file: FileView {
        path: Quickshell.env("HOME") + "/.config/elysian_themes/active_theme/colors.lua"
        watchChanges: true

        onFileChanged: reload()

        onTextChanged: {
            if (!loaded) return

            root.ready = false

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

            root.colors = colors
            root.tokens = tokens
            root.ready = true
        }
    }
}
