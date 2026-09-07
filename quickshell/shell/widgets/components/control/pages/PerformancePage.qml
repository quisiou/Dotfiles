/* quickshell/shell/widgets/components/control/pages/PerformancePage.qml */


import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../../base"

Item {
    id: root
    implicitWidth: compRow.implicitWidth
    implicitHeight: compRow.implicitHeight

    property real cpuUsage: 0
    property real cpuTemp: 0

    property real memUsage: 0
    property real memUsagePerc: 0
    property real memTotal: 0

    property real gpuUsage: 0
    property real gpuTemp: 0

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
                    var data = JSON.parse(line)
                    root.cpuUsage = data.used_percentage
                    root.cpuTemp = data.temp
                } catch (e) {
                    console.log("get_cpu parse failed:", e, line)
                }
            }
        }
    }

    Process {
        id: memProc
        command: [
            Quickshell.env("HOME") + "/.config/quickshell/.bin/get_mem_info",
            "1000"
        ]
        running: true
        stdout: SplitParser {
            onRead: (line) => {
                try {
                    var data = JSON.parse(line)
                    root.memUsage = data.used
                    root.memUsagePerc = data.used_percentage
                    root.memTotal = data.total
                } catch (e) {
                    console.log("get_mem parse failed:", e, line)
                }
            }
        }
    }

    Process {
        id: gpuProc
        command: [
            Quickshell.env("HOME") + "/.config/quickshell/.bin/get_gpu_info",
            "1000"
        ]
        running: true
        stdout: SplitParser {
            onRead: (line) => {
                try {
                    var data = JSON.parse(line)
                    root.gpuUsage = data.used_percentage
                    root.gpuTemp = data.temp
                } catch (e) {
                    console.log("get_gpu parse failed:", e, line)
                }
            }
        }
    }

    RowLayout {
        id: compRow
        anchors.fill: parent
        spacing: 20

        Item {
            id: cpuGroup
            Layout.preferredWidth: 200
            Layout.preferredHeight: 200
            Layout.alignment: Qt.AlignCenter

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

        Item {
            id: memGroup
            Layout.preferredWidth: 200
            Layout.preferredHeight: 200
            Layout.alignment: Qt.AlignCenter

            FillMeter {
                id: memFill
                anchors.centerIn: parent
                width: 140
                height: 140
                infoText: "RAM usage"
                minValue: 0
                value: root.memUsagePerc
                maxValue: 100
            }

            // RingMeter {
            //     anchors.fill: parent
            //     minValue: 30
            //     value: root.cpuTemp
            //     maxValue: 95
            //     ringRadius: memFill.implicitWidth / 2 + 15
            // }
        }

        Item {
            id: gpuGroup
            Layout.preferredWidth: 200
            Layout.preferredHeight: 200
            Layout.alignment: Qt.AlignCenter

            FillMeter {
                id: gpuFill
                anchors.centerIn: parent
                width: 140
                height: 140
                infoText: "GPU usage"
                minValue: 0
                value: root.gpuUsage
                maxValue: 100
            }

            RingMeter {
                anchors.fill: parent
                minValue: 30
                value: root.gpuTemp
                maxValue: 95
                ringRadius: gpuFill.implicitWidth / 2 + 15
            }
        }
    }
}
