/* quickshell/shell/widgets/components/control/pages/PerformancePage.qml */


import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../../../base"

Item {
    id: root
    implicitWidth: compRow.implicitWidth + 20
    implicitHeight: compRow.implicitHeight + 40

    property real cpuPerc: 0
    property real cpuTemp: 0

    property real memUsed: 0
    property real memTotal: 0

    property real diskUsed: 0
    property real diskTotal: 0

    property real gpuPerc: 0
    property real gpuTemp: 0

    Process {
        id: cpuProc
        command: [
            Quickshell.shellDir + "/bin/get_cpu_info",
            "1000"
        ]
        running: true
        stdout: SplitParser {
            onRead: (line) => {
                try {
                    var data = JSON.parse(line)
                    root.cpuPerc = data.perc
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
            Quickshell.shellDir + "/bin/get_mem_info",
            "1000"
        ]
        running: true
        stdout: SplitParser {
            onRead: (line) => {
                try {
                    var data = JSON.parse(line)
                    root.memUsed = data.used
                    root.memTotal = data.total
                } catch (e) {
                    console.log("get_mem parse failed:", e, line)
                }
            }
        }
    }

    Process {
        id: diskProc
        command: [
            Quickshell.shellDir + "/bin/get_disk_info",
            "1000"
        ]
        running: true
        stdout: SplitParser {
            onRead: (line) => {
                try {
                    var data = JSON.parse(line)
                    root.diskUsed = data.used
                    root.diskTotal = data.total
                } catch (e) {
                    console.log("get_disk parse failed:", e, line)
                }
            }
        }
    }

    Process {
        id: gpuProc
        command: [
            Quickshell.shellDir + "/bin/get_gpu_info",
            "1000"
        ]
        running: true
        stdout: SplitParser {
            onRead: (line) => {
                try {
                    var data = JSON.parse(line)
                    root.gpuPerc = data.perc
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
            Layout.preferredWidth: cpuRing.implicitWidth
            Layout.preferredHeight: cpuRing.implicitHeight
            Layout.alignment: Qt.AlignCenter

            FillMeter {
                id: cpuFill
                anchors.centerIn: parent
                width: 120
                height: 120
                infoSubTextFormat: (value, displayValue) => { return "CPU usage" }
                minValue: 0
                value: root.cpuPerc
                maxValue: 100
            }

            RingMeter {
                id: cpuRing
                anchors.fill: parent
                minValue: 30
                value: root.cpuTemp
                maxValue: 95
                ringRadius: cpuFill.width / 2 + 15
                infoSubTextFormat: (value, displayValue) => { return "Temp" }
            }
        }

        Item {
            id: memGroup
            Layout.preferredWidth: diskRing.implicitWidth
            Layout.preferredHeight: diskRing.implicitHeight
            Layout.alignment: Qt.AlignCenter

            FillMeter {
                id: memFill
                anchors.centerIn: parent
                width: 160
                height: 160
                infoSubTextFormat: (value, displayValue) => { return "RAM usage" }
                minValue: 0
                value: root.memUsed
                maxValue: root.memTotal
            }

            RingMeter {
                id: diskRing
                anchors.fill: parent
                minValue: 0
                value: root.diskUsed
                maxValue: root.diskTotal
                ringRadius: memFill.width / 2 + 15
                infoTextFormat: (value, displayValue) => { return Math.round(displayValue * 100) + "%" }
                infoSubTextFormat: (value, displayValue) => { return "Disk usage" }
            }
        }

        Item {
            id: gpuGroup
            Layout.preferredWidth: gpuRing.implicitWidth
            Layout.preferredHeight: gpuRing.implicitHeight
            Layout.alignment: Qt.AlignCenter

            FillMeter {
                id: gpuFill
                anchors.centerIn: parent
                width: 120
                height: 120
                infoSubTextFormat: (value, displayValue) => { return "GPU usage" }
                minValue: 0
                value: root.gpuPerc
                maxValue: 100
            }

            RingMeter {
                id: gpuRing
                anchors.fill: parent
                minValue: 30
                value: root.gpuTemp
                maxValue: 95
                ringRadius: gpuFill.width / 2 + 15
                infoSubTextFormat: (value, displayValue) => { return "Temp" }
            }
        }
    }
}
