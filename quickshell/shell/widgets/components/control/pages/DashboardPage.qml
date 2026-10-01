/* quickshell/shell/widgets/components/control/pages/DashboardPage.qml */


import QtQuick
import ElysianShell.Themes
import "../../../base"

Item {
    id: root
    implicitWidth: calendar.implicitWidth
    implicitHeight: calendar.implicitHeight

    function refresh() {
        calendar.refreshLocale()
    }

    Calendar {
        id: calendar
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: 300
        height: 250
        color: ActiveTheme.colors["BG_HIGHLIGHT"]
    }
}
