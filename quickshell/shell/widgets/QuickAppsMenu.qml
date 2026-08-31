/* quickshell/shell/widgets/QuickAppsMenu.qml */


import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "base"

// qmllint disable uncreatable-type
PanelWindow {
// qmllint enable uncreatable-type
    id: root
    color: "transparent"
    visible: false
    focusable: true

    property var _sets: []

    anchors {
        top: true;
        bottom: true;
        left: true;
        right: true
    }

    signal menuClosed()

    function openMenu(set_index, posX, posY) {
        if (visible) return
        visible = true
        orbitMenu.openMenu(set_index ?? 0, posX, posY)
    }

    function closeMenu() {
        if (!visible) return
        orbitMenu.closeMenu()
    }

    FileView {
        id: appsFile
        path: Quickshell.shellDir + "/quickapps.json"
        watchChanges: true
        onFileChanged: reload()
        onTextChanged: root.rebuildSets()
    }

    function appIds() {
        var text = appsFile.text()
        if (text === "") return []
        try {
            var data = JSON.parse(text)
            return Array.isArray(data) ? data : []
        } catch (e) {
            console.warn("quickapps.json: parse failed", e)
            return []
        }
    }

    function makeEntry(app) {
        var obj = Qt.createQmlObject(`import QtQuick; QtObject {
            property string name
            property string id
            property string icon
            property string comment
            property bool   selected
            property bool   stateful
            property var leftAction
        }`, root)
        obj.name    = app.name
        obj.id      = app.id ?? ""
        obj.icon    = app.icon ? "image://icon/" + app.icon : ""
        obj.comment = app.comment ?? ""
        obj.selected = app.selected ?? true
        obj.stateful = app.stateful ?? false
        obj.leftAction = (function(a) { return () => a.execute() })(app)
        return obj
    }

    function rebuildSets() {
        var ids = appIds()
        var entries = DesktopEntries.applications.values
            .filter(app => !app.noDisplay)
            .filter(app => ids.includes(app.id))
            .map(app => makeEntry(app))
            .sort((a, b) => ids.indexOf(a.id) - ids.indexOf(b.id))

        if (entries.length === 0) {
            root._sets = []
            return
        }

        var sets = []
        for (var i = 0; i < entries.length; i += 8) {
            var setObj = Qt.createQmlObject('import QtQuick; QtObject { property var entries: [] }', root)
            setObj.entries = entries.slice(i, i + 8)
            sets.push(setObj)
        }

        root._sets = sets
    }

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "quick-apps-menu"
    exclusionMode: ExclusionMode.Ignore

    // ── Hooks ─────────────────────────────────────────────────────────────────
    Connections {
        target: DesktopEntries
        function onApplicationsChanged() { root.rebuildSets() }
    }

    // ── Menu ───────────────────────────────────────────────────────────────
    OrbitMenu {
        id: orbitMenu
        onCloseRequested: {
            root.visible = false
            root.menuClosed()
        }
        onFullCloseRequested: orbitMenu.closeMenu()
        z: 200
        sets: root._sets
    }
}
