/* quickshell/shell/widgets/base/OrbitMenu.qml */


pragma ComponentBehavior: Bound

import QtQuick
import ElysianShell.Themes


Item {
    id: root
    anchors.fill: parent
    focus: true

    property bool fetchMousePos:        false
    property real centerX:              0
    property real centerY:              0
    property real bubbleSize:           50
    property real orbitRadius:          bubbleSize * 2
    property real fetchTimeout:         100
    property bool fixedTooltip:         false
    property int activeSet:             0
    property int _pendingSet:           -1
    property list<QtObject> sets:  []

    signal closeRequested()
    signal fullCloseRequested()

    function openMenu(set_index, posX, posY) {
        activeSet = set_index ?? 0

        if (posX !== undefined && posY !== undefined) {
            centerX = posX
            centerY = posY
            fetchMousePos = false
            forceActiveFocus()
            bubbleRepeater.triggerExpand()
        }
        else {
            fetchMousePos = true
            forceActiveFocus()
            fallbackTimer.restart()
        }
    }

    function closeMenu() { bubbleRepeater.triggerCollapse() }

    function switchSet(index) {
        _pendingSet = index
        bubbleRepeater.triggerCollapse()
    }

    function bubbleCenter(localIndex, totalInSet) {
        let angle = (localIndex / totalInSet) * Math.PI * 2 - Math.PI / 2
        return Qt.point(
            root.centerX + Math.cos(angle) * root.orbitRadius,
            root.centerY + Math.sin(angle) * root.orbitRadius
        )
    }

    Keys.onPressed: event => {
        if      (event.key === Qt.Key_Tab && sets.length > 1)   { switchSet((activeSet + 1) % sets.length) }
        else if (event.key === Qt.Key_Escape)                   { root.closeMenu(); fullCloseRequested() }
    }

    /*
        This timer gives the MouseArea <interval> miliseconds to notify the new cursor position.
        No notification would mean MouseArea did not update,
            meaning cursor did not move at all from previous position.
        When this timer finishes, if no update has been received, the menu is opened
            at the last know position (or screen center if never opened before).
    */
    Timer {
        id: fallbackTimer
        interval: root.fetchTimeout
        repeat: false
        onTriggered: {
            if (root.fetchMousePos) {
                if (root.centerX <= 0 || root.centerY <= 0) {
                    root.centerX = root.width / 2
                    root.centerY = root.height / 2
                }
                root.fetchMousePos = false
                bubbleRepeater.triggerExpand()
            }
        }
    }

    Repeater {
        id: bubbleRepeater
        model: (root.sets[root.activeSet]?.entries ?? []).length

        function triggerExpand() {
            for (let i = 0; i < count; i++) {
                const item = itemAt(i) as BubbleItem
                if (item && item.collapsed) item.expandBubble()
            }
        }

        function triggerCollapse() {
            for (let i = 0; i < count; i++) {
                const item = itemAt(i) as BubbleItem
                if (item && !item.collapsed) item.collapseBubble()
            }
        }

        function allCollapsed() {
            for (let i = 0; i < count; i++) {
                const item = itemAt(i) as BubbleItem
                if (item && !item.collapsed) return false
            }
            return true
        }

        function collapseOrSwitch() {
            if (root._pendingSet !== -1) {
                root.activeSet = root._pendingSet
                root._pendingSet = -1
                triggerExpand()
            } else {
                root.closeRequested()
            }
        }

        delegate: BubbleItem {}

    }

    component BubbleItem: Item {
        id: bubbleItem

        required property int index
        
        property int count: bubbleRepeater.count

        readonly property var  activeEntries:   root.sets[root.activeSet]?.entries ?? []
        readonly property var  entry:           activeEntries[index]
        readonly property real sliceAngle:      (2 * Math.PI) / activeEntries.length
        readonly property real targetAngle:     index * sliceAngle - Math.PI / 2
        readonly property real targetX:         root.centerX + Math.cos(targetAngle) * root.orbitRadius
        readonly property real targetY:         root.centerY + Math.sin(targetAngle) * root.orbitRadius
        readonly property bool selected:        entry?.selected ?? false

        property bool hovered:      false
        property bool collapsed:    true

        width:  root.bubbleSize
        height: root.bubbleSize
        x: 0
        y: 0
        opacity: 1

        function expandBubble() {
            if (collapseAnimation.running) return
            bubbleItem.x = root.centerX - root.bubbleSize / 2
            bubbleItem.y = root.centerY - root.bubbleSize / 2
            expandAnimation.start()
        }

        function collapseBubble() {
            if (expandAnimation.running) return
            collapseAnimation.start()
        }

        SequentialAnimation {
            id: expandAnimation
            running: false

            ParallelAnimation {
                NumberAnimation {
                    target:      bubbleItem
                    property:    "scale"
                    from:        0.0
                    to:          1.0
                    duration:    225
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target:             bubbleItem
                    property:           "x"
                    to:                 bubbleItem.targetX - root.bubbleSize / 2
                    duration:           450
                    easing.type:        Easing.OutBack
                    easing.overshoot:   1.5
                }
                NumberAnimation {
                    target:             bubbleItem
                    property:           "y"
                    to:                 bubbleItem.targetY - root.bubbleSize / 2
                    duration:           450
                    easing.type:        Easing.OutBack
                    easing.overshoot:   1.5
                }
            }

            onStopped: bubbleItem.collapsed = false
        }

        SequentialAnimation {
            id: collapseAnimation
            running: false

            ParallelAnimation {
                NumberAnimation {
                    target:             bubbleItem
                    property:           "x"
                    to:                 root.centerX - root.bubbleSize / 2
                    duration:           450
                    easing.type:        Easing.InBack
                    easing.overshoot:   1.5
                }
                NumberAnimation {
                    target:             bubbleItem
                    property:           "y"
                    to:                 root.centerY - root.bubbleSize / 2
                    duration:           450
                    easing.type:        Easing.InBack
                    easing.overshoot:   1.5
                }
                SequentialAnimation {
                    PauseAnimation { duration: 450 / 2 }
                    NumberAnimation {
                        target:      bubbleItem
                        property:    "scale"
                        from:        1.0
                        to:          0.0
                        duration:    450 / 2
                        easing.type: Easing.InCubic
                    }
                }
            }

            onStopped: {
                bubbleItem.collapsed = true
                if (bubbleRepeater.allCollapsed()) bubbleRepeater.collapseOrSwitch()
            }
        }

        // Bubble
        Rectangle {
            anchors.fill: parent
            radius: root.bubbleSize / 2

            color: {
                if (bubbleItem.hovered)   return ActiveTheme.colors["DARK4"]
                if (bubbleItem.selected)  return ActiveTheme.colors["BG_HIGHLIGHT"]
                return ActiveTheme.colors["BG"]
            }

            border.color: {
                if (bubbleItem.selected)  return ActiveTheme.colors["FG_DARK"]
                if (bubbleItem.hovered)   return ActiveTheme.colors["FG"]
                return ActiveTheme.colors["DARK3"]
            }
            border.width: bubbleItem.selected ? 1.5 : 0.5

            Image {
                id: bubbleIcon
                anchors.centerIn: parent
                sourceSize {
                    width:  48
                    height: 48
                }
                width: 32; height: 32
                source: bubbleItem.entry?.icon ?? ""
                fillMode: Image.PreserveAspectFit
                smooth: true
                visible: status === Image.Ready
                opacity: bubbleItem.selected ? 1.0 : 0.75
            }

            Text {
                anchors.centerIn: parent
                text: (bubbleItem.entry?.name ?? "").charAt(0).toUpperCase()
                color: bubbleItem.selected ? ActiveTheme.colors["FG"] : ActiveTheme.colors["DARK3"]
                font.pixelSize: 16
                font.weight: Font.Medium
                visible: bubbleIcon.status !== Image.Ready
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                
                onEntered: bubbleItem.hovered = true
                onExited: bubbleItem.hovered = false

                onClicked: (mouse) => {
                    if (mouse.button == Qt.RightButton) {
                        if (bubbleItem.entry.rightAction)
                            bubbleItem.entry.rightAction(bubbleItem.index, root.sets[root.activeSet].entries.length)
                        else console.log("Right click!")
                    }
                    else {
                        bubbleItem.entry.leftAction()
                        if (!bubbleItem.entry.stateful) root.fullCloseRequested()
                    }
                }
            }
        }

        // Tooltip
        Tooltip {
            readonly property real gap: 10

            title: bubbleItem.entry?.name ?? ""
            comment: bubbleItem.entry?.comment ?? ""
            selected: bubbleItem.selected

            x: Math.cos(bubbleItem.targetAngle) * (root.bubbleSize / 2 + width / 2 + gap) + root.bubbleSize / 2 - width / 2
            y: Math.sin(bubbleItem.targetAngle) * (root.bubbleSize / 2 + height / 2 + gap) + root.bubbleSize / 2 - height / 2
            z: root.z + 1
            visible: (root.fixedTooltip || bubbleItem.hovered) &&
                        !expandAnimation.running && !collapseAnimation.running &&
                        ((bubbleItem.entry?.name ?? "") !== "" || (bubbleItem.entry?.comment ?? "") !== "")
        }
    }

    // This MouseArea covers the whole screen. Only used to capture mouse position (x, Y) on screen
    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        propagateComposedEvents: true
        z: -1
        enabled: root.activeFocus

        onPositionChanged: mouse => {
            if (root.fetchMousePos) {
                root.centerX = mouse.x
                root.centerY = mouse.y
                root.fetchMousePos = false
                bubbleRepeater.triggerExpand()
            }
        }

        // Close menu if clicking outside of any bubble
        onClicked: { root.closeMenu() }
    }
}
