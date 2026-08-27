/* quickshell/shell/widgets/components/default/DefaultMenu.qml */


import QtQuick
import Quickshell.Widgets
import Quickshell.Services.Mpris
import ElysianShell.Themes
import ElysianShell.Services
import "../../base"     // For ClockText widget

Item {
    id: root

    property real horizontalPadding: 10
    property real verticalPadding: 8
    property bool expanded: false
    property int clockPixelSize: 16
    property bool mouseEnabled: false

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

    readonly property real _clockWrapperTargetHeight:
        _clockTargetHeight + (root.expanded ? (2 + _dateHeight) : 0)   // 2 = Column spacing

    implicitWidth: root.expanded
        ? mediaRect.implicitWidth + _clockTargetWidth + systemRect.implicitWidth + root.horizontalPadding * 18
        : _clockTargetWidth + root.horizontalPadding * 4

    implicitHeight: root.expanded
        ? _clockWrapperTargetHeight + root.verticalPadding * 4
        : _clockTargetHeight + root.verticalPadding * 1.5

    readonly property real basePillHeight: _clockTargetHeight + verticalPadding * 2

    signal dashboardTabRequested()
    signal mediaTabRequested()
    signal systemTabRequested()

    // ---------------- LEFT: media info ----------------
    Rectangle {
        id: mediaRect
        color: ActiveTheme.colors["ACCENT"].replace("#", "#20")
        radius: 12
        opacity: root._hasMedia ? 1 : 0
        visible: opacity > 0
        anchors {
            left: parent.left
            leftMargin: root.horizontalPadding
            verticalCenter: parent.verticalCenter
        }
        border {
            width: 1
            color: ActiveTheme.colors["BG_HIGHLIGHT"]
        }
        implicitWidth: mediaInfo.implicitWidth + 16
        implicitHeight: mediaInfo.implicitHeight + 12

        Behavior on opacity {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }

        MouseArea {
            enabled: root.mouseEnabled
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true

            onEntered:  mediaRect.color = ActiveTheme.colors["ACCENT_LOW"].replace("#", "#20")
            onExited:   mediaRect.color = ActiveTheme.colors["ACCENT"].replace("#", "#20")
            onClicked:  root.mediaTabRequested()
        }

        Row {
            id: mediaInfo
            spacing: 8
            clip: true
            anchors.centerIn: parent

            property real textMaxWidth: 90

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

                Item {
                    id: titleClip
                    width: parent.width - 10
                    height: titleText.implicitHeight
                    clip: true

                    property bool shouldMarquee: titleText.implicitWidth > titleClip.width

                    Text {
                        id: titleText
                        text: root._activePlayer ? root._activePlayer.trackTitle : ""
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
                    text: root._activePlayer ? root._activePlayer.trackArtist : ""
                    color: ActiveTheme.colors["FG_MUTED"]
                    font.pixelSize: 10
                    maximumLineCount: 1
                    elide: Text.ElideRight
                }
            }
        }
    }

    // ---------------- CENTER: clock + date ----------------
    Item {
        id: clockWrapper
        anchors.centerIn: parent
        implicitWidth: clockColumn.implicitWidth
        implicitHeight: clockColumn.implicitHeight

        MouseArea {
            enabled: root.mouseEnabled
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked:  root.dashboardTabRequested()
        }

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
    }

    // ---------------- RIGHT: wifi + battery ----------------
    Rectangle {
        id: systemRect
        color: ActiveTheme.colors["ACCENT"].replace("#", "#20")
        radius: 12
        opacity: root.expanded ? 1 : 0
        visible: opacity > 0
        anchors {
            verticalCenter: parent.verticalCenter
            right: parent.right
            rightMargin: root.horizontalPadding * 3
        }
        border {
            width: 1
            color: ActiveTheme.colors["BG_HIGHLIGHT"]
        }
        implicitWidth: systemRow.implicitWidth + 16
        implicitHeight: systemRow.implicitHeight + 12

        MouseArea {
            enabled: root.mouseEnabled
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true

            onEntered:  systemRect.color = ActiveTheme.colors["ACCENT_LOW"].replace("#", "#20")
            onExited:   systemRect.color = ActiveTheme.colors["ACCENT"].replace("#", "#20")
            onClicked:  root.systemTabRequested()
        }

        Row {
            id: systemRow
            spacing: 6
            anchors.centerIn: parent

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
}
