/* quickshell/shell/widgets/components/default/DefaultMenu.qml */


import QtQuick
import Quickshell.Widgets
import Quickshell.Services.Mpris
import ElysianShell.Themes
import ElysianShell.Services
import "../../base"     // For ClockText widget

Item {
    id: root

    property real horizontalPadding: 20
    property real verticalPadding: 8
    property bool expanded: false
    property int clockPixelSize: 16

    property real _batteryPercentage: BatteryService.percentage
    property string _batteryStatus:   BatteryService.statusText

    readonly property var _activePlayer: {
        const players = Mpris.players.values
        for (let p of players) {
            if (p.isPlaying) return p
        }
        return players.length > 0 ? players[0] : null
    }
    readonly property bool _hasMedia: root.expanded && root._activePlayer !== null

    // ---- STABLE target size for the clock, decoupled from the animating text ----
    readonly property real _targetClockPixelSize: root.expanded ? root.clockPixelSize * 1.6 : root.clockPixelSize

    FontMetrics {
        id: clockMetrics
        font.bold: true
        font.pixelSize: root._targetClockPixelSize
    }

    // Fixed-width sample since the clock format is "hh:mm" -> consistent digit count
    readonly property real _clockTargetWidth:  clockMetrics.boundingRect("00:00").width
    readonly property real _clockTargetHeight: clockMetrics.boundingRect("00:00").height

    readonly property real _dateHeight: dateMetrics.height
    FontMetrics {
        id: dateMetrics
        font.pixelSize: 11
    }

    readonly property real _clockColumnTargetHeight:
        _clockTargetHeight + (root.expanded ? (2 + _dateHeight) : 0)   // 2 = Column spacing

    implicitWidth: root.expanded
        ? mediaInfo.implicitWidth + _clockTargetWidth + batteryIcon.implicitWidth + root.horizontalPadding * 9
        : _clockTargetWidth + root.horizontalPadding * 2

    implicitHeight: root.expanded
        ? _clockColumnTargetHeight + root.verticalPadding * 4
        : _clockTargetHeight + root.verticalPadding * 1.5

    readonly property real basePillHeight: _clockTargetHeight + verticalPadding * 2

    // ---------------- LEFT: media info ----------------
    Row {
        id: mediaInfo
        opacity: root._hasMedia ? 1 : 0
        visible: opacity > 0
        spacing: 8
        clip: true   // guards against a stray 3rd wrapped line pushing past bounds
        anchors {
            left: parent.left
            leftMargin: root.horizontalPadding
            verticalCenter: parent.verticalCenter
        }

        Behavior on opacity {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }

        property real textMaxWidth: 90   // tune to taste — this is what caps mediaInfo's footprint

        ClippingRectangle {
            id: albumArtMask
            width: 32
            height: 32
            radius: 8
            color: "transparent"
            anchors.verticalCenter: parent.verticalCenter

            Image {
                anchors.fill: parent
                source: root._activePlayer && root._activePlayer.trackArtUrl
                        ? root._activePlayer.trackArtUrl : ""
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
            }
        }

        Column {
            width: mediaInfo.textMaxWidth
            anchors.verticalCenter: parent.verticalCenter
            spacing: 1

            Row {
                width: parent.width
                spacing: 4
                Text {
                    text: "♫"
                    color: ActiveTheme.colors["ACCENT_LOW"]
                    font.pixelSize: 11
                }
                Text {
                    width: parent.width - 15   // leaves room for the note glyph + spacing
                    text: root._activePlayer ? root._activePlayer.trackTitle : ""
                    color: ActiveTheme.colors["FG"]
                    font.bold: true
                    font.pixelSize: 11
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }
            }

            Text {
                width: parent.width
                text: root._activePlayer ? root._activePlayer.trackArtist : ""
                color: ActiveTheme.colors["FG_MUTED"]
                font.pixelSize: 10
                maximumLineCount: 1
                elide: Text.ElideRight
            }
        }
    }

    // ---------------- CENTER: clock + date ----------------
    Column {
        id: clockColumn
        anchors.centerIn: parent
        spacing: root.expanded ? 2 : 0

        Behavior on spacing {
            NumberAnimation { duration: 200; easing.type: Easing.InOutCubic }
        }

        Clock {
            id: clock
            anchors.horizontalCenter: parent.horizontalCenter
            pixelSize: root._targetClockPixelSize

            Behavior on pixelSize {
                NumberAnimation { duration: 200; easing.type: Easing.InOutCubic }
            }
        }

        Item {
            id: dateWrapper
            anchors.horizontalCenter: parent.horizontalCenter
            width: dateText.implicitWidth
            height: root.expanded ? dateMetrics.height : 0
            clip: true

            Behavior on height {
                NumberAnimation { duration: 200; easing.type: Easing.InOutCubic }
            }

            Text {
                id: dateText
                anchors.top: parent.top   // pin to top of wrapper so clipping trims cleanly as height shrinks
                opacity: root.expanded ? 1 : 0
                text: Qt.formatDate(new Date(), "ddd, MMM d")
                color: ActiveTheme.colors["FG_MUTED"]
                font.pixelSize: 11

                Behavior on opacity {
                    NumberAnimation { duration: 200; easing.type: Easing.InOutCubic }
                }
            }
        }
    }

    // ---------------- RIGHT: wifi + battery ----------------
    Row {
        id: batteryIcon
        opacity: root.expanded ? 1 : 0
        visible: opacity > 0
        anchors {
            verticalCenter: parent.verticalCenter
            right: parent.right
            rightMargin: root.horizontalPadding
        }
        spacing: 6

        Behavior on opacity {
            NumberAnimation { duration: 200; easing.type: Easing.InOutCubic }
        }

        Text {
            text: "📶"
            color: ActiveTheme.colors["FG"]
            font.pixelSize: 12
            anchors.verticalCenter: parent.verticalCenter
        }

        Row {
            spacing: 1
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                id: batteryBody
                implicitWidth: 25
                implicitHeight: 15
                anchors.verticalCenter: parent.verticalCenter
                radius: 5
                color: "transparent"
                border {
                    width: 1.5
                    color: ActiveTheme.colors["FG"]
                }
                clip: true

                Rectangle {
                    id: batteryFill
                    anchors {
                        left: parent.left
                        top: parent.top
                        bottom: parent.bottom
                        margins: 2.5
                    }
                    width: (parent.width - anchors.margins * 2) * root._batteryPercentage
                    radius: 3
                    color: ActiveTheme.colors["ACCENT_LOW"]

                    Behavior on width {
                        NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                    }
                }

                Text {
                    anchors.centerIn: parent
                    z: 1
                    text: Math.round(root._batteryPercentage * 100)
                    font.pixelSize: 8
                    font.bold: true
                    color: ActiveTheme.colors["BG"]
                }
            }

            Rectangle {
                implicitWidth: 1.5
                implicitHeight: 6
                anchors.verticalCenter: parent.verticalCenter
                radius: height / 2
                color: ActiveTheme.colors["FG"]
            }
        }
    }
}
