/* quickshell/shell/widgets/components/default/DefaultMenu.qml */


import QtQuick
import ElysianShell.Themes
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

    // Fixed-width sample since the clock format is "hh:mm" -> consistent digit count
    readonly property real _targetClockWidth:  clockMetrics.boundingRect("00:00").width
    readonly property real _targetClockHeight: clockMetrics.boundingRect("00:00").height
    readonly property real _dateHeight: dateMetrics.height

    readonly property real _clockWrapperTargetHeight:
        _targetClockHeight + (root.expanded ? (2 + _dateHeight) : 0)   // 2 = Column spacing

    implicitWidth: root.expanded
        ? mediaRect.implicitWidth + _targetClockWidth + systemRect.implicitWidth + root.horizontalPadding * 16
        : _targetClockWidth + root.horizontalPadding * 3

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

        ClockModule {
            id: clockColumn
            expanded: root.expanded
            clockPixelSize: root._targetClockPixelSize
            anchors.centerIn: parent
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
