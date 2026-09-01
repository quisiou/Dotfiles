/* quickshell/modules/Services/Brightness/BrightnessService.qml */


pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property string device: ""
    property int maxBrightness: 1
    property real value: 0
    property bool _internalWrite: false
    property bool _seen: false
    property real pendingValue: 0

    signal brightnessChanged()

    Process {
        id: detectDevice
        running: true
        command: ["bash", "-c", "ls /sys/class/backlight | head -1"]

        stdout: StdioCollector {
            onStreamFinished: {
                root.device = text.trim()
                if (root.device === "") return

                const base = "/sys/class/backlight/" + root.device

                maxBrightnessFile.path = base + "/max_brightness"
                brightnessFile.path    = base + "/actual_brightness"

                watcher.command = [
                    "inotifywait",
                    "-m",
                    "-e",
                    "modify",
                    "-e",
                    "attrib",
                    base + "/actual_brightness"
                ]
                watcher.running = true
            }
        }
    }

    FileView {
        id: maxBrightnessFile
        onLoaded: {
            root.maxBrightness = parseInt(text().trim())
        }
    }

    FileView {
        id: brightnessFile
        onLoaded: root._updateFromFile()
    }

    Process {
        id: watcher
        
        stdout: SplitParser { onRead: (line) => { brightnessFile.reload() } }
    }

    function _updateFromFile() {
        const raw = parseInt(brightnessFile.text().trim())
        const v = root.maxBrightness > 0 ? raw / root.maxBrightness : 0

        const wasInternal = root._internalWrite
        root._internalWrite = false

        if (!root._seen) {
            root._seen = true
            root.value = v
            return   // first load ever — establish baseline, no signal
        }

        if (Math.abs(v - root.value) < 0.001) return
        root.value = v

        if (!wasInternal) root.brightnessChanged()
    }

    Timer {
        id: writeDebounce
        interval: 40
        onTriggered: {
            root._internalWrite = true
            setProcess.command = ["brightnessctl", "set", Math.round(root.pendingValue * 100) + "%"]
            setProcess.running = true
        }
    }
    

    Process {
        id: setProcess
        running: false
    }

    function setValue(v) {
        root.value = v
        pendingValue = v
        writeDebounce.restart()
    }
}
