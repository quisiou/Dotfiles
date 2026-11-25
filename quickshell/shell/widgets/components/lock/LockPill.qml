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

    property real horizontalPadding: 15
    property int  maxDots: 16
    property real dotSize: 8
    property real dotSpacing: 7

    readonly property int  length: password.length
    readonly property bool _empty: length === 0
    readonly property int  count: Math.min(length, maxDots)
    readonly property real dotStep: dotSize + dotSpacing
    readonly property real _dotsWidth: count > 0 ? count * dotSize + (count - 1) * dotSpacing : 0

    implicitHeight: barHeight
    implicitWidth: Math.max(barHeight, (_empty ? label.implicitWidth : _dotsWidth) + horizontalPadding * 2)

    Text {
        id: label
        anchors.centerIn: parent
        text: root.message !== "" ? root.message : "\udb80\udf41"
        color: root.message !== "" ? ActiveTheme.colors["ERROR"] : ActiveTheme.colors["FG"]
        font { pixelSize: 20; bold: true }

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
