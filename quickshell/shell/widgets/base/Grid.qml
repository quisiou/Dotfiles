// quickshell/shell/widgets/base/Grid.qml


pragma ComponentBehavior: Bound

import QtQuick
import ElysianShell.Themes

Item {
    id: root

    property int columns: 20
    property int rows: 10

    property real blockWidth: 40
    property real blockHeight: 40
    property real spacing: 12

    // Draw the empty cells, useful to verify the geometry
    property bool showCells: false

    implicitWidth: columns * blockWidth + (columns - 1) * spacing
    implicitHeight: rows * blockHeight + (rows - 1) * spacing

    Repeater {
        model: root.showCells ? root.columns * root.rows : 0

        Rectangle {
            required property int index

            x: (index % root.columns) * (root.blockWidth + root.spacing)
            y: Math.floor(index / root.columns) * (root.blockHeight + root.spacing)
            width: root.blockWidth
            height: root.blockHeight
            color: "transparent"
            border.width: 1
            border.color: ActiveTheme.colors["FG_GHOST"]
            opacity: 0.4
        }
    }
}
