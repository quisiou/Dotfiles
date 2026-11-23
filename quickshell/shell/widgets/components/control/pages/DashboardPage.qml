/* quickshell/shell/widgets/components/control/pages/DashboardPage.qml */


import QtQuick
import ElysianShell.Themes
import ElysianShell.Services
import "../../../base"

Item {
    id: root

    property bool active: false

    readonly property int _gridColumns: 40
    readonly property int _gridRows: 20
    readonly property real _gridSpacing: 12
    readonly property real _designWidth: 768

    readonly property real _designBlock: (_designWidth - (_gridColumns - 1) * _gridSpacing) / _gridColumns

    implicitWidth: _designWidth
    implicitHeight: _gridRows * _designBlock + (_gridRows - 1) * _gridSpacing

    readonly property var _expandables: [
        notificationBlock, clipboardBlock, meteoBlock, systemBlock
    ]
    readonly property var _current: _expandables.find(b => b.expanded) || null

    // Called when opening a page
    function refresh() {
        active = true
        calendar.refreshLocale()
        ClipboardService.refresh()
    }

    // Called after completely switching to another page (animation finished)
    function leave() {
        active = false
        if (_current)
            _current.collapseImmediately()
    }

    function toggleExclusive(block) {
        if (_current && _current !== block)
            _current.collapse()
        block.toggle()
    }

    Component.onCompleted: WeatherService.refresh()

    Keys.onPressed: event => {
        if (!active) return
        if (event.key === Qt.Key_Escape) {
            event.accepted = _current !== null
            if (_current)
                _current.collapse()
        }
        else if (event.key === Qt.Key_I) toggleExclusive(systemBlock)
        else if (event.key === Qt.Key_C) toggleExclusive(clipboardBlock)
        else if (event.key === Qt.Key_N) toggleExclusive(notificationBlock)
        else if (event.key === Qt.Key_W) toggleExclusive(meteoBlock)
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

        showCells: false

        // Left top
        GridBlock {
            id: clipboardBlock
            column: 0; row: 0
            columnSpan: 12; rowSpan: 14

            ClipboardLog {
                anchors.fill: parent
                color: ActiveTheme.colors["BG_FOCUSED"]
                entries: ClipboardService.history

                onToggleRequested: clipboardBlock.toggle()
            }
        }

        // Left bottom
        GridBlock {
            id: meteoBlock
            column: 0; row: 14
            columnSpan: 12; rowSpan: 6

            WeatherMenu {
                anchors.fill: parent
                active: root.active
                expanded: meteoBlock.expanded
                onToggleRequested: meteoBlock.toggle()
            }
        }

        // Center top
        GridBlock {
            id: systemBlock
            column: 12; row: 0
            columnSpan: 16; rowSpan: 6

            SystemInfoMenu {
                anchors.fill: parent
                expanded: systemBlock.expanded
                onToggleRequested: systemBlock.toggle()
            }
        }

        // Center bottom
        GridBlock {
            id: calendarBlock
            column: 12; row: 6
            columnSpan: 16; rowSpan: 14

            Calendar {
                id: calendar
                anchors.centerIn: parent
                uiScale: 1
            }
        }

        // Right
        GridBlock {
            id: notificationBlock
            column: 28; row: 0
            columnSpan: 12; rowSpan: 20

            NotificationLog {
                anchors.fill: parent
                color: ActiveTheme.colors["BG_FOCUSED"]
                entries: NotificationService.history

                onToggleRequested: notificationBlock.toggle()
            }
        }
    }
}
