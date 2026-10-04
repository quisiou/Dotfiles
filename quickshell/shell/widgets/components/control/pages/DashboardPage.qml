/* quickshell/shell/widgets/components/control/pages/DashboardPage.qml */


import QtQuick
import ElysianShell.Themes
import ElysianShell.Services
import "../../../base"

Item {
    id: root

    readonly property int _gridColumns: 20
    readonly property int _gridRows: 10
    readonly property real _gridSpacing: 12
    readonly property real _designWidth: 768

    readonly property real _designBlock: (_designWidth - (_gridColumns - 1) * _gridSpacing) / _gridColumns

    implicitWidth: _designWidth
    implicitHeight: _gridRows * _designBlock + (_gridRows - 1) * _gridSpacing

    function refresh() {
        calendar.refreshLocale()
    }

    Grid {
        id: grid
        anchors.fill: parent

        columns: root._gridColumns
        rows: root._gridRows
        spacing: root._gridSpacing

        // Blocks are derived from the available width; square blocks,
        // so the height follows from the width.
        blockWidth: (root.width - (columns - 1) * spacing) / columns
        blockHeight: blockWidth

        showCells: false   // set to true to see the 20x10 cells

        // Left top
        GridBlock {
            column: 0; row: 0
            columnSpan: 6; rowSpan: 6
        }

        // Left bottom
        GridBlock {
            column: 0; row: 6
            columnSpan: 6; rowSpan: 4
        }

        // Center top
        GridBlock {
            column: 6; row: 0
            columnSpan: 8; rowSpan: 3
        }

        // Center bottom
        GridBlock {
            id: calendarBlock
            column: 6; row: 3
            columnSpan: 8; rowSpan: 7

            Calendar {
                id: calendar
                anchors.centerIn: parent
                uiScale: 1
            }
        }

        // Right
        GridBlock {
            column: 14; row: 0
            columnSpan: 6; rowSpan: 10

            NotificationLog {
                anchors.fill: parent
                color: ActiveTheme.colors["BG_FOCUSED"]
                entries: NotificationService.history
            }
        }
    }
}
