/* quickshell/shell/widgets/components/default/modules/MediaModule.qml */


import QtQuick
import Quickshell.Widgets
import ElysianShell.Themes
import ElysianShell.Services
import "../../../base"

Row {
    id: root
    spacing: 8
    clip: true

    property real textMaxWidth: 90

    Text {
        text: "\udb81\udf5b"
        font.pixelSize: 32
        color: ActiveTheme.colors["FG_MUTED"]
        visible: !MediaService.hasPlayer
        anchors.verticalCenter: parent.verticalCenter
    }

    ClippingRectangle {
        id: albumArtMask
        width: 32
        height: 32
        radius: width / 2
        color: "transparent"
        anchors.verticalCenter: parent.verticalCenter
        visible: MediaService.hasPlayer

        Image {
            id: albumArt
            anchors.fill: parent
            source: MediaService.artUrl
            sourceSize.width: 48
            sourceSize.height: 48
            fillMode: Image.PreserveAspectCrop   // fills the circle, no letterboxing gaps
            asynchronous: true

            property real currentRotation: 0
            rotation: currentRotation

            FrameAnimation {
                running: MediaService.hasPlayer && MediaService.isPlaying
                onTriggered: albumArt.currentRotation = (albumArt.currentRotation + frameTime * 60) % 360
            }
        }

        // the "donut hole" in the middle
        Rectangle {
            width: parent.width * 0.25
            height: width
            radius: width / 2
            anchors.centerIn: parent
            color: ActiveTheme.colors["BG"]   // match whatever sits behind this widget
            border.color: ActiveTheme.colors["FG_MUTED"]
            border.width: 1
            visible: MediaService.hasPlayer
        }
    }

    Column {
        width: root.textMaxWidth
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1

        Marquee {
            width: parent.width - 10
            text: MediaService.title || "Idle"
            color: ActiveTheme.colors["FG"]
            font.bold: true
            font.pixelSize: 11
        }

        Text {
            width: parent.width
            text: MediaService.artist || "No media playing"
            color: ActiveTheme.colors["FG_MUTED"]
            font.pixelSize: 10
            maximumLineCount: 1
            elide: Text.ElideRight
        }
    }
}
