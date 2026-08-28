/* quickshell/shell/widgets/base/Tooltip.qml */


import QtQuick
import ElysianShell.Themes

Rectangle {
    id: root

    property string title: ""
    property string comment: ""
    property bool   selected: false

    width:  tooltipCol.implicitWidth + 16
    height: tooltipCol.implicitHeight + 10
    color: ActiveTheme.colors["BG_HIGHLIGHT"].replace("#", "#C0")
    border.color: root.selected ? ActiveTheme.colors["ACCENT_LOW"] : ActiveTheme.colors["BG_POPUP"]
    border.width: 1
    radius: 6

    Column {
        id: tooltipCol
        anchors.centerIn: parent
        spacing: 2

        Text {
            text: root.title
            color: ActiveTheme.colors["FG"]
            font.pixelSize: 12
            font.weight: Font.Medium
            visible: text !== ""
            horizontalAlignment: Text.AlignHCenter
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Text {
            text: root.comment
            color: root.selected ? ActiveTheme.colors["ACCENT_LOW"] : ActiveTheme.colors["FG_MUTED"]
            font.pixelSize: 11
            visible: text !== ""
            horizontalAlignment: Text.AlignHCenter
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }
}