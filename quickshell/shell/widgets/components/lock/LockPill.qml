/* quickshell/shell/widgets/components/lock/LockPill.qml */


import QtQuick
import ElysianShell.Themes

Item {
    id: root

    property string password: ""
    property bool   busy: false
    property string message: ""
    property real   barHeight: 36
    property int    animDuration: 200
    property int    easingType: Easing.InOutCubic

    property real horizontalPadding: (barHeight - dotSize) / 2
    property int  maxDots: 16
    property real dotSize: 7
    property real dotSpacing: 7

    readonly property int  length: password.length
    readonly property bool _empty: length === 0
    readonly property int  count: Math.min(length, maxDots)
    readonly property real dotStep: dotSize + dotSpacing
    readonly property real _dotsWidth: count > 0 ? count * dotSize + (count - 1) * dotSpacing : 0

    property real errorAmount: 0    // 0 = normal colour, 1 = fully red
    property real shakeX: 0

    readonly property color _errColor: ActiveTheme.colors["ERROR"]

    implicitHeight: barHeight
    implicitWidth: Math.max(barHeight,
        (_empty ? (message !== "" ? label.implicitWidth : 0) : _dotsWidth) + horizontalPadding * 2)

    function flashError() { errorFlash.restart(); shake.restart() }

    onLengthChanged: if (length > 0) {          // typing again cancels the flash
        errorFlash.stop(); shake.stop()
        errorAmount = 0; shakeX = 0
    }

    SequentialAnimation {
        id: errorFlash
        NumberAnimation { target: root; property: "errorAmount"; to: 1; duration: 80 }
        PauseAnimation  { duration: 800 }
        NumberAnimation { target: root; property: "errorAmount"; to: 0; duration: 400; easing.type: Easing.OutQuad }
    }

    SequentialAnimation {
        id: shake
        NumberAnimation { target: root; property: "shakeX"; to: -5; duration: 50 }
        NumberAnimation { target: root; property: "shakeX"; to:  5; duration: 80 }
        NumberAnimation { target: root; property: "shakeX"; to: -3; duration: 70 }
        NumberAnimation { target: root; property: "shakeX"; to:  0; duration: 50 }
    }

    Text {
        id: label
        anchors.centerIn: parent
        text: root.message !== "" ? root.message : "\udb80\udf41"
        color: root.message !== ""
            ? root._errColor
            : Qt.tint(ActiveTheme.colors["FG"],
                    Qt.rgba(root._errColor.r, root._errColor.g, root._errColor.b, root.errorAmount))
        font { pixelSize: 20; bold: true }
        transform: Translate { x: root.shakeX }

        opacity: root._empty ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 120 } }
    }

    Item {
        id: dotsLayer
        anchors.centerIn: parent
        width: 0; height: 0
        opacity: root.busy ? 0.4 : 1
        Behavior on opacity { NumberAnimation { duration: 100 } }

        Repeater {
            model: root.maxDots

            delegate: Rectangle {
                id: dot
                required property int index

                readonly property bool present: index < root.count

                width: root.dotSize
                height: width
                radius: width / 2
                color: ActiveTheme.colors["FG"]

                x: (index - (Math.max(root.count, 1) - 1) / 2) * root.dotStep - width / 2
                y: -height / 2

                scale: present ? 1 : 0
                opacity: scale

                Behavior on x     { NumberAnimation { duration: root.animDuration; easing.type: root.easingType } }
                Behavior on scale { NumberAnimation { duration: root.animDuration; easing.type: root.easingType } }
            }
        }
    }
}
