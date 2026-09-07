/* quickshell/shell/widgets/components/control/pages/PerformancePage.qml */


import QtQuick
import Quickshell
import Quickshell.Io
import ElysianShell.Themes
import "../../../base"

Item {
    id: root
    implicitWidth: 200
    implicitHeight: 200

    property real cpuUsage: 0
    property real cpuTemp: 0

    Process {
        id: cpuProc
        command: [
            Quickshell.env("HOME") + "/.config/quickshell/.bin/get_cpu_info",
            "1000"
        ]
        running: true
        stdout: SplitParser {
            onRead: (line) => {
                try {
                    var data = JSON.parse(line);
                    root.cpuUsage = data.used_percentage;
                    root.cpuTemp = data.temp;
                } catch (e) {
                    console.log("get_cpu parse failed:", e, line);
                }
            }
        }
    }

    FillMeter {
        id: cpuFill
        anchors.centerIn: parent
        width: 140
        height: 140
        infoText: "CPU usage"
        minValue: 0
        value: root.cpuUsage
        maxValue: 100
    }

    RingMeter {
        anchors.fill: parent
        minValue: 30
        value: root.cpuTemp
        maxValue: 95
        ringRadius: cpuFill.implicitWidth / 2 + 15
    }
}
