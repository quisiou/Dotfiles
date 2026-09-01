/* quickshell/shell/widgets/components/control/pages/MediaPage.qml */


pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell.Services.Mpris
import ElysianShell.Themes

Item {
    id: root

    implicitWidth: 320
    implicitHeight: textColumn.implicitHeight

    anchors.fill: parent

    readonly property var _activePlayer: {
        const players = Mpris.players.values
        for (let p of players) {
            if (p.isPlaying) return p
        }
        return players.length > 0 ? players[0] : null
    }
    readonly property bool _playing: root._activePlayer && root._activePlayer.trackArtUrl

    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: 50

        ClippingRectangle {
            id: albumArtMask
            width: 180
            height: 180
            radius: height / 2
            color: "transparent"
            anchors.verticalCenter: parent.verticalCenter

            Text {
                text: "\udb81\udf5b"
                font.pixelSize: albumArtMask.height
                color: ActiveTheme.colors["FG_MUTED"]
                visible: !root._playing
                anchors.centerIn: parent
            }

            Image {
                anchors.fill: parent
                source: root._playing ? root._activePlayer.trackArtUrl : ""
                sourceSize {
                    width:  albumArtMask.width
                    height: albumArtMask.height
                }
                width:  albumArtMask.width
                height: albumArtMask.height
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                visible: root._playing
            }
        }

        ColumnLayout {
            id: textColumn
            anchors.verticalCenter: parent.verticalCenter
            Layout.maximumWidth: root.width
            spacing: 6

            Text {
                id: titleText
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: root.width
                text: root._activePlayer ? root._activePlayer.trackTitle : "Idle"
                color: ActiveTheme.colors["ACCENT_LOW"]
                font.pixelSize: 17
                font.bold: true
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
            }

            Text {
                id: albumText
                Layout.alignment: Qt.AlignHCenter
                text: root._activePlayer ? root._activePlayer.trackAlbum : "No media playing"
                color: ActiveTheme.colors["FG_MUTED"]
                font.pixelSize: 13
                elide: Text.ElideRight
            }

            Text {
                id: artistText
                Layout.alignment: Qt.AlignHCenter
                text: root._activePlayer ? root._activePlayer.trackArtist : "No media playing"
                color: ActiveTheme.colors["FG"]
                font.pixelSize: 13
                elide: Text.ElideRight
            }
        }
    }
}