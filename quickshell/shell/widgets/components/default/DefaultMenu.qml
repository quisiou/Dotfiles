/* quickshell/shell/widgets/components/default/DefaultMenu.qml */


import QtQuick
import ElysianShell.Themes
import ElysianShell.Services
import "modules"

Item {
    id: root

    property real horizontalPadding: 10
    property real verticalPadding: 8
    property bool expanded: false
    property int clockPixelSize: 16
    property bool mouseEnabled: false

    // ---- STABLE target size for the clock, decoupled from the animating text ----
    readonly property real _targetClockPixelSize: root.expanded ? root.clockPixelSize * 1.6 : root.clockPixelSize

    FontMetrics {
        id: clockMetrics
        font.bold: true
        font.pixelSize: root._targetClockPixelSize
    }
    FontMetrics {
        id: dateMetrics
        font.pixelSize: 11
    }

    // Single source of truth for the gap between the clock and the cava bars.
    // Bump this to widen the spacing — implicitWidth and both anchors follow automatically.
    property real centerGap: 10

    readonly property real _cavaWidth: cavaRow.visible
        ? (cavaRow.numBars * 3 + (cavaRow.numBars - 1) * 2 + root.centerGap)
        : 0

    // Fixed-width sample since the clock format is "hh:mm" -> consistent digit count
    readonly property real _targetClockWidth:  clockMetrics.boundingRect("00:00").width
    readonly property real _targetClockHeight: clockMetrics.boundingRect("00:00").height
    readonly property real _dateHeight: dateMetrics.height

    readonly property real _clockWrapperTargetHeight:
        _targetClockHeight + (root.expanded ? (2 + _dateHeight) : 0)   // 2 = Column spacing

    implicitWidth: root.expanded
        ? mediaRect.implicitWidth + _targetClockWidth + systemRect.implicitWidth + root.horizontalPadding * 16
        : _targetClockWidth + _cavaWidth + root.horizontalPadding * 2.5

    implicitHeight: root.expanded
        ? _clockWrapperTargetHeight + root.verticalPadding * 4
        : _targetClockHeight + root.verticalPadding * 1.5

    readonly property real basePillHeight: _targetClockHeight + verticalPadding * 2

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
            leftMargin: root.horizontalPadding
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

        // CAVA Visualizer (Left of Clock) - grows away from the clock,
        // which itself shifts right only enough to keep the pair balanced
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
                    readonly property real targetHeight: Math.max(3, (modelData / 150) * 20)

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
            dateMetricsHeight: dateMetrics.height
            clockPixelSize: root._targetClockPixelSize
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
            rightMargin: root.horizontalPadding * 3
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
