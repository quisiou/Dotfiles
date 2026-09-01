/* quickshell/modules/Services/Battery/BatteryService.qml */


pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.UPower

Singleton {
    readonly property var device: UPower.displayDevice
    readonly property real percentage: device.percentage
    readonly property string statusText: {
        switch (device.state) {
            case UPowerDeviceState.Charging:            return "Charging"
            case UPowerDeviceState.Discharging:         return "Discharging"
            case UPowerDeviceState.Empty:               return "Empty"
            case UPowerDeviceState.FullyCharged:        return "Fully charged"
            case UPowerDeviceState.PendingCharge:       return "Not drawing power"
            case UPowerDeviceState.PendingDischarge:    return "Pending discharge"
            default:                                    return "Unknown"
        }
    }
}
