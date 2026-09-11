/* quickshell/shell/widgets/components/control/pages/DashboardPage.qml */


import QtQuick
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
        anchors.centerIn: parent
        width: 300
        height: 250
    }
}
