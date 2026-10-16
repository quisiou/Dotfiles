// quickshell/shell/widgets/base/Glass.qml


import QtQuick
import ElysianShell.Themes

// Simple glass look: faint top-lit tint, a highlight on the top edge, a hairline border.
// Place it as the first child of a block, below the content.
Item {
    id: root

    property real radius: 12
    property real tint: 1.0      // overall strength: 0 = invisible, 1 = default, 1.5 = stronger
    property bool showTint: true

    // Tint: lighter at the top, almost nothing at the bottom
    Rectangle {
        anchors.fill: parent
        radius: root.radius
        visible: root.showTint
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.alpha(ActiveTheme.colors["ACCENT_LOW"], 0.09 * root.tint) }
            GradientStop { position: 0.5; color: Qt.alpha(ActiveTheme.colors["ACCENT"],     0.04 * root.tint) }
            GradientStop { position: 1.0; color: Qt.alpha(ActiveTheme.colors["ACCENT"],     0.02 * root.tint) }
        }
    }

    // Highlight along the top edge, fading out toward the corners
    Rectangle {
        height: 1
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            topMargin: 1
            leftMargin: root.radius
            rightMargin: root.radius
        }
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: "transparent" }
            GradientStop { position: 0.5; color: Qt.alpha(ActiveTheme.colors["FG"], 0.18 * root.tint) }
            GradientStop { position: 1.0; color: "transparent" }
        }
    }

    // Hairline border
    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: "transparent"
        border.width: 1
        border.color: Qt.alpha(ActiveTheme.colors["FG"], 0.07 * root.tint)
    }
}
