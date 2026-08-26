/* quickshell/shell/widgets/components/workspace/WorkspaceOSD.qml */


import QtQuick
import ElysianShell.Services
import ElysianShell.Themes

Item {
    id: workspaceOsd
    property real horizontalPadding: 20
    property real verticalPadding: 7

    readonly property int _radius: 15
    readonly property int _animDuration: 100

    implicitWidth: row.implicitWidth + horizontalPadding * 2
    implicitHeight: row.implicitHeight + verticalPadding * 2

    Row {
        id: row
        anchors.centerIn: parent
        spacing: 10

        Repeater {
            model: WorkspaceService.states

            Rectangle {
                id: wsIndicator

                required property var modelData

                readonly property bool active:  modelData.active
                readonly property bool exists:  modelData.exists

                visible: modelData.visible

                width: active ? workspaceOsd._radius * 3 : workspaceOsd._radius
                height: workspaceOsd._radius
                radius: height / 2
                color: WorkspaceService.colorFor(active, exists)

                border {
                    width: 0
                    color: ActiveTheme.colors["FG"]
                }

                Behavior on color { ColorAnimation { duration: workspaceOsd._animDuration } }

                Behavior on width { NumberAnimation {
                    duration: workspaceOsd._animDuration
                    easing.type: Easing.InOutCubic
                }}

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true

                    onEntered: wsIndicator.border.width = 2
                    onExited: wsIndicator.border.width = 0
                    onClicked: WorkspaceService.activate(modelData.id)
                }
            }
        }
    }
}
