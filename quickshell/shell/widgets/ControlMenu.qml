/* quickshell/shell/widgets/ControlMenu.qml */


import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.UPower 
import Quickshell.Services.Polkit
import QtQuick
import ElysianShell.Services
import ElysianShell.Themes
import "base"
import "components/auth"
import "components/lock"
import "components/launcher"
import "components/launcher/modes"
import "components/session"
import "components/workspace"

PanelWindow {
    id: panwin
    readonly property int topbarHeight: 40

    implicitWidth: screen.width
    implicitHeight: screen.height
    exclusionMode: ExclusionMode.Normal
    exclusiveZone: topbarHeight - 15

    WlrLayershell.layer: root.pillWidget !== "default" ? WlrLayer.Overlay : WlrLayer.Top
    WlrLayershell.keyboardFocus: root.pillWidget === "launcher"
        || root.pillWidget === "session"
        || root.pillWidget === "lock"
        || root.pillWidget === "auth"
            ? WlrKeyboardFocus.Exclusive
            : WlrKeyboardFocus.None
    WlrLayershell.namespace: "top-bar"

    mask: Region { item: root }

    anchors { top: true; right: true; left: true }
    color: "transparent"
    
    focusable: true

    // ── Content ───────────────────────────────────────────────────────────────
    MorphingContainer {
        id: root

        readonly property int _defaultClockPixelSize: 16

        Item {
            id: defaultMenu
            anchors.fill: parent

            property real horizontalPadding: 20
            property real verticalPadding: 4
            
            implicitWidth:  (clock.implicitWidth  + horizontalPadding * 2) * (root.defaultExpanded ? 2 : 1)
            implicitHeight: (clock.implicitHeight + verticalPadding   * 2) * (root.defaultExpanded ? 2 : 1)

            readonly property real basePillHeight: clock.implicitHeight + verticalPadding * 2

            Clock {
                id: clock
                anchors {
                    top: parent.top
                    topMargin: 3
                    horizontalCenter: parent.horizontalCenter
                }
                pixelSize: root._defaultClockPixelSize
            }

            Row {
                id: batteryIcon
                visible: root.defaultExpanded
                anchors {
                    verticalCenter: parent.verticalCenter
                    right: parent.right
                    rightMargin: 5
                }
                spacing: 1

                Rectangle {
                    id: batteryBody
                    implicitWidth: 25
                    implicitHeight: 15
                    anchors.verticalCenter: parent.verticalCenter
                    radius: 5
                    color: "transparent"
                    border {
                        width: 1.5
                        color: ActiveTheme.colors["FG"]
                    }
                    clip: true

                    Rectangle {
                        id: batteryFill
                        anchors {
                            left: parent.left
                            top: parent.top
                            bottom: parent.bottom
                            margins: 2.5
                        }
                        width: (parent.width - anchors.margins * 2) * root._batteryPercentage
                        radius: 3
                        color: ActiveTheme.colors["ACCENT_LOW"]

                        Behavior on width {
                            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        z: 1
                        text: Math.round(root._batteryPercentage * 100)
                        font.pixelSize: 8
                        font.bold: true
                        color: ActiveTheme.colors["BG"]
                    }
                }

                Rectangle {
                    implicitWidth: 1.5
                    implicitHeight: 6
                    anchors.verticalCenter: parent.verticalCenter
                    radius: height / 2
                    color: ActiveTheme.colors["FG"]
                }
            }
        }
        LockScreen { id: lockScreen }

        defaultItem: defaultMenu

        readonly property int _menuHideTimer: 1000
        readonly property real _fullHeight: panwin.screen ? panwin.screen.height : 1
        readonly property real _lockProgress: Math.min(Math.max(
            (root.height - defaultMenu.basePillHeight) / (_fullHeight - defaultMenu.basePillHeight), 0), 1)

        property string pillWidget: "default"
        property bool defaultExpanded: false
        property var _entries: []

        property var _batteryDevice: UPower.displayDevice
        property real _batteryPercentage: _batteryDevice.percentage
        property string _batteryStatusText: {
            switch (_batteryDevice.state) {
                case UPowerDeviceState.Charging:            return "Charging"
                case UPowerDeviceState.Discharging:         return "Discharging"
                case UPowerDeviceState.Empty:               return "Empty"
                case UPowerDeviceState.FullyCharged:        return "Fully charged"
                case UPowerDeviceState.PendingCharge:       return "Not drawing power"
                case UPowerDeviceState.PendingDischarge:    return "Pending discharge"
                default:                                    return "Unknown"
            }
        }
        
        anchors {
            top: parent.top
            horizontalCenter: parent.horizontalCenter
        }
        color: ActiveTheme.colors["BG"]
        cornerRadius: panwin.topbarHeight / 2

        // ── Public API ────────────────────────────────────────────────────────────
        function toggleLauncher(): void {
            if (pillWidget === "auth") return
            pillWidget = pillWidget === "launcher" ? "default" : "launcher"
        }
        function toggleSessionMenu(): void {
            if (pillWidget === "auth") return
            pillWidget = pillWidget === "session" ? "default" : "session"
        }
        function lockSession(): void {
            if (pillWidget === "auth") return
            pillWidget = "lock"
        }
        function reset(): void {
            if (pillWidget === "auth") return
            pillWidget = "default"
        }

        BluetoothMode  { id: bluetoothMode }
        WallpaperMode  { id: wallpaperMode }
        ColorThemeMode { id: colorThemeMode }
        readonly property var _launchModes: [bluetoothMode, wallpaperMode, colorThemeMode]

        Timer {
            id: volumeOsdTimer
            interval: root._menuHideTimer
            onTriggered: if (root.pillWidget === "volume") root.pillWidget = "default"
        }

        Timer {
            id: brightnessOsdTimer
            interval: root._menuHideTimer
            onTriggered: if (root.pillWidget === "brightness") root.pillWidget = "default"
        }

        Timer {
            id: workspaceTimer
            interval: root._menuHideTimer
            onTriggered: if (root.pillWidget === "workspace") root.pillWidget = "default"
        }

        Connections {
            target: VolumeService

            function onOsdRequested() {
                if (root.pillWidget === "launcher" || root.pillWidget === "lock" || root.pillWidget === "auth") return

                root.pillWidget = "volume"
                if (pillHoverHandler.hovered) volumeOsdTimer.stop()
                else volumeOsdTimer.restart()
            }
        }

        Connections {
            target: BrightnessService

            function onBrightnessChanged() {
                if (root.pillWidget === "launcher" || root.pillWidget === "lock" || root.pillWidget === "auth") return

                root.pillWidget = "brightness"
                if (pillHoverHandler.hovered) brightnessOsdTimer.stop()
                else brightnessOsdTimer.restart()
            }
        }

        Connections {
            target: WorkspaceService

            function onSwitched() {
                if (root.pillWidget === "launcher" || root.pillWidget === "lock" || root.pillWidget === "auth") return

                root.pillWidget = "workspace"
                if (pillHoverHandler.hovered) workspaceTimer.stop()
                else workspaceTimer.restart()
            }
        }

        PolkitAgent {
            id: polkitAgent
            onIsActiveChanged: if (isActive && root.pillWidget !== "lock") root.pillWidget = "auth"
        }

        // ── Possible Menus ────────────────────────────────────────────────────────
        Component {     // Volume OSD
            id: volumeOsdComponent
            Item {
                id: volumeOsd

                readonly property real horizontalPadding: 14
                readonly property real verticalPadding: 7
                property real iconSize: 16

                implicitWidth:  volumeRow.implicitWidth  + horizontalPadding * 2
                implicitHeight: Math.max(volumeRow.implicitHeight, iconSize) + verticalPadding * 2

                Row {
                    id: volumeRow
                    anchors.centerIn: parent
                    spacing: 6

                    Image {
                        id: volumeIcon
                        anchors.verticalCenter: parent.verticalCenter
                        source: VolumeService.muted
                                    ? Quickshell.shellDir + "/assets/icons/audio-volume-muted.svg"
                                    : Quickshell.shellDir + "/assets/icons/audio-volume-high.svg"
                        sourceSize {
                            width:  volumeOsd.iconSize
                            height: volumeOsd.iconSize
                        }
                        width:  volumeOsd.iconSize
                        height: volumeOsd.iconSize
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                    }

                    SlideBar {
                        anchors.verticalCenter: parent.verticalCenter
                        value: VolumeService.volume
                        minValue: 0
                        maxValue: 1
                        onSetValue: (v) => VolumeService.setVolume(v)
                    }
                }
            }
        }
        Component {     // Brightness OSD
            id: brightnessOsdComponent
            Item {
                id: brightnessOsd

                readonly property real horizontalPadding: 14
                readonly property real verticalPadding: 7
                property real iconSize: 16

                implicitWidth:  brightnessRow.implicitWidth  + horizontalPadding * 2
                implicitHeight: Math.max(brightnessRow.implicitHeight, iconSize) + verticalPadding * 2

                Row {
                    id: brightnessRow
                    anchors.centerIn: parent
                    spacing: 6

                    Image {
                        id: brightnessIcon
                        anchors.verticalCenter: parent.verticalCenter
                        source: Quickshell.shellDir + "/assets/icons/brightness.svg"
                        sourceSize {
                            width:  brightnessOsd.iconSize
                            height: brightnessOsd.iconSize
                        }
                        width:  brightnessOsd.iconSize
                        height: brightnessOsd.iconSize
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                    }

                    SlideBar {
                        anchors.verticalCenter: parent.verticalCenter
                        value: BrightnessService.value
                        minValue: 0.02  // This matches window manager's keybind min limit
                        maxValue: 1
                        onSetValue: (v) => BrightnessService.setValue(v)
                    }
                }
            }
        }
        Component {     // Launcher
            id: launcherComponent
            Launcher {
                id: launcher

                entries:      root._entries
                launchModes:  root._launchModes

                Connections {
                    target: DesktopEntries
                    function onApplicationsChanged() { launcher.rebuildEntries() }
                }

                // ── App entries ───────────────────────────────────────────────────────────
                function rebuildEntries() {
                    root._entries = DesktopEntries.applications.values
                        .filter(app => !app.noDisplay)
                        .map(app => ({
                            id:      app.id ?? app.name,
                            name:    app.name,
                            icon:    app.icon ? "image://icon/" + app.icon : "",
                            comment: app.comment ?? "",
                            action:  (function(a) { return () => a.execute() })(app)
                        }))
                        .sort((a, b) => a.name.localeCompare(b.name))
                }

                // ── Hooks ─────────────────────────────────────────────────────────────────
                onCloseRequested: root.pillWidget = "default"
                Component.onCompleted: {
                    rebuildEntries()
                    Qt.callLater(launcher.forceInputFocus)

                    wallpaperMode.rescan()
                    colorThemeMode.rescan()
                }
            }
        }
        Component {     // Workspace OSD
            id: workspaceOsdComponent
            WorkspaceOSD {}
        }
        Component {     // Session menu
            id: sessionComponent;
            SessionMenu {
                id: sessionMenu
                cornerRadius: root.cornerRadius

                onResetRequested: root.reset()
                onLockRequested: root.lockSession()
            }
        }
        Component {     // Authentication
            id: authComponent
            Authenticator {
                id: authItem
                flow: polkitAgent.flow
                
                Connections {
                    target: authItem.flow
                    function onIsCompletedChanged() { if (authItem.flow.isCompleted) root.pillWidget = "default" }
                    function onIsResponseRequiredChanged() {
                        if (authItem.flow.isResponseRequired && authItem.flow.failed) authItem.authFailed()
                    }
                }

                onAuthSubmitRequested: (passwd) => { if (authItem.flow) authItem.flow.submit(passwd) }
                onAuthCancelRequested: {
                    if (authItem.flow) authItem.flow.cancelAuthenticationRequest()
                    root.pillWidget = "default"
                }
            }
        }
        Component {     // Lock visual
            id: lockComponent
            LockVisual {
                implicitWidth:  panwin.screen ? panwin.screen.width  : 0
                implicitHeight: panwin.screen ? panwin.screen.height : 0
                wallpaper: LockService.currentWallpaper
                clockPixelSize: root._defaultClockPixelSize + root._lockProgress * (64 - 16)
            }
        }

        onPillWidgetChanged: {
            if (pillWidget === "default") root.content = null
            else {
                root.defaultExpanded = false
                switch (pillWidget) {
                    case "volume":      root.content = volumeOsdComponent;      break
                    case "brightness":  root.content = brightnessOsdComponent;  break
                    case "launcher":    root.content = launcherComponent;       break
                    case "workspace":   root.content = workspaceOsdComponent;   break
                    case "lock":        root.content = lockComponent;           break
                    case "session":     root.content = sessionComponent;        break
                    case "auth":        root.content = authComponent;           break
                }
            }
        }
        Component.onCompleted: root.content = null

        HoverHandler {
            id: pillHoverHandler
            cursorShape: root.pillWidget === "default" ? Qt.PointingHandCursor : Qt.ArrowCursor

            onHoveredChanged: {
                switch (root.pillWidget) {
                    case "volume":
                        if (hovered) volumeOsdTimer.stop()
                        else volumeOsdTimer.restart()
                        break
                    case "brightness":
                        if (hovered) brightnessOsdTimer.stop()
                        else brightnessOsdTimer.restart()
                        break
                    case "workspace":
                        if (hovered) workspaceTimer.stop()
                        else workspaceTimer.restart()
                        break
                    case "default":
                        root.defaultExpanded = hovered
                        break
                    default:
                        break
                }
            }
        }

        // ── Morph handoff ────────────────────────────────────────────────────
        Connections {
            target: root
            function onMorphFinished() {
                if (root.pillWidget === "lock" && !lockScreen.isLocked) {
                    root.square = true
                    lockScreen.lock()   // decoy is fully fullscreen now — safe to hand off
                }
            }
        }

        Connections {
            target: lockScreen
            function onReadyToUnlock() {
                root.square = false
                lockScreen.unlock()      // decoy still fullscreen underneath — no flash
                root.pillWidget = "default"    // now shrink back down
            }
        }
    }

    function toggleLauncher(): void { root.toggleLauncher() }
    function toggleSessionMenu(): void { root.toggleSessionMenu() }
    function lockSession(): void { root.lockSession() }
    function reset(): void { root.reset() }
}
