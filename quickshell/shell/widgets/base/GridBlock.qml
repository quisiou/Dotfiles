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

    // Expand state
    property bool expanded: false
    property int animationDuration: 220
    property real scrimOpacity: 0.5   // how dark the backdrop gets

    readonly property var grid: parent

    // True while an expand/collapse is in flight, so the block keeps its
    // elevated z until it is back in place.
    readonly property bool _animating: xAnim.running || yAnim.running
                                       || wAnim.running || hAnim.running
    // Only animate geometry changes caused by expand()/collapse(),
    // not by the grid being resized.
    property bool _animate: false

    function expand() {
        _animate = true
        expanded = true
    }

    function collapse() {
        _animate = true
        expanded = false
    }

    function expandImmediately() {   // No animation
        _animate = false
        expanded = true
    }

    function collapseImmediately() {   // No animation
        _animate = false
        expanded = false
    }

    function toggle() {
        expanded ? collapse() : expand()
    }

    x: expanded ? grid.blockWidth + grid.spacing : column * (grid.blockWidth + grid.spacing)
    y: expanded ? grid.blockHeight + grid.spacing : row * (grid.blockHeight + grid.spacing)
    width: expanded ? grid.width - 2 * (grid.blockWidth) - grid.spacing
                    : columnSpan * grid.blockWidth + (columnSpan - 1) * grid.spacing
    height: expanded ? grid.height - 2 * (grid.blockHeight) - grid.spacing
                     : rowSpan * grid.blockHeight + (rowSpan - 1) * grid.spacing

    z: (expanded || _animating) ? 100 : 0

    clip: true
    radius: 12
    color: ActiveTheme.colors["BG_FOCUSED"]

    Behavior on x {
        enabled: root._animate
        NumberAnimation { id: xAnim; duration: root.animationDuration; easing.type: Easing.OutCubic }
    }
    Behavior on y {
        enabled: root._animate
        NumberAnimation { id: yAnim; duration: root.animationDuration; easing.type: Easing.OutCubic }
    }
    Behavior on width {
        enabled: root._animate
        NumberAnimation {
            id: wAnim
            duration: root.animationDuration
            easing.type: Easing.OutCubic
            onRunningChanged: if (!running) root._animate = false
        }
    }
    Behavior on height {
        enabled: root._animate
        NumberAnimation { id: hAnim; duration: root.animationDuration; easing.type: Easing.OutCubic }
    }

    // Backdrop dimming the rest of the grid while this block is expanded.
    Rectangle {
        id: scrim

        parent: root.grid          // lives in the grid, not inside the clipped block
        anchors.fill: parent
        z: 99                      // above other blocks (0), below the expanded one (100)

        color: "black"
        opacity: root.expanded ? root.scrimOpacity : 0
        visible: opacity > 0       // don't render when fully transparent

        Behavior on opacity {
            NumberAnimation {
                duration: root._animate ? root.animationDuration : 0
                easing.type: Easing.OutCubic
            }
        }

        // Swallow clicks on the dimmed blocks, and collapse on click outside
        MouseArea {
            anchors.fill: parent
            enabled: root.expanded
            hoverEnabled: true
            onClicked: root.collapse()
        }
    }
}
