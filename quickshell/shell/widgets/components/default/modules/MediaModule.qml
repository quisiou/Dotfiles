/* quickshell/shell/widgets/components/default/modules/MediaModule.qml */


import QtQuick
import Quickshell.Widgets
import Quickshell.Services.Mpris
import ElysianShell.Themes

Row {
    id: root
    spacing: 8
    clip: true

    property real textMaxWidth: 90
    readonly property var _activePlayer: {
        const players = Mpris.players.values
        for (let p of players) {
            if (p.isPlaying) return p
        }
        return players.length > 0 ? players[0] : null
    }

    ClippingRectangle {
        id: albumArtMask
        width: 32
        height: 32
        radius: 8
        color: "transparent"
        anchors.verticalCenter: parent.verticalCenter

        Text {
            text: "\udb81\udf5b"
            font.pixelSize: 32
            color: ActiveTheme.colors["FG_MUTED"]
            visible: !(root._activePlayer && root._activePlayer.trackArtUrl)
            anchors.centerIn: parent
        }

        Image {
            anchors.fill: parent
            source: root._activePlayer.trackArtUrl
            sourceSize {
                width:  48
                height: 48
            }
            width:  48
            height: 48
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            visible: root._activePlayer && root._activePlayer.trackArtUrl
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
                text: root._activePlayer ? root._activePlayer.trackTitle : "Idle"
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
            text: root._activePlayer ? root._activePlayer.trackArtist : "No media playing"
            color: ActiveTheme.colors["FG_MUTED"]
            font.pixelSize: 10
            maximumLineCount: 1
            elide: Text.ElideRight
        }
    }
}
