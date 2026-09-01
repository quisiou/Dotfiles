/* quickshell/modules/Services/Lock/LockService.qml */


pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: service
    property string currentWallpaper: Quickshell.env("HOME") + "/.config/awww/default/Leshy.jpg"

    property Process _queryProcess: Process {
        running: false
        command: [
            "bash", "-c",
            "awww query | awk -F'image: ' '{print $2}' | awk '{print $1}' | xargs realpath"
        ]
        stdout: SplitParser {
            onRead: function(line) {
                if (line.trim() !== "") {
                    service.currentWallpaper = "file://" + line.trim()
                }
            }
        }
    }

    function refreshWallpaper() { _queryProcess.running = true }
}
