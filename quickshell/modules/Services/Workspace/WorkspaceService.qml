/* quickshell/modules/Services/Workspace/WorkspaceService.qml */


pragma Singleton

import Quickshell
import Quickshell.Hyprland
import ElysianShell.Themes
import QtQuick

Singleton {
    id: root

    readonly property int count: 10
    readonly property int minIndicators: 5

    // Fired only on genuine, user-requested workspace switches
    signal switched()

    // One entry per possible workspace slot — everything ControlPill
    // needs to render, with no Hyprland types leaking out.
    property var states: []

    function _rebuild() {
        const focusedId = Hyprland.focusedWorkspace?.id ?? 0
        const list = []

        for (let i = 0; i < root.count; i++) {
            const wsId = i + 1
            let hyprWs = null
            for (let j = 0; j < Hyprland.workspaces.values.length; j++) {
                if (Hyprland.workspaces.values[j].id === wsId) {
                    hyprWs = Hyprland.workspaces.values[j]
                    break
                }
            }

            list.push({
                id:      wsId,
                active:  hyprWs?.focused ?? false,
                exists:  hyprWs !== null,
                visible: wsId <= focusedId || i < root.minIndicators
            })
        }

        root.states = list
    }

    // Pure function, called from a QML binding — property reads inside
    // (ActiveTheme.colors[...]) are still tracked, so bindings that call
    // this stay reactive to theme changes even though `states` itself
    // is a plain pre-computed array.
    function colorFor(active, exists) {
        return active ? ActiveTheme.colors["SECONDARY"]
             : exists ? ActiveTheme.colors["WARNING"]
             :          ActiveTheme.colors["FG_HINT"]
    }

    function activate(workspaceId) {
        let hyprWs = null
        for (let j = 0; j < Hyprland.workspaces.values.length; j++) {
            if (Hyprland.workspaces.values[j].id === workspaceId) {
                hyprWs = Hyprland.workspaces.values[j]
                break
            }
        }
        if (hyprWs) hyprWs.activate()
        else Hyprland.dispatch("hl.dsp.focus({ workspace = " + workspaceId + " })")
    }

    Connections {
        target: Hyprland.workspaces
        function onValuesChanged() { root._rebuild() }
    }

    Connections {
        target: Hyprland

        function onFocusedWorkspaceChanged() { root._rebuild() }

        function onRawEvent(event) {
            if (event.name === "workspacev2") root.switched()
        }
    }

    Component.onCompleted: _rebuild()
}
