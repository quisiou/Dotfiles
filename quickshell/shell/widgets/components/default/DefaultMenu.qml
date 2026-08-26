/* quickshell/shell/widgets/components/default/DefaultMenu.qml */


import QtQuick
import ElysianShell.Themes
import ElysianShell.Services
import "../../base"     // For Clock widget

Item {
    id: root

    property real horizontalPadding: 20
    property real verticalPadding: 4
    property bool expanded: false
    property int clockPixelSize: 16

    property real _batteryPercentage:   BatteryService.percentage
    property string _batteryStatus:     BatteryService.statusText
    
    implicitWidth:  (clock.implicitWidth  + horizontalPadding * 2) * (root.expanded ? 2 : 1)
    implicitHeight: (clock.implicitHeight + verticalPadding   * 2) * (root.expanded ? 2 : 1)

    readonly property real basePillHeight: clock.implicitHeight + verticalPadding * 2

    Clock {
        id: clock
        anchors {
            top: parent.top
            topMargin: 3
            horizontalCenter: parent.horizontalCenter
        }
        pixelSize: root.clockPixelSize
    }

    Row {
        id: batteryIcon
        visible: root.expanded
        anchors {
            verticalCenter: parent.verticalCenter
            right: parent.right
            rightMargin: 5
        }
        spacing: 1

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
