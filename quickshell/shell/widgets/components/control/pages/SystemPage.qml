/* quickshell/shell/widgets/components/control/pages/SystemPage.qml */


import QtQuick
import ElysianShell.Themes
import ElysianShell.Services
import "../../../base"

Item {
    id: root

    // Pages are at most 900 wide; the grid adapts to the width we get.
    implicitWidth: 900
    implicitHeight: grid.implicitHeight

    function refresh() {
        calendar.refreshLocale()
    }

    Grid {
        id: grid
        anchors.fill: parent

        columns: 20
        rows: 10
        spacing: 12

        // Blocks are derived from the available width; square blocks,
        // so the height follows from the width.
        blockWidth: (root.width - (columns - 1) * spacing) / columns
        blockHeight: blockWidth

        showCells: false   // set to true to see the 20x10 cells

        // Left top: calendar
        GridBlock {
            column: 0; row: 0
            columnSpan: 6; rowSpan: 6
        }

        // Left bottom (5 x 4)
        GridBlock {
            column: 0; row: 6
            columnSpan: 6; rowSpan: 4
        }

        // Center top (10 x 4)
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
                onDismissed: (time) => NotificationService.removeHistory(time)
            }
        }
    }
}
