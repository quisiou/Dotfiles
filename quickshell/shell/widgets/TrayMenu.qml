/* quickshell/shell/widgets/TrayMenu.qml */


pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Services.SystemTray
import "base"

// qmllint disable uncreatable-type
PanelWindow {
// qmllint enable uncreatable-type
    id: root
    color: "transparent"
    visible: false
    focusable: true

    anchors {
        top: true;
        bottom: true;
        left: true;
        right: true
    }

    property bool pendingOpen: false
    property int  pendingSet:  0

    signal menuClosed()

    function openMenu(set_index, posX, posY) {
        if (visible) return
        rebuildEntries()
        if (trayMenu.sets.length === 0) {
            pendingOpen = true
            pendingSet  = set_index ?? 0
            pendingOpenTimeout.restart()
            return
        }
        visible = true
        trayMenu.openMenu(set_index ?? 0, posX, posY)
    }

    function closeMenu() {
        if (!visible) return
        // optionMenu.closeMenu()          // Close option menu (if open)
        trayMenu.fullCloseRequested() // Makes it so the option menu closes tray menu too
    }

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "tray-menu"
    exclusionMode: ExclusionMode.Ignore

    Timer {
        id: pendingOpenTimeout
        interval: 500
        repeat: false
        onTriggered: root.pendingOpen = false
    }

    Timer {
        id: rebuildDebounce
        interval: 50
        repeat: false
        onTriggered: {
            let wasOpen = root.visible
            let currentSet = trayMenu.activeSet

            if (wasOpen) root.visible = false  // bypass animation

            root.rebuildEntries()

            if (root.pendingOpen && trayMenu.sets.length > 0) {
                root.pendingOpen = false
                root.visible = true
                trayMenu.openMenu(root.pendingSet)
            }
            else if (wasOpen && trayMenu.sets.length > 0) {
                let safeSet = Math.min(currentSet, trayMenu.sets.length - 1)
                root.visible = true
                trayMenu.openMenu(safeSet, trayMenu.centerX, trayMenu.centerY)
            }
        }
    }

    QsMenuOpener {
        id: menuOpener
        menu: null  // set dynamically on right click

        property real pendingX: 0
        property real pendingY: 0

        onChildrenChanged: {
            if (menu === null) return
            if (children.values.length === 0) return
            root.buildOptionSets(children)
            optionMenu.openMenu(0, pendingX, pendingY)
        }
    }

    OrbitMenu {
        id: optionMenu

        fixedTooltip: true
        bubbleSize: 35
        z: 200
        sets: []

        property bool fullClose: false

        onCloseRequested: {
            optionMenu.sets = []
            menuOpener.menu = null
            if (fullClose) {
                fullClose = false
                trayMenu.closeMenu()
            } else {
                trayMenu.forceActiveFocus()
            }
        }

        onFullCloseRequested: {
            fullClose = true
            optionMenu.closeMenu()
        }
    }

    function buildOptionSets(entries) {
        let values = entries.values
        let allEntries = []
        for (let i = 0; i < values.length; i++) {
            let e = values[i]
            if (e.isSeparator) continue
            allEntries.push(Qt.createQmlObject(`
                import QtQuick
                QtObject {
                    property string name:     ""
                    property string comment:  ""
                    property string icon:     ""
                    property bool   selected: false
                    property bool   stateful: false
                    property var    leftAction:  null
                    property var    rightAction: null
                }
            `, root))
            let obj = allEntries[allEntries.length - 1]
            obj.name       = e.text
            obj.icon       = e.icon
            obj.leftAction = function() { e.triggered() }
            obj.rightAction = e.hasChildren ? function() { /* nested, later */ } : null
        }

        let newSets = []
        for (let i = 0; i < allEntries.length; i += 8) {
            let set = Qt.createQmlObject('import QtQuick; QtObject { property list<QtObject> entries: [] }', root)
            set.entries = allEntries.slice(i, i + 8)
            newSets.push(set)
        }
        optionMenu.sets = newSets
    }

    Instantiator {
        id: instantiator
        model: SystemTray.items
        delegate: QtObject {
            required property var   modelData
            property string         name:        modelData.tooltipTitle || modelData.id
            property string         comment:     modelData.tooltipDescription
            property string         icon:        modelData.icon
            property bool           selected:    true
            property bool           stateful:    false
            property var            leftAction:  function() { if (!modelData.onlyMenu) modelData.activate() }
            property var            rightAction: function(index, total) {
                if (!modelData.hasMenu) return
                let pos = trayMenu.bubbleCenter(index, total)
                menuOpener.pendingX = pos.x
                menuOpener.pendingY = pos.y
                menuOpener.menu = modelData.menu
            }
        }
        onObjectRemoved:    (index, obj) => rebuildDebounce.restart()
        onObjectAdded:      (index, obj) => rebuildDebounce.restart()
    }

    function rebuildEntries() {
        let allEntries = []
        for (let i = 0; i < instantiator.count; i++)
            allEntries.push(instantiator.objectAt(i))
        if (allEntries.length === 0) {
            root.closeMenu()
            return
        }

        let newSets = []
        for (let i = 0; i < allEntries.length; i += 8) {
            let chunk = allEntries.slice(i, i + 8)
            let set = Qt.createQmlObject('import QtQuick; QtObject { property list<QtObject> entries: [] }', root)
            set.entries = chunk
            newSets.push(set)
        }
        trayMenu.sets = newSets
    }

    // ── Menu ───────────────────────────────────────────────────────────────
    OrbitMenu {
        id: trayMenu
        z: 200
        onCloseRequested: {
            root.visible = false
            root.menuClosed()
        }

        onFullCloseRequested: {
            if (optionMenu.sets.length > 0) optionMenu.fullCloseRequested()
            else trayMenu.closeMenu()
        }

        // ── Entry sets ────────────────────────────────────────────────────────────
        sets: []
    }
}
