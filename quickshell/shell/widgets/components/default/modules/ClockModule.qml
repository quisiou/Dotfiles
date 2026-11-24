/* quickshell/shell/widgets/components/default/modules/ClockModule.qml */


import QtQuick
import ElysianShell.Themes
import "../../../base"     // For ClockText widget

Item {
    id: root

    property bool expanded: false
    property real clockPixelSize: 16
    property real expandedScale: 1.6
    property real gap: 2                       // clock <-> date when expanded

    // Stable targets: depend only on `expanded`, never on animated values.
    // DefaultMenu sizes itself from these.
    readonly property real targetWidth:  clock.implicitWidth * (expanded ? expandedScale : 1)
    readonly property real targetHeight: clock.implicitHeight * (expanded ? expandedScale : 1)
                                         + (expanded ? gap + dateText.implicitHeight : 0)

    // Animated progress 0..1: the only animated thing, drives every visual below
    property real t: expanded ? 1 : 0
    Behavior on t { NumberAnimation { duration: 200; easing.type: Easing.InOutCubic } }
    readonly property real _s: 1 + (expandedScale - 1) * t

    // Live size: what the parent centers and what the click area follows
    implicitWidth:  clock.implicitWidth * _s
    implicitHeight: clock.implicitHeight * _s + t * (gap + dateText.implicitHeight)
    width:  implicitWidth
    height: implicitHeight

    ClockText {
        id: clock
        pixelSize: root.clockPixelSize
        anchors.horizontalCenter: parent.horizontalCenter
        y: implicitHeight * (root._s - 1) / 2     // keeps the scaled glyphs' top edge at y = 0
        scale: root._s                            // grows from its center
    }

    Text {
        id: dateText
        anchors.horizontalCenter: parent.horizontalCenter
        y: clock.implicitHeight * root._s + root.gap * root.t
        visible: root.t > 0
        opacity: root.t
        text: Qt.formatDate(new Date(), "ddd, MMM d")
        color: ActiveTheme.colors["FG_MUTED"]
        font.pixelSize: 11
    }
}
