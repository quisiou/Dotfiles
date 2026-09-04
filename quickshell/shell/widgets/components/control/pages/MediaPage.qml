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

        Item {
            id: visualizerItem

            property int   artSize: 160
            property int   radius: artSize/2 + 10 // +N is the gap between art and visualizer
            property int   barWidth: 5
            property int   maxBarHeight: 50
            property color barColor: ActiveTheme.colors["ACCENT"]

            anchors.verticalCenter: parent.verticalCenter

            width: (radius + maxBarHeight) * 2
            height: width

            // drive the cava process only while this is actually visible
            onVisibleChanged: VisualizerService.active = visible
            Component.onCompleted: VisualizerService.active = visible
            Component.onDestruction: VisualizerService.active = false

            Repeater {
                model: VisualizerService.bars

                delegate: Rectangle {
                    id: bar
                    required property int index

                    readonly property real rawValue: (VisualizerService.values[index] ?? 0)
                    readonly property real targetHeight: Math.max(2, (rawValue / 100) * visualizerItem.maxBarHeight)

                    width: visualizerItem.barWidth
                    height: targetHeight
                    radius: width / 2
                    color: visualizerItem.barColor
                    antialiasing: true

                    // fixed base at `radius` from center; grows outward as height increases
                    x: visualizerItem.width / 2 - width / 2
                    y: visualizerItem.height / 2 - visualizerItem.radius - height

                    transform: Rotation {
                        origin.x: bar.width / 2
                        origin.y: visualizerItem.radius + bar.height
                        angle: bar.index * (360 / VisualizerService.bars)
                    }

                    Behavior on height {
                        NumberAnimation { duration: 1250 / VisualizerService.frameRate; easing.type: Easing.OutQuad }
                    }
                }
            }

            ClippingRectangle {
                id: albumArtMask
                width: visualizerItem.artSize
                height: visualizerItem.artSize
                radius: height / 2
                color: "transparent"
                anchors.centerIn: parent

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