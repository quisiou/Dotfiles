// quickshell/shell/widgets/base/GridBlock.qml


pragma ComponentBehavior: Bound

import QtQuick
import ElysianShell.Themes

Rectangle {
    id: root

    property int column: 0
    property int row: 0
    property int columnSpan: 1
    property int rowSpan: 1

    readonly property var grid: parent

    x: column * (grid.blockWidth + grid.spacing)
    y: row * (grid.blockHeight + grid.spacing)
    width: columnSpan * grid.blockWidth + (columnSpan - 1) * grid.spacing
    height: rowSpan * grid.blockHeight + (rowSpan - 1) * grid.spacing

    clip: true

    radius: 12
    color: ActiveTheme.colors["BG_FOCUSED"]
}
