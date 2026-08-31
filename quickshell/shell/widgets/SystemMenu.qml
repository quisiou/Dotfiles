/* quickshell/shell/widgets/SystemMenu.qml */


import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Bluetooth
import ElysianShell.Services
import "base"

PanelWindow {
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

    signal menuClosed()
    signal lockRequested()

    function openMenu(set_index, posX, posY) {
        if (visible) return
        visible = true
        orbitMenu.openMenu(set_index ?? 0, posX, posY)
    }

    function closeMenu() {
        if (!visible) return
        orbitMenu.closeMenu()
    }

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "system-menu"
    exclusionMode: ExclusionMode.Ignore

    // ── Menu ───────────────────────────────────────────────────────────────
    OrbitMenu {
        id: orbitMenu
        onCloseRequested: {
            root.visible = false
            root.menuClosed()
        }
        onFullCloseRequested: orbitMenu.closeMenu()
        z: 200

        property var bthAdapters: Bluetooth.adapters.values

        // ── Entries ────────────────────────────────────────────────────────────
        sets: [
            QtObject {
                property list<QtObject> entries: [

                    // Sound
                    QtObject {
                        readonly property bool  muted:  VolumeService.muted
                        readonly property real  volume: VolumeService.volume
                        readonly property int   pct:    Math.round(volume * 100)

                        property string name:     "Sound"
                        property string icon:     muted                 ?   Qt.resolvedUrl("../assets/icons/audio-volume-muted.svg")
                                : pct === 0             ?   Qt.resolvedUrl("../assets/icons/audio-volume-low.svg")
                                : pct < 60              ?   Qt.resolvedUrl("../assets/icons/audio-volume-medium.svg")
                                :                           Qt.resolvedUrl("../assets/icons/audio-volume-high.svg")
                        property string comment:  muted ? "Muted" : pct + "%"
                        property bool selected: !muted
                        property bool stateful: true
                        property var leftAction:   function() { VolumeService.toggleMute() }
                    },

                    // Bluetooth
                    QtObject {
                        readonly property var adapter: orbitMenu.bthAdapters[0] ?? null

                        property string name:     "Bluetooth"
                        property string icon:     !(adapter?.enabled ?? false) ? Qt.resolvedUrl("../assets/icons/bluetooth-disabled.svg")
                            : BluetoothDeviceModel.connectedNames.length > 0 ? Qt.resolvedUrl("../assets/icons/bluetooth-paired.svg")
                            : Qt.resolvedUrl("../assets/icons/bluetooth-active.svg")
                        property string comment:  !(adapter?.enabled ?? false)                  ? "Off"
                            : BluetoothDeviceModel.connectedNames.length > 0    ? BluetoothDeviceModel.connectedNames.join("\n")
                            : "On"
                        property bool selected: adapter?.enabled ?? false
                        property bool stateful: true
                        property var leftAction:   function() {
                            if (adapter) adapter.enabled = !adapter.enabled
                        }
                    },

                    // Airplane Mode
                    QtObject {
                        property bool prev_network: true
                        property bool prev_bluetooth: true

                        property string name:     "Airplane Mode"
                        property string icon: !selected ?   Qt.resolvedUrl("../assets/icons/airplane-mode-disabled.svg")
                            :               Qt.resolvedUrl("../assets/icons/airplane-mode-active.svg")

                        property string comment:  selected ? "On" : "Off"
                        property bool selected: false
                        property bool stateful: true
                        property var leftAction:   function() {
                            if (!selected) {
                                prev_network      = NetworkService.enabled
                                prev_bluetooth = orbitMenu.bthAdapters[0]?.enabled ?? false

                                NetworkService.enabled = false
                                if (orbitMenu.bthAdapters[0])
                                    orbitMenu.bthAdapters[0].enabled = false

                                selected = true
                            }
                            else {
                                NetworkService.enabled = prev_network
                                if (orbitMenu.bthAdapters[0])
                                    orbitMenu.bthAdapters[0].enabled = prev_bluetooth

                                selected = false
                            }
                        }
                    },

                    // Network
                    QtObject {
                        property string name:     "Network"
                        property string icon: NetworkService.connectionType === "ethernet" ?   Qt.resolvedUrl("../assets/icons/network-wired.svg")
                            : !NetworkService.enabled       ?   Qt.resolvedUrl("../assets/icons/network-wireless-offline.svg")
                            : NetworkService.strength === 0 ?   Qt.resolvedUrl("../assets/icons/network-wireless-acquiring.svg")
                            : NetworkService.strength >= 80 ?   Qt.resolvedUrl("../assets/icons/network-wireless-80.svg")
                            : NetworkService.strength >= 60 ?   Qt.resolvedUrl("../assets/icons/network-wireless-60.svg")
                            : NetworkService.strength >= 40 ?   Qt.resolvedUrl("../assets/icons/network-wireless-40.svg")
                            :                                   Qt.resolvedUrl("../assets/icons/network-wireless-20.svg")

                        property string comment:  NetworkService.connectionType === "ethernet" ?   "Wired"
                            : NetworkService.enabled            ?   NetworkService.ssid
                            :                                       "Off"
                        property bool selected: NetworkService.connectionType !== "none"
                        property bool stateful: true
                        property var leftAction:   function() {
                        if (NetworkService.connectionType !== "ethernet")
                            NetworkService.enabled = !NetworkService.enabled
                        }
                    },

                    // Notifications
                    QtObject {
                        property string name:       "Notifications"
                        property string icon:       (NotificationService.showNotifications)
                                        ? Qt.resolvedUrl("../assets/icons/notification-active.svg")
                                        : Qt.resolvedUrl("../assets/icons/notification-disabled.svg")
                        property string comment:  (NotificationService.showNotifications) ? "On" : "Off"
                        property bool selected: NotificationService.showNotifications
                        property bool stateful: true
                        property var leftAction:   function() {
                            NotificationService.showNotifications = !NotificationService.showNotifications
                        }
                    }
                ]
            }
        ]
    }
}
