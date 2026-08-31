/* quickshell/shell/widgets/components/session/SessionMenu.qml */


pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import ElysianShell.Themes

Item {
    id: root
    property real padding: 10
    property real cornerRadius: 10
    property int currentIndex: 0

    readonly property int _radius: 15
    readonly property int _animDuration: 100

    implicitWidth: sessionRow.implicitWidth + padding * 2
    implicitHeight: sessionRow.implicitHeight + padding * 2

    signal resetRequested()
    signal lockRequested()

    Component.onCompleted: {
        root.currentIndex = 0
        Qt.callLater(root.forceActiveFocus)
    }

    Keys.onLeftPressed:  root.currentIndex = Math.max(root.currentIndex - 1, 0)
    Keys.onRightPressed: root.currentIndex = Math.min(root.currentIndex + 1, sessionRow.sessionActions.length - 1)
    Keys.onReturnPressed: sessionRow.sessionActions[root.currentIndex].action()
    Keys.onEscapePressed: root.resetRequested()

    Row {
        id: sessionRow
        anchors.centerIn: parent
        spacing: 10

        property var sessionActions: [
            {
                title: "Lock",
                icon: "object-locked.svg",
                action: () => root.lockRequested()
            },
            {
                title: "Logout",
                icon: "system-log-out.svg",
                action: () => Quickshell.execDetached([
                    "bash", "-c",
                    "loginctl terminate-session \"${XDG_SESSION_ID:-$(loginctl session-status | head -1 | awk '{print $1}')}\""
                ])
            },
            {
                title: "Reboot",
                icon: "system-reboot.svg",
                action: () => Quickshell.execDetached(["systemctl", "reboot"])
            },
            {
                title: "Shutdown",
                icon: "system-shutdown.svg",
                action: () => Quickshell.execDetached(["systemctl", "poweroff"])
            }
        ]

        Repeater {
            model: sessionRow.sessionActions

            delegate: Rectangle {
                id: btn
                required property var modelData
                required property int index

                readonly property bool isCurrent: index === root.currentIndex

                width: 64
                height: 64
                radius: root.cornerRadius - root.padding
                color: isCurrent ? ActiveTheme.colors["BG_STRIPE"]
                    : mouseArea.containsMouse ? "#3a3a3a" : "#2a2a2a"
                border.width: isCurrent ? 2 : 0
                border.color: ActiveTheme.colors["ACCENT_DIM"]

                Behavior on color { ColorAnimation { duration: root._animDuration } }
                Behavior on border.color { ColorAnimation { duration: root._animDuration } }
                Behavior on border.width { NumberAnimation { duration: root._animDuration } }

                Column {
                    anchors.centerIn: parent
                    spacing: 4

                    Image {
                        source: Quickshell.shellDir + "/assets/icons/" + btn.modelData.icon
                        sourceSize {
                            width:  48
                            height: 48
                        }
                        width: 36
                        height: 36
                        anchors.horizontalCenter: parent.horizontalCenter
                    }
                }

                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: root.currentIndex = btn.index
                    onClicked: btn.modelData.action()
                }
            }
        }
    }
}
