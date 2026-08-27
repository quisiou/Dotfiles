/* quickshell/shell/widgets/components/lock/LockVisual.qml */


import QtQuick
import QtQuick.Effects
import "../../base"     // For ClockText widget

Item {
    id: root
    property string wallpaper: ""
    property real clockPixelSize: 64

    Image {
        id: bg
        anchors.fill: parent
        source: root.wallpaper
        fillMode: Image.PreserveAspectCrop
        opacity: 0   // never shown directly — only feeds MultiEffect below
        cache: true
        asynchronous: true
    }

    MultiEffect {
        anchors.fill: parent
        source: bg
        blurEnabled: true
        blur: 1.0
        blurMultiplier: 2.5
        brightness: -0.15
    }

    ClockText {
        anchors.centerIn: parent
        pixelSize: root.clockPixelSize
    }
}
