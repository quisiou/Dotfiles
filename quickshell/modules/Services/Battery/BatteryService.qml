/* quickshell/modules/Services/Battery/BatteryService.qml */


pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower

Singleton {
    id: root

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

    readonly property var battery: {
        const list = UPower.devices.values
        for (let i = 0; i < list.length; i++)
            if (list[i].isLaptopBattery) return list[i]
        return null
    }
    readonly property bool hasBattery: battery !== null

    // ── Live ─────────────────────────────────────────
    readonly property int chargePercent: Math.round(device.percentage * 100)

    readonly property string shortState: {
        switch (device.state) {
            case UPowerDeviceState.Charging:         return "Charging"
            case UPowerDeviceState.Discharging:      return "On battery"
            case UPowerDeviceState.FullyCharged:     return "Full"
            case UPowerDeviceState.PendingCharge:    return "Plugged in"
            case UPowerDeviceState.Empty:            return "Empty"
            default:                                 return ""
        }
    }

    // ── Static-ish: health, capacity, identity ───────
    readonly property bool healthKnown:
        battery !== null && battery.healthSupported && battery.healthPercentage > 0
    readonly property real healthRaw: healthKnown ? battery.healthPercentage : 0
    readonly property int healthPercent: Math.min(100, Math.round(healthRaw))

    // energyCapacity is today's full capacity, so design = full / health
    readonly property real designWh:
        healthKnown && healthRaw > 0 ? battery.energyCapacity * 100 / healthRaw : 0

    property string manufacturer: ""
    property int cycles: 0

    readonly property string name:
        [manufacturer, battery?.model ?? ""].filter(x => x !== "" && x !== "Unknown").join(" ")
    readonly property string detail: [
        designWh > 0 ? designWh.toFixed(1) + " Wh" : "",
        cycles > 0 ? cycles + " cycles" : ""
    ].filter(x => x !== "").join(" · ")

    function _mfr(s) {
        const m = { SMP: "Simplo", LGC: "LG Chem", SDI: "Samsung SDI", ATL: "ATL", BYD: "BYD" }
        return m[s.toUpperCase()] ?? s
    }

    // Manufacturer and cycle count are not exposed by UPower, read them from sysfs once
    Process {
        command: ["sh", "-c", `
            b=$(ls -d /sys/class/power_supply/BAT* 2>/dev/null | head -1)
            [ -n "$b" ] || exit 0
            echo "mfr=$(cat $b/manufacturer 2>/dev/null)"
            echo "cycles=$(cat $b/cycle_count 2>/dev/null)"
        `]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const v = {}
                for (const line of text.split("\n")) {
                    const i = line.indexOf("=")
                    if (i > 0) v[line.slice(0, i)] = line.slice(i + 1).trim()
                }
                root.manufacturer = root._mfr(v.mfr ?? "")
                root.cycles = parseInt(v.cycles) || 0
            }
        }
    }
}
