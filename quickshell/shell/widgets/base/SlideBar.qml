/* quickshell/shell/widgets/base/SlideBar.qml */


import QtQuick
import ElysianShell.Themes

Item {
    id: root
    property real value: 0.5
    property real minValue: 0
    property real maxValue: 1
    property bool liveUpdate: true

    readonly property real progress: {
        let range = maxValue - minValue
        if (range <= 0) return 0
        let norm = (value - minValue) / range
        return Math.max(0, Math.min(1, norm))
    }

    property bool pressed: mouseArea.pressed
    property bool growHorizontal: true

    readonly property int _animDuration: 100
    readonly property var _easingType: Easing.Linear

    signal setValue(real newValue)

    width: 200
    height: 6

    // background track
    Rectangle {
        id: track
        anchors.fill: parent
        radius: width > height ? height / 2 : width / 2
        color: ActiveTheme.colors["DARK7"]
    }

    // progressive fill
    Rectangle {
        id: fill

        anchors.left: parent.left
        anchors.right: root.growHorizontal ? undefined : parent.right
        anchors.top:   root.growHorizontal ? parent.top : undefined
        anchors.bottom: parent.bottom

        radius: width > height ? height / 2 : width / 2
        width:  root.growHorizontal ? track.width * root.progress : parent.width
        height: root.growHorizontal ? parent.height : track.height * root.progress
        color: ActiveTheme.colors["FG"]

        Behavior on width {
            enabled: root.growHorizontal && !mouseArea.pressed
            NumberAnimation { duration: root._animDuration; easing.type: root._easingType }
        }
        Behavior on height {
            enabled: !root.growHorizontal && !mouseArea.pressed
            NumberAnimation { duration: root._animDuration; easing.type: root._easingType }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        cursorShape: root.growHorizontal ? Qt.SizeHorCursor : Qt.SizeVerCursor
        preventStealing: true

        function fractionFor(mouse) {
            let fraction = root.growHorizontal
                ? mouse.x / root.width
                : 1 - (mouse.y / root.height)
            return Math.max(0, Math.min(1, fraction))
        }

        function valueFor(mouse) {
            const fraction = fractionFor(mouse)
            return root.minValue + fraction * (root.maxValue - root.minValue)
        }

        function updateValue(mouse) {
            const v = valueFor(mouse)
            root.value = v
            if (root.liveUpdate) root.setValue(v)
        }

        onPressed: (mouse) => updateValue(mouse)
        onPositionChanged: (mouse) => { if (pressed) updateValue(mouse) }
        onReleased: (mouse) => {
            const v = valueFor(mouse)
            root.value = v
            root.setValue(v)
        }
        onWheel: (wheel) => {
            let step = (root.maxValue - root.minValue) * 0.02
            let delta = wheel.angleDelta.y > 0 ? step : -step
            let newValue = Math.max(root.minValue, Math.min(root.maxValue, root.value + delta))
            root.value = newValue
            root.setValue(newValue)
        }
    }
}
