/* quickshell/modules/Services/Clipboard/ClipboardService.qml */


pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // newest first: { id, kind: "text"|"image", text, meta }
    property var history: []

    function refresh() { if (!listProc.running) listProc.running = true }

    function copy(id) {
        copyProc.command = ["sh", "-c", "cliphist decode \"$1\" | wl-copy", "sh", String(id)]
        copyProc.running = true
    }
    function remove(id) {
        delProc.command = ["sh", "-c", "printf '%s\\t\\n' \"$1\" | cliphist delete", "sh", String(id)]
        delProc.running = true
    }
    function clearHistory() { wipeProc.running = true }

    function _parse(raw) {
        const out = []
        for (const line of raw.split("\n")) {
            const tab = line.indexOf("\t")
            if (tab < 0) continue
            const id = line.slice(0, tab)
            const preview = line.slice(tab + 1)

            // cliphist shows images as: [[ binary data 12 KiB png 800x600 ]]
            const m = preview.match(/^\[\[ binary data (.+?) (\w+)(?: (\d+x\d+))? \]\]$/)
            if (m) {
                out.push({ id, kind: "image", text: "Image",
                           meta: [m[3], m[2], m[1]].filter(x => x).join(" · ") })
            } else {
                out.push({ id, kind: "text", text: preview, meta: "" })
            }
        }
        return out
    }

    Process {
        id: listProc
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: root.history = root._parse(text)
        }
    }
    Process { id: copyProc }
    Process { id: delProc;  onRunningChanged: if (!running) root.refresh() }
    Process { id: wipeProc; command: ["cliphist", "wipe"]; onRunningChanged: if (!running) root.refresh() }

    // refresh whenever the clipboard changes
    Process {
        running: true
        command: ["wl-paste", "--watch", "echo"]
        stdout: SplitParser { onRead: debounce.restart() }
    }
    Timer { id: debounce; interval: 200; onTriggered: root.refresh() }

    Component.onCompleted: refresh()
}
