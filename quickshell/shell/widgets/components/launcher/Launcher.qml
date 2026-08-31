/* quickshell/shell/widgets/components/launcher/Launcher.qml */


pragma ComponentBehavior: Bound

import QtQml
import QtQuick
import QtQuick.Layouts
import ElysianShell.Themes

Rectangle {
    id: root

    // ── Public API — inputs ──────────────────────────────────────────
    property var    entries:      []
    property var    launchModes:  []
    property string actionPrefix: "/"

    // ── Public API — outputs (read-only, exposed for convenience) ─────
    readonly property var filteredEntries: _filteredEntries
    readonly property int currentIndex:    _currentIndex
    readonly property var activeMode: {
        const text   = searchInput.text
        const prefix = root.actionPrefix
        if (!text.startsWith(prefix)) return null
        const rest = text.slice(prefix.length)
        return root.launchModes.find(
            m => rest === m.prefix + " " || rest.startsWith(m.prefix + " ")) ?? null
    }
    readonly property bool wrapNavigation: root.activeMode?.displayMode === "carousel"

    // ── Signals ───────────────────────────────────────────────────────
    signal closeRequested()
    signal activated(var entry)

    // ── Internal state ───────────────────────────────────────────────
    property var _filteredEntries: []
    property int _currentIndex:    0

    property int padding: 20

    implicitWidth:  launcher.implicitWidth  + padding * 2
    implicitHeight: launcher.implicitHeight + padding * 2

    color: "transparent"

    // ── Public functions ───────────────────────────────────────────────
    function forceInputFocus() {
        searchInput.forceActiveFocus()
        root._currentIndex = 0
    }
    function clearInput() { searchInput.text = "" }
    function refresh()    { filterDebounce.restart() }

    // ── Filtering ─────────────────────────────────────────────────────
    Timer {
        id: filterDebounce
        interval: 50
        repeat: false
        onTriggered: root._filteredEntries = root._computeFilteredEntries()
    }

    Instantiator {
        model: root.launchModes
        delegate: Connections {
            required property var modelData
            target: modelData
            function onEntriesChanged() { root.refresh() }
        }
    }

    function _normalizeEntry(e) {
        return e.id !== undefined ? e : Object.assign({}, e, { id: e.name })
    }

    function _computeFilteredEntries() {
        const text   = searchInput.text
        const prefix = root.actionPrefix
        let result = []

        if (text.startsWith(prefix)) {
            const rest = text.slice(prefix.length).toLowerCase()
            const matchedMode = root.launchModes.find(
                m => rest === "" || m.prefix.startsWith(rest) || rest.startsWith(m.prefix + " "))

            const modePrefix = matchedMode ? prefix + matchedMode.prefix + " " : null

            if (matchedMode && text.startsWith(modePrefix)) {
                const q = text.slice(modePrefix.length).toLowerCase()
                const modeEntries = typeof matchedMode.entries === "function"
                    ? matchedMode.entries() : matchedMode.entries
                result = q
                    ? modeEntries.filter(e =>
                        e.name.toLowerCase().includes(q) ||
                        (e.comment ?? "").toLowerCase().includes(q))
                    : modeEntries
            } else {
                result = root.launchModes
                    .filter(m => rest === "" || m.prefix.startsWith(rest) || m.label.toLowerCase().startsWith(rest))
                    .map(m => ({
                        id:           "mode:" + m.prefix,
                        name:         m.label,
                        icon:         m.icon,
                        comment:      "Type " + prefix + m.prefix + " to browse",
                        isModeEntry:  true,
                        fallbackText: root.actionPrefix,
                        modePrefix:   prefix + m.prefix + " ",
                        stayOpen:     true,
                        action:       () => { searchInput.text = prefix + m.prefix + " " }
                    }))
            }
        } else {
            const q = text.toLowerCase()
            result = q
                ? root.entries.filter(e =>
                    e.name.toLowerCase().includes(q) ||
                    (e.comment ?? "").toLowerCase().includes(q))
                : root.entries
        }

        return result.map(root._normalizeEntry)
    }

    // ── Navigation ────────────────────────────────────────────────────
    function _navigatePrev() {
        const count = root._filteredEntries.length
        if (count === 0) return
        const next = root.wrapNavigation
            ? (root._currentIndex - 1 + count) % count
            : Math.max(0, root._currentIndex - 1)
        root._currentIndex = next
        entryView.positionAt(next)
    }
    function _navigateNext() {
        const count = root._filteredEntries.length
        if (count === 0) return
        const next = root.wrapNavigation
            ? (root._currentIndex + 1) % count
            : Math.min(count - 1, root._currentIndex + 1)
        root._currentIndex = next
        entryView.positionAt(next)
    }
    function _activateCurrent() {
        const entry = root._filteredEntries[root._currentIndex]
        if (!entry) return
        root.activated(entry)
        if (!(entry.stayOpen ?? false)) root.closeRequested()
    }

    onEntriesChanged: refresh()
    onActivated:      (entry) => entry.action()
    Component.onCompleted: _filteredEntries = _computeFilteredEntries()

    // Shared key handling — both inputs forward here so Return/Up/Down/Escape
    // behave identically regardless of which one currently has focus.
    Item {
        id: keyHandler
        Keys.onReturnPressed: root._activateCurrent()
        Keys.onEscapePressed: root.closeRequested()
        Keys.onUpPressed:     root._navigatePrev()
        Keys.onDownPressed:   root._navigateNext()
        Keys.onLeftPressed:   root._navigatePrev()
        Keys.onRightPressed:  root._navigateNext()
    }

    Rectangle {
        id: launcher

        implicitWidth:  contentColumn.implicitWidth
        implicitHeight: contentColumn.implicitHeight

        color: "transparent"
        clip: true

        anchors.centerIn: parent

        // ── Layout ────────────────────────────────────────────────────────
        ColumnLayout {
            id: contentColumn
            spacing: 20

            // ── Search input row ─────────────────────────────────────────
            Rectangle {
                id: searchBarRect
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                color: ActiveTheme.colors["BG_STRIPE"]
                radius: 12

                Row {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 6
                    visible: root.activeMode !== null

                    Rectangle {
                        visible: root.activeMode !== null
                        height: 26
                        width: chipLabel.implicitWidth + 16
                        radius: 6
                        color: ActiveTheme.colors["ACCENT_DIM"]
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            id: chipLabel
                            anchors.centerIn: parent
                            text: root.activeMode?.label ?? ""
                            color: ActiveTheme.colors["FG"]
                            font.pixelSize: 12
                            font.weight: Font.Medium
                        }
                    }

                    TextInput {
                        id: modeInput
                        width: parent.width - chipLabel.implicitWidth - 32
                        anchors.verticalCenter: parent.verticalCenter
                        color: ActiveTheme.colors["FG"]
                        font.pixelSize: 16
                        focus: root.activeMode !== null

                        property string modePrefixText: root.activeMode
                            ? (root.actionPrefix + root.activeMode.prefix + " ")
                            : ""

                        onModePrefixTextChanged: {
                            if (root.activeMode !== null) {
                                const full = searchInput.text
                                text = full.startsWith(modePrefixText) ? full.slice(modePrefixText.length) : ""
                                forceActiveFocus()
                            }
                        }
                        onTextChanged: {
                            if (root.activeMode !== null)
                                searchInput.text = modePrefixText + text
                        }

                        Keys.priority: Keys.BeforeItem
                        Keys.forwardTo: [keyHandler]
                        Keys.onPressed: function(event) {
                            if (event.key === Qt.Key_Backspace && text === "") {
                                searchInput.text = root.actionPrefix
                                event.accepted = true
                            }
                        }

                        Text {
                            visible: modeInput.text === ""
                            text: root.activeMode?.placeholder
                                ?? ("Search " + (root.activeMode?.label ?? "") + "...")
                            color: ActiveTheme.colors["DARK3"]
                            font.pixelSize: 16
                            font.italic: true
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }
                }

                TextInput {
                    id: searchInput
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: 16
                    visible: root.activeMode === null
                    focus:   root.activeMode === null
                    color: searchInput.text.startsWith(root.actionPrefix)
                            ? ActiveTheme.colors["ACCENT_DIM"] : ActiveTheme.colors["FG"]
                    font.pixelSize: 16

                    onTextChanged: {
                        root._currentIndex = 0
                        filterDebounce.restart()
                        if (root.activeMode !== null)
                            modeInput.forceActiveFocus()
                    }

                    Keys.priority: Keys.BeforeItem
                    Keys.forwardTo: [keyHandler]
                    Keys.onTabPressed: {
                        if (root._filteredEntries.length > 0) {
                            const entry = root._filteredEntries[root._currentIndex]
                            if (entry.isModeEntry) searchInput.text = entry.modePrefix
                        }
                    }
                    Keys.onPressed: function(event) {
                        if (event.key === Qt.Key_Backspace && text === root.actionPrefix) {
                            searchInput.text = ""
                            event.accepted = true
                        }
                    }
                }

                Text {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.margins: 16
                    visible: searchInput.text === "" && root.activeMode === null
                    text: "Search apps  ·  type " + root.actionPrefix + " for commands"
                    color: ActiveTheme.colors["DARK3"]
                    font.pixelSize: 15
                    font.italic: true
                }
            }

            // ── Results ──────────────────────────────────────────────────
            EntryView {
                id: entryView
                Layout.alignment: Qt.AlignHCenter
                model:        root._filteredEntries
                currentIndex: root._currentIndex
                displayMode:  root.activeMode?.displayMode ?? "items"
                onActivated:      (entry) => root.activated(entry)
                onCloseRequested: root.closeRequested()
            }
        }
    }
}
