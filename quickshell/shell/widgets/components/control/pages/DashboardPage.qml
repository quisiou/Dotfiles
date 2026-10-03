/* quickshell/shell/widgets/components/control/pages/DashboardPage.qml */


import QtQuick
import QtQuick.Layouts
import ElysianShell.Themes
import ElysianShell.Services
import "../../../base"

Item {
    id: root

    implicitWidth: layout.implicitWidth
    implicitHeight: layout.implicitHeight

    function refresh() {
        calendar.refreshLocale()
    }

    RowLayout {
        id: layout
        anchors.fill: parent
        spacing: 12

        Calendar {
            id: calendar
            Layout.alignment: Qt.AlignVCenter
            color: ActiveTheme.colors["BG_FOCUSED"]
        }

        NotificationLog {
            Layout.fillWidth: true
            Layout.preferredHeight: calendar.height
            Layout.alignment: Qt.AlignVCenter
            color: ActiveTheme.colors["BG_FOCUSED"]
            entries: NotificationService.history
            onDismissed: (time) => NotificationService.removeHistory(time)
        }
    }
}
