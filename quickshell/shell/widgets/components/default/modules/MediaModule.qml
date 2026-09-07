/* quickshell/shell/widgets/components/default/modules/MediaModule.qml */


import QtQuick
import Quickshell.Widgets
import ElysianShell.Themes
import ElysianShell.Services

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

        Item {
            id: titleClip
            width: parent.width - 10
            height: titleText.implicitHeight
            clip: true

            property bool shouldMarquee: titleText.implicitWidth > titleClip.width

            Text {
                id: titleText
                text: MediaService.title || "Idle"
                color: ActiveTheme.colors["FG"]
                font.bold: true
                font.pixelSize: 11
            }

            SequentialAnimation {
                id: marqueeAnim
                loops: Animation.Infinite

                PauseAnimation { duration: 2000 }

                NumberAnimation {
                    target: titleText
                    property: "x"
                    to: titleClip.width - titleText.implicitWidth - 6
                    duration: Math.max(1200, (titleText.implicitWidth - titleClip.width) * 40)
                    easing.type: Easing.Linear
                }

                PauseAnimation { duration: 1200 }

                NumberAnimation {
                    target: titleText
                    property: "x"
                    to: 0
                    duration: Math.max(1200, (titleText.implicitWidth - titleClip.width) * 40)
                    easing.type: Easing.Linear
                }

                PauseAnimation { duration: 500 }
            }

            onShouldMarqueeChanged: restartMarquee()
            Component.onCompleted: restartMarquee()

            function restartMarquee() {
                marqueeAnim.stop()
                titleText.x = 0
                if (shouldMarquee) marqueeAnim.start()
            }
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
