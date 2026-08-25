/* quickshell/shell/widgets/components/launcher/modes/BluetoothMode.qml */


import QtQuick
import Quickshell
import ElysianShell.Services

Item {
    id: root

    // ── Public API — mode descriptor (duck-typed, consumed by Launcher) ────
    readonly property string prefix:      "bluetooth"
    readonly property string label:       "Bluetooth"
    readonly property string placeholder: "Select device to toggle connection"
    readonly property string icon:        Quickshell.shellDir + "/assets/icons/bluetooth-active.svg"
    readonly property string displayMode: "items"

    // ── Public API — reactive entries ───────────────────────────────────────
    // Plain property (not a function): Launcher's Instantiator listens for
    // entriesChanged and calls refresh() automatically, so nothing external
    // needs to know when Bluetooth state changes.
    property var entries: []

    function _rebuild() {
        entries = BluetoothDeviceModel.deviceList().map(dev => ({
            id:       "bt:" + dev.path,
            name:     dev.alias || dev.name,
            icon:     dev.icon ? "image://icon/" + dev.icon : "",
            comment:  dev.address + " · " + (dev.connected ? "Connected ✓" : "Disconnected"),
            stayOpen: true,
            action:   (function(p) {
                return () => BluetoothDeviceModel.toggle(p)
            })(dev.path)
        }))
    }

    Connections {
        target: BluetoothDeviceModel
        function onDataChanged() { root._rebuild() }
        function onModelReset()  { root._rebuild() }
    }

    Component.onCompleted: _rebuild()
}
