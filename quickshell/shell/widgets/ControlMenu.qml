/* quickshell/shell/widgets/ControlMenu.qml */


pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Polkit
import QtQuick
import ElysianShell.Services
import ElysianShell.Themes
import "base"
import "components/auth"
import "components/control"
import "components/control/pages"
import "components/default"
import "components/lock"
import "components/launcher"
import "components/launcher/modes"
import "components/session"
import "components/workspace"

// qmllint disable uncreatable-type
PanelWindow {
// qmllint enable uncreatable-type
    id: panwin
    readonly property int topbarHeight: 40

    readonly property real lipHeight: 32
    readonly property real pillHeight: 36
    readonly property real pillGap: 6
    readonly property real lipOverlap: 6

    // The container is a pill only while it is the lock UI
    readonly property bool isPill: root.pillWidget === "lock"

    exclusiveZone: lipHeight - lipOverlap
    exclusionMode: ExclusionMode.Normal

    implicitWidth: screen.width
    implicitHeight: screen.height

    WlrLayershell.layer: root.pillWidget !== "default" ? WlrLayer.Overlay : WlrLayer.Top
    WlrLayershell.keyboardFocus: root.pillWidget === "default"
        || root.pillWidget === "volume"
        || root.pillWidget === "brightness"
        || root.pillWidget === "workspace"
        || root.pillWidget === "lock"
            ? WlrKeyboardFocus.None
            : WlrKeyboardFocus.Exclusive
    WlrLayershell.namespace: "elysian-top-bar"

    mask: Region { item: root }

    anchors { top: true; right: true; left: true }
    color: "transparent"

    focusable: true

    // ── Content ───────────────────────────────────────────────────────────────
    MorphingContainer {
        id: root
        isPill: panwin.isPill
        pillMorphDuration: lockScreen.pillMorphMs
        transform: Translate { id: shakeShift }
        readonly property int _defaultClockPixelSize: 16

        DefaultMenu {
            id: defaultMenu
            anchors.fill: parent
            barHeight: panwin.lipHeight
            clockPixelSize: root._defaultClockPixelSize
            mouseEnabled: root.pillWidget === "default"

            onDashboardTabRequested: {
                const idx = root._controlCenterTabs.findIndex(t => t.name === "Dashboard")
                root._controlCenterCurrentIndex = idx >= 0 ? idx : 0
                root.pillWidget = "control"
            }
            onSystemTabRequested: {
                const idx = root._controlCenterTabs.findIndex(t => t.name === "System")
                root._controlCenterCurrentIndex = idx >= 0 ? idx : 0
                root.pillWidget = "control"
            }
            onMediaTabRequested: {
                const idx = root._controlCenterTabs.findIndex(t => t.name === "Media")
                root._controlCenterCurrentIndex = idx >= 0 ? idx : 0
                root.pillWidget = "control"
            }
        }

        defaultItem: defaultMenu

        readonly property int _menuHideTimer: 1000

        property string pillWidget: "default"
        property var _entries: []

        property var authQueue: []
        readonly property bool authBusy: pillWidget === "auth" || pillWidget === "auth-askpass"
        property bool lastAskpassFailed: false
        property bool _askpassPendingResult: false

        function requestAuth(entry) {
            authQueue.push(entry)
            _processAuthQueue()
        }

        function _processAuthQueue() {
            if (authBusy || authQueue.length === 0 || lockScreen.isLocked) return
            var next = authQueue.shift()
            if (next.type === "polkit") {
                pillWidget = "auth"
            } else if (next.type === "askpass") {
                askpassSettleTimer.stop()
                root.lastAskpassFailed = root._askpassPendingResult
                root._askpassPendingResult = false
                askpassFlow.start(next.prompt, next.pipe)
                pillWidget = "auth-askpass"
            }
        }

        anchors {
            top: parent.top
            topMargin: panwin.pillGap * root.detach
            horizontalCenter: parent.horizontalCenter
        }
        color: ActiveTheme.colors["BG"]
        cornerRadius: panwin.topbarHeight / 2

        // ── Public API ────────────────────────────────────────────────────────────
        function toggleLauncher(): void {
            if (pillWidget === "auth" || lockScreen.isLocked) return
            pillWidget = pillWidget === "launcher" ? "default" : "launcher"
        }
        function toggleSessionMenu(): void {
            if (pillWidget === "auth" || lockScreen.isLocked) return
            pillWidget = pillWidget === "session" ? "default" : "session"
        }
        function lockSession(): void {
            if (pillWidget === "auth" || lockScreen.isLocked) return
            pillWidget = "lock"
            lockScreen.lock()
        }
        function reset(): void {
            if (pillWidget === "auth" || lockScreen.isLocked) return
            pillWidget = "default"
        }
        function askPass(prompt: string, pipe: string): void {
            root.requestAuth({ type: "askpass", prompt: prompt, pipe: pipe })
        }

        BluetoothMode  { id: bluetoothMode }
        WallpaperMode  { id: wallpaperMode }
        ColorThemeMode { id: colorThemeMode }
        readonly property var _launchModes: [bluetoothMode, wallpaperMode, colorThemeMode]

        function _rebuildEntries() {     // App entries
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

        DashboardPage   { id: dashboardPage;    visible: false }
        MediaPage       { id: mediaPage;        visible: false }
        SystemPage      { id: systemPage;       visible: false }
        PerformancePage { id: performancePage;  visible: false }
        property int _controlCenterCurrentIndex: 0
        readonly property var _controlCenterTabs: [
            { name: "Dashboard",    item: dashboardPage,    icon: "\udb81\udd6e" },
            { name: "Media",        item: mediaPage,        icon: "\udb83\udcb8" },
            { name: "Performance",  item: performancePage,  icon: "\udb81\udcc5" },
            { name: "System",       item: systemPage,       icon: "\ue690" }
        ]

        PolkitAgent {
            id: polkitAgent
            onIsActiveChanged: {
                if (isActive) {
                    if (!lockScreen.isLocked) root.requestAuth({ type: "polkit" })
                } else {
                    // flow disappeared (cancelled/timed out) — drop it if still queued,
                    // or clear the screen if it was the one showing
                    root.authQueue = root.authQueue.filter(e => e.type !== "polkit")
                    if (root.pillWidget === "auth") {
                        root.pillWidget = "default"
                        Qt.callLater(root._processAuthQueue)
                    }
                }
            }
        }

        AskpassFlow { id: askpassFlow }

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

        Timer {
            id: askpassSettleTimer
            interval: 3000
            onTriggered: root._askpassPendingResult = false
        }

        Connections {
            target: VolumeService

            function onOsdRequested() {
                if ((root.pillWidget === "default" && defaultMenu.expanded)
                    || !["default", "volume", "brightness", "workspace"].includes(root.pillWidget)) return

                root.pillWidget = "volume"
                if (pillHoverHandler.hovered) volumeOsdTimer.stop()
                else volumeOsdTimer.restart()
            }
        }

        Connections {
            target: BrightnessService

            function onBrightnessChanged() {
                if ((root.pillWidget === "default" && defaultMenu.expanded)
                    || !["default", "volume", "brightness", "workspace"].includes(root.pillWidget)) return

                root.pillWidget = "brightness"
                if (pillHoverHandler.hovered) brightnessOsdTimer.stop()
                else brightnessOsdTimer.restart()
            }
        }

        Connections {
            target: WorkspaceService

            function onSwitched() {
                if ((root.pillWidget === "default" && defaultMenu.expanded)
                    || !["default", "volume", "brightness", "workspace"].includes(root.pillWidget)) return

                root.pillWidget = "workspace"
                if (pillHoverHandler.hovered) workspaceTimer.stop()
                else workspaceTimer.restart()
            }
        }

        Connections {
            target: askpassFlow
            function onSubmitted() {
                root._askpassPendingResult = true
                askpassSettleTimer.restart()
            }
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
                            width:  48
                            height: 48
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
                            width:  48
                            height: 48
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
                    function onApplicationsChanged() { root._rebuildEntries() }
                }

                // ── Hooks ─────────────────────────────────────────────────────────────────
                onCloseRequested: root.pillWidget = "default"
                Component.onCompleted: {
                    root._rebuildEntries()
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
        Component {     // Authentication (Polkit)
            id: authComponent
            Authenticator {
                id: authItem
                // qmllint disable unresolved-type
                flow: polkitAgent.flow
                // qmllint enable unresolved-type
                Connections {
                    target: authItem.flow
                    function onIsCompletedChanged() {
                        if (authItem.flow.isCompleted) {
                            root.pillWidget = "default"
                            Qt.callLater(root._processAuthQueue)
                        }
                    }
                    function onIsResponseRequiredChanged() {
                        if (authItem.flow.isResponseRequired && authItem.flow.failed) authItem.authFailed()
                    }
                }
                onAuthSubmitRequested: (passwd) => { if (authItem.flow) authItem.flow.submit(passwd) }
                onAuthCancelRequested: {
                    if (authItem.flow) authItem.flow.cancelAuthenticationRequest()
                    root.pillWidget = "default"
                    Qt.callLater(root._processAuthQueue)
                }
            }
        }
        Component {     // Authentication (ssh / sudo)
            id: authAskpassComponent
            Authenticator {
                id: authAskpassItem
                flow: askpassFlow
                showError: root.lastAskpassFailed
                Connections {
                    target: askpassFlow
                    function onIsCompletedChanged() {
                        if (askpassFlow.isCompleted) {
                            root.pillWidget = "default"
                            Qt.callLater(root._processAuthQueue)
                        }
                    }
                }
                onAuthSubmitRequested: (passwd) => askpassFlow.submit(passwd)
                onAuthCancelRequested: {
                    askpassFlow.cancelAuthenticationRequest()
                    root.pillWidget = "default"
                    Qt.callLater(root._processAuthQueue)
                }
            }
        }
        Component {     // Control center
            id: controlComponent
            ControlCenter {
                tabs: root._controlCenterTabs
                currentIndex: root._controlCenterCurrentIndex
                settled: !root._morphing

                onTabChanged: (newIndex) => { root._controlCenterCurrentIndex = newIndex }
                onCloseRequested: root.pillWidget = "default"
            }
        }
        Component {     // Lock (password pill, display only)
            id: lockComponent
            LockPill {
                password: lockScreen.passwordText
                busy: lockScreen.busy || lockScreen.unlocking
                message: lockScreen.errorVisible ? lockScreen.errorMessage : ""
                barHeight: panwin.pillHeight
                animDuration: root._animDuration
                easingType: root._easingType
            }
        }

        onPillWidgetChanged: {
            if (lockScreen.isLocked && !lockScreen.unlocking && pillWidget !== "lock") {
                pillWidget = "lock"
                return
            }
            if (pillWidget === "default") root.content = null
            else {
                switch (pillWidget) {
                    case "volume":          root.content = volumeOsdComponent;      break
                    case "brightness":      root.content = brightnessOsdComponent;  break
                    case "launcher":        root.content = launcherComponent;       break
                    case "workspace":       root.content = workspaceOsdComponent;   break
                    case "session":         root.content = sessionComponent;        break
                    case "auth":            root.content = authComponent;           break
                    case "auth-askpass":    root.content = authAskpassComponent;    break
                    case "control":         root.content = controlComponent;        break
                    case "lock":            root.content = lockComponent;           break
                }
            }
        }
        Component.onCompleted: root.content = null

        HoverHandler {
            id: pillHoverHandler
            onHoveredChanged: {
                defaultMenu.expanded = hovered
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
                    default:
                        break
                }
            }
        }
    }

    SequentialAnimation {
        id: shake
        NumberAnimation { target: shakeShift; property: "x"; to: -10; duration: 50 }
        NumberAnimation { target: shakeShift; property: "x"; to:  10; duration: 80 }
        NumberAnimation { target: shakeShift; property: "x"; to:  -6; duration: 70 }
        NumberAnimation { target: shakeShift; property: "x"; to:   0; duration: 50 }
    }

    LockScreen { id: lockScreen }

    Connections {
        target: lockScreen
        function onUnlockingChanged() {
            if (lockScreen.unlocking) root.pillWidget = "default"     // pill reshapes back to the lip
        }
        function onIsLockedChanged() {
            if (!lockScreen.isLocked) {
                if (root.pillWidget === "lock") root.pillWidget = "default"   // unlocked by another path
                root._processAuthQueue()
            }
        }
        function onErrorVisibleChanged() { if (lockScreen.errorVisible) shake.restart() }
    }

    function toggleLauncher(): void { root.toggleLauncher() }
    function toggleSessionMenu(): void { root.toggleSessionMenu() }
    function lockSession(): void { root.lockSession() }
    function reset(): void { root.reset() }
    function askPass(prompt: string, pipe: string): void { root.askPass(prompt, pipe) }
    function openControlTab(tabName: string): void {
        const idx = root._controlCenterTabs.findIndex(t => t.name === tabName)
        root._controlCenterCurrentIndex = idx >= 0 ? idx : 0
        root.pillWidget = "control"
    }
}
