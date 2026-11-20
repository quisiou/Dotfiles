/* quickshell/shell/widgets/base/Marquee.qml */


import QtQuick

// Single-line text that slides sideways when it doesn't fit, pauses, then slides back.
// Give it a width (Layout.fillWidth or width:). It never sizes itself from the text,
// otherwise it would push its parent wider instead of scrolling.
Item {
    id: root

    property string text: ""
    property color color: "white"
    property alias font: label.font

    // Gate: the text only moves while this is true (for example only while a card is expanded)
    property bool running: true

    // When the text fits, centre it instead of left-aligning it
    property bool centerWhenFits: false

    // Timing (defaults match MediaModule)
    property int startDelay: 2000     // pause before sliding
    property int endDelay: 1200       // pause at the far end
    property int restDelay: 500       // pause before the next loop
    property int msPerPixel: 40       // slide speed
    property int minDuration: 1200
    property int endMargin: 6         // extra pixels past the last character
    property int settleDelay: 350     // wait for width changes (expand animations) to finish

    readonly property real overflow: Math.max(0, label.implicitWidth - width)
    readonly property bool scrolling: anim.running

    // Where the text sits when it is not moving
    readonly property real _restX:
        centerWhenFits && overflow <= 0 ? (width - label.implicitWidth) / 2 : 0

    implicitWidth: 0
    implicitHeight: label.implicitHeight
    clip: true

    function reset() {
        anim.stop()
        label.x = _restX
    }

    function restart() {
        reset()
        if (running && overflow > 0) anim.start()
    }

    Timer { id: settle; interval: root.settleDelay; onTriggered: root.restart() }

    onRunningChanged: running ? settle.restart() : reset()
    onOverflowChanged: { reset(); settle.restart() }
    onTextChanged: { reset(); settle.restart() }
    // Keep centred while the width changes, without waiting for the settle timer
    onWidthChanged: if (!anim.running) label.x = _restX
    Component.onCompleted: { reset(); settle.restart() }

    Text {
        id: label
        text: root.text
        color: root.color
    }

    SequentialAnimation {
        id: anim
        loops: Animation.Infinite

        PauseAnimation { duration: root.startDelay }
        NumberAnimation {
            target: label; property: "x"
            to: -root.overflow - root.endMargin
            duration: Math.max(root.minDuration, root.overflow * root.msPerPixel)
            easing.type: Easing.Linear
        }
        PauseAnimation { duration: root.endDelay }
        NumberAnimation {
            target: label; property: "x"
            to: 0
            duration: Math.max(root.minDuration, root.overflow * root.msPerPixel)
            easing.type: Easing.Linear
        }
        PauseAnimation { duration: root.restDelay }
    }
}
