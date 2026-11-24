/* quickshell/shell/widgets/components/default/DefaultMenu.qml */


import QtQuick
import ElysianShell.Themes
import ElysianShell.Services
import "modules"

Item {
    id: root

    // ── Inputs ───────────────────────────────────────────────────────────────
    property bool isPill: false
    property bool expanded: false
    property bool mouseEnabled: false
    property real barHeight: 32                  // collapsed height, set by the panel
    property int  clockPixelSize: 16
    property real expandedClockScale: 1.5

    // ── Spacing ──────────────────────────────────────────────────────────────
    property real horizontalPadding: 10
    property real expandedPadding: 16            // top/bottom when expanded
    property real expandedExtraWidth: 160        // air between media | clock | system
    property real centerGap: 10                  // clock <-> cava
    readonly property real pillInset: isPill ? 8 : 0   // extra side room for round ends

    readonly property real _cavaWidth: cavaRow.visible
        ? (cavaRow.numBars * 3 + (cavaRow.numBars - 1) * 2 + root.centerGap)
        : 0

    // ── Size: read from live items, nothing in here animates ─────────────────
    implicitWidth: expanded
        ? mediaRect.implicitWidth + clockColumn.targetWidth + systemRect.implicitWidth
          + expandedExtraWidth + pillInset * 2
        : clockColumn.targetWidth + _cavaWidth + horizontalPadding * 2.5 + pillInset * 2

    implicitHeight: expanded
        ? Math.max(barHeight, clockColumn.targetHeight + expandedPadding * 2)
        : barHeight

    signal dashboardTabRequested()
    signal mediaTabRequested()
    signal systemTabRequested()

    // ---------------- LEFT: media info ----------------
    Rectangle {
        id: mediaRect
        color: "transparent"
        radius: 12
        opacity: root.expanded ? 1 : 0
        anchors {
            left: parent.left
            leftMargin: root.horizontalPadding + root.pillInset
            verticalCenter: parent.verticalCenter
        }
        implicitWidth: mediaModule.implicitWidth + 12
        implicitHeight: mediaModule.implicitHeight + 12

        Behavior on opacity {
            NumberAnimation { duration: 200; easing.type: Easing.InOutCubic }
        }

        Behavior on color {
            ColorAnimation { duration: 150; easing.type: Easing.InOutCubic }
        }

        MouseArea {
            enabled: root.mouseEnabled
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true

            onEntered:  mediaRect.color = ActiveTheme.colors["ACCENT_HIGH"].replace("#", "#40")
            onExited:   mediaRect.color = "transparent"
            onClicked:  root.mediaTabRequested()
        }

        MediaModule { id: mediaModule; anchors.centerIn: parent }
    }


    // ---------------- CENTER: clock + date ----------------
    Item {
        id: centerContainer
        anchors.fill: parent

        Row {
            id: cavaRow
            spacing: 2
            opacity: MediaService.isPlaying && !root.expanded ? 1 : 0
            visible: opacity > 0
            anchors.right: clockColumn.left
            anchors.rightMargin: root.centerGap
            anchors.verticalCenter: clockColumn.verticalCenter

            property int numBars: 5

            property var cavaBars: {
                const values = VisualizerService.displayValues || [];
                if (values.length === 0) return Array(cavaRow.numBars).fill(0);

                const chunkSize = Math.floor(values.length / cavaRow.numBars);
                let result = [];

                for (let i = 0; i < cavaRow.numBars; i++) {
                    let max = 0;
                    let start = i * chunkSize;
                    let end = (i + 1) * chunkSize;

                    for (let j = start; j < end; j++) {
                        if (values[j] > max) max = values[j];
                    }
                    result.push(max);
                }
                return result;
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.InOutCubic
                }
            }

            Repeater {
                model: cavaRow.cavaBars

                delegate: Rectangle {
                    id: bar

                    required property var modelData
                    readonly property real targetHeight: Math.max(3, (modelData / 125) * 20)

                    width: 3
                    height: targetHeight
                    radius: width / 2
                    color: ActiveTheme.colors["ACCENT_LOW"] ?? "cyan"
                    antialiasing: true

                    anchors.verticalCenter: parent.verticalCenter

                    Behavior on height {
                        NumberAnimation {
                            duration: 1250 / (VisualizerService.frameRate || 60)
                            easing.type: Easing.OutQuad
                        }
                    }
                }
            }
        }

        // Clock Module - dead center when expanded; when collapsed, shifts right
        // just enough to keep itself + the cava bars balanced around center
        ClockModule {
            id: clockColumn
            expanded: root.expanded
            clockPixelSize: root.clockPixelSize
            expandedScale: root.expandedClockScale
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.horizontalCenterOffset: root.expanded ? 0 : root._cavaWidth / 2
            anchors.verticalCenter: parent.verticalCenter

            Behavior on anchors.horizontalCenterOffset {
                NumberAnimation { duration: 200; easing.type: Easing.InOutCubic }
            }
        }

        // Hover/click target — only the clock's own bounds, not the cava bars
        MouseArea {
            enabled: root.mouseEnabled
            anchors.fill: clockColumn
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true
            onClicked: root.dashboardTabRequested()
        }
    }

    // ---------------- RIGHT: wifi + battery ----------------
    Rectangle {
        id: systemRect
        color: "transparent"
        radius: 12
        opacity: root.expanded ? 1 : 0
        anchors {
            verticalCenter: parent.verticalCenter
            right: parent.right
            rightMargin: root.horizontalPadding * 3 + root.pillInset
        }
        implicitWidth: systemModule.implicitWidth + 12
        implicitHeight: systemModule.implicitHeight + 12

        Behavior on opacity {
            NumberAnimation { duration: 200; easing.type: Easing.InOutCubic }
        }

        Behavior on color {
            ColorAnimation { duration: 150; easing.type: Easing.InOutCubic }
        }

        MouseArea {
            enabled: root.mouseEnabled
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true

            onEntered:  systemRect.color = ActiveTheme.colors["ACCENT_HIGH"].replace("#", "#40")
            onExited:   systemRect.color = "transparent"
            onClicked:  root.systemTabRequested()
        }

        SystemModule { id: systemModule; anchors.centerIn: parent }
    }
}
