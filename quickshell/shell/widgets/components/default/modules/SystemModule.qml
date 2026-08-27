/* quickshell/shell/widgets/components/default/modules/SystemModule.qml */


import QtQuick
import Quickshell
import Quickshell.Widgets
import ElysianShell.Services
import ElysianShell.Themes

Row {
    id: root
    spacing: 6

    property real _batteryPercentage: BatteryService.percentage
    property string _batteryStatus: BatteryService.statusText

    Image {
        id: volumeIcon
        anchors.verticalCenter: parent.verticalCenter
        source: VolumeService.muted
                    ? Quickshell.shellDir + "/assets/icons/audio-volume-muted.svg"
                    : Quickshell.shellDir + "/assets/icons/audio-volume-high.svg"
        sourceSize {
            width:  48
            height: 48
        }
        width:  24
        height: 24
        fillMode: Image.PreserveAspectFit
        smooth: true
        asynchronous: true
    }

    Image {
        id: networkIcon
        anchors.verticalCenter: parent.verticalCenter
        source: NetworkService.connectionType === "ethernet"
            ?                                   Quickshell.shellDir + "/assets/icons/network-wired.svg"
            : !NetworkService.enabled       ?   Quickshell.shellDir + "/assets/icons/network-wireless-offline.svg"
            : NetworkService.strength === 0 ?   Quickshell.shellDir + "/assets/icons/network-wireless-acquiring.svg"
            : NetworkService.strength >= 80 ?   Quickshell.shellDir + "/assets/icons/network-wireless-80.svg"
            : NetworkService.strength >= 60 ?   Quickshell.shellDir + "/assets/icons/network-wireless-60.svg"
            : NetworkService.strength >= 40 ?   Quickshell.shellDir + "/assets/icons/network-wireless-40.svg"
            :                                   Quickshell.shellDir + "/assets/icons/network-wireless-20.svg"
        sourceSize {
            width:  48
            height: 48
        }
        width:  24
        height: 24
        fillMode: Image.PreserveAspectFit
        smooth: true
        asynchronous: true
    }

    Row {
        spacing: 1
        anchors.verticalCenter: parent.verticalCenter

        Rectangle {
            id: batteryBody
            implicitWidth: 25
            implicitHeight: 15
            anchors.verticalCenter: parent.verticalCenter
            radius: 5
            color: "transparent"
            border {
                width: 1.5
                color: ActiveTheme.colors["FG"]
            }
            clip: true

            Rectangle {
                id: batteryFill
                anchors {
                    left: parent.left
                    top: parent.top
                    bottom: parent.bottom
                    margins: 2.5
                }
                width: (parent.width - anchors.margins * 2) * root._batteryPercentage
                radius: 3
                color: ActiveTheme.colors["ACCENT_LOW"]

                Behavior on width {
                    NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                }
            }

            Text {
                anchors.centerIn: parent
                z: 1
                text: Math.round(root._batteryPercentage * 100)
                font.pixelSize: 8
                font.bold: true
                color: ActiveTheme.colors["BG"]
            }
        }

        Rectangle {
            implicitWidth: 1.5
            implicitHeight: 6
            anchors.verticalCenter: parent.verticalCenter
            radius: height / 2
            color: ActiveTheme.colors["FG"]
        }
    }
}
