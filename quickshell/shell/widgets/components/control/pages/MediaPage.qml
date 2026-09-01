/* quickshell/shell/widgets/components/control/pages/MediaPage.qml */


pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import ElysianShell.Themes
import ElysianShell.Services

Item {
    id: root

    implicitWidth: 320
    implicitHeight: textColumn.implicitHeight

    anchors.fill: parent

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
                visible: !MediaService.hasPlayer
                anchors.centerIn: parent
            }

            Image {
                anchors.fill: parent
                source: MediaService.artUrl
                sourceSize {
                    width:  albumArtMask.width
                    height: albumArtMask.height
                }
                width:  albumArtMask.width
                height: albumArtMask.height
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                visible: MediaService.hasPlayer
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
                text: MediaService.title || "Idle"
                color: ActiveTheme.colors["ACCENT_LOW"]
                font.pixelSize: 17
                font.bold: true
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
            }

            Text {
                id: albumText
                Layout.alignment: Qt.AlignHCenter
                text: MediaService.album || "No media playing"
                color: ActiveTheme.colors["FG_MUTED"]
                font.pixelSize: 13
                elide: Text.ElideRight
            }

            Text {
                id: artistText
                Layout.alignment: Qt.AlignHCenter
                text: MediaService.artist || "No media playing"
                color: ActiveTheme.colors["FG"]
                font.pixelSize: 13
                elide: Text.ElideRight
            }
        }
    }
}