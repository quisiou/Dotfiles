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
import "base/lock"
import "base/launcher"
import "base/launcher/modes"

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
        Component {
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
                        sourceSize.width:  volumeOsd.iconSize
                        sourceSize.height: volumeOsd.iconSize
                        width:  volumeOsd.iconSize
                        height: volumeOsd.iconSize
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                    }

                    SlideBar {
                        id: slideBar
                        anchors.verticalCenter: parent.verticalCenter
                        value: VolumeService.volume
                        minValue: 0
                        maxValue: 1
                        onSetValue: (v) => VolumeService.setVolume(v)
                    }
                }
            }
        }
        Component {
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
                        sourceSize.width:  brightnessOsd.iconSize
                        sourceSize.height: brightnessOsd.iconSize
                        width:  brightnessOsd.iconSize
                        height: brightnessOsd.iconSize
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                    }

                    SlideBar {
                        id: slideBar
                        anchors.verticalCenter: parent.verticalCenter
                        value: BrightnessService.value
                        minValue: 0.02  // This matches window manager's keybind min limit
                        maxValue: 1
                        onSetValue: (v) => BrightnessService.setValue(v)
                    }
                }
            }
        }
        Component {
            id: controlCenter
            Rectangle {
                id: controlRect

                readonly property int padding: 20
                implicitWidth:  launcher.implicitWidth  + padding * 2
                implicitHeight: launcher.implicitHeight + padding * 2

                color: "transparent"

                Connections {
                    target: DesktopEntries
                    function onApplicationsChanged() { controlRect.rebuildEntries() }
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
                Component.onCompleted: {
                    rebuildEntries()
                    Qt.callLater(launcher.forceInputFocus)

                    wallpaperMode.rescan()
                    colorThemeMode.rescan()
                }

                // ── Content ───────────────────────────────────────────────────────────────
                Rectangle {
                    anchors.fill: parent
                    color: ActiveTheme.colors["BG"]
                    radius: root.radius
                    clip: true

                    Launcher {
                        id: launcher
                        anchors.centerIn: parent
                        entries:      root._entries
                        launchModes:  root._launchModes
                        onActivated:      (entry) => entry.action()
                        onCloseRequested: root.pillWidget = "default"
                    }
                }
            }
        }
        Component {
            id: workspaceOsdComponent
            Item {
                id: workspaceOsd
                property real horizontalPadding: 20
                property real verticalPadding: 7

                readonly property int _radius: 15
                readonly property int _animDuration: 100

                implicitWidth: row.implicitWidth + horizontalPadding * 2
                implicitHeight: row.implicitHeight + verticalPadding * 2

                Row {
                    id: row
                    anchors.centerIn: parent
                    spacing: 10

                    Repeater {
                        model: WorkspaceService.states

                        Rectangle {
                            id: wsIndicator

                            required property var modelData

                            readonly property bool active:  modelData.active
                            readonly property bool exists:  modelData.exists

                            visible: modelData.visible

                            width: active ? workspaceOsd._radius * 3 : workspaceOsd._radius
                            height: workspaceOsd._radius
                            radius: height / 2
                            color: WorkspaceService.colorFor(active, exists)

                            border {
                                width: 0
                                color: ActiveTheme.colors["FG"]
                            }

                            Behavior on color { ColorAnimation { duration: workspaceOsd._animDuration } }

                            Behavior on width { NumberAnimation {
                                duration: workspaceOsd._animDuration
                                easing.type: Easing.InOutCubic
                            }}

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true

                                onEntered: wsIndicator.border.width = 2
                                onExited: wsIndicator.border.width = 0
                                onClicked: WorkspaceService.activate(modelData.id)
                            }
                        }
                    }
                }
            }
        }
        Component {
            id: sessionMenuComponent;
            Item {
                id: sessionMenu
                property real padding: 10
                property int currentIndex: 0

                readonly property int _radius: 15
                readonly property int _animDuration: 100

                implicitWidth: sessionRow.implicitWidth + padding * 2
                implicitHeight: sessionRow.implicitHeight + padding * 2

                Component.onCompleted: {
                    sessionMenu.currentIndex = 0
                    Qt.callLater(sessionMenu.forceActiveFocus)
                }

                Keys.onLeftPressed:  sessionMenu.currentIndex = Math.max(sessionMenu.currentIndex - 1, 0)
                Keys.onRightPressed: sessionMenu.currentIndex = Math.min(sessionMenu.currentIndex + 1, sessionRow.sessionActions.length - 1)
                Keys.onReturnPressed: sessionRow.sessionActions[sessionMenu.currentIndex].action()
                Keys.onEscapePressed: root.reset()

                Row {
                    id: sessionRow
                    anchors.centerIn: parent
                    spacing: 10

                    property var sessionActions: [
                        {
                            title: "Lock",
                            icon: "object-locked.svg",
                            action: () => root.lockSession()
                        },
                        {
                            title: "Logout",
                            icon: "system-log-out.svg",
                            action: () => Quickshell.execDetached([
                                "bash", "-c",
                                "loginctl terminate-session \"${XDG_SESSION_ID:-$(loginctl session-status | head -1 | awk '{print $1}')}\""
                            ])
                        },
                        {
                            title: "Reboot",
                            icon: "system-reboot.svg",
                            action: () => Quickshell.execDetached(["systemctl", "reboot"])
                        },
                        {
                            title: "Shutdown",
                            icon: "system-shutdown.svg",
                            action: () => Quickshell.execDetached(["systemctl", "poweroff"])
                        }
                    ]

                    Repeater {
                        model: sessionRow.sessionActions

                        delegate: Rectangle {
                            id: btn
                            required property var modelData
                            required property int index

                            readonly property bool isCurrent: index === sessionMenu.currentIndex

                            width: 64
                            height: 64
                            radius: root.cornerRadius - sessionMenu.padding
                            color: isCurrent ? ActiveTheme.colors["BG_STRIPE"]
                                : mouseArea.containsMouse ? "#3a3a3a" : "#2a2a2a"
                            border.width: isCurrent ? 2 : 0
                            border.color: ActiveTheme.colors["ACCENT_DIM"]

                            Behavior on color { ColorAnimation { duration: sessionMenu._animDuration } }
                            Behavior on border.width { NumberAnimation { duration: sessionMenu._animDuration } }

                            Column {
                                anchors.centerIn: parent
                                spacing: 4

                                Image {
                                    source: Quickshell.shellDir + "/assets/icons/" + btn.modelData.icon
                                    width: 36
                                    height: 36
                                    anchors.horizontalCenter: parent.horizontalCenter
                                }

                                // Text {
                                //     text: btn.modelData.title
                                //     color: "white"
                                //     font.pixelSize: 15
                                //     anchors.horizontalCenter: parent.horizontalCenter
                                // }
                            }

                            MouseArea {
                                id: mouseArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onEntered: sessionMenu.currentIndex = btn.index
                                onClicked: btn.modelData.action()
                            }
                        }
                    }
                }
            }
        }
        Component {
            id: authComponent
            Item {
                id: authItem
                property real padding: 20

                implicitWidth: 450
                implicitHeight: authColumn.implicitHeight + padding * 2

                Keys.onEscapePressed: authItem.cancel()
                Component.onCompleted: Qt.callLater(passwordInput.forceActiveFocus)

                function cancel() {
                    if (polkitAgent.flow) polkitAgent.flow.cancelAuthenticationRequest()
                    root.pillWidget = "default"
                }

                function submit() {
                    if (polkitAgent.flow && passwordInput.text.length > 0) {
                        polkitAgent.flow.submit(passwordInput.text)
                        passwordInput.text = ""
                    }
                }

                Connections {
                    target: polkitAgent.flow
                    function onFailedChanged() {
                        if (polkitAgent.flow.failed) {
                            passwordInput.text = ""
                            errorText.visible = true
                            Qt.callLater(passwordInput.forceActiveFocus)
                        }
                    }
                    function onIsCompletedChanged() {
                        if (polkitAgent.flow.isCompleted) root.pillWidget = "default"
                    }
                }

                Column {
                    id: authColumn
                    anchors {
                        left: parent.left;
                        top: parent.top
                        margins: authItem.padding
                    }
                    width: authItem.implicitWidth - authItem.padding * 2
                    spacing: 12

                    Row {
                        spacing: 8
                        Text {
                            text: "\uf023"
                            color: ActiveTheme.colors["ACCENT_LOW"]
                            font.pixelSize: 14
                        }
                        Text {
                            text: "Authentication Required"
                            color: ActiveTheme.colors["FG"]
                            font {
                                pixelSize: 16
                                bold: true
                            }
                        }
                    }

                    // Message
                    Text {
                        width: parent.width
                        text: polkitAgent.flow ? polkitAgent.flow.message : ""
                        color: ActiveTheme.colors["FG_DARK"]
                        font.pixelSize: 13
                        wrapMode: Text.WordWrap
                    }

                    // Action id, muted small text
                    Text {
                        width: parent.width
                        text: polkitAgent.flow ? polkitAgent.flow.actionId : ""
                        color: ActiveTheme.colors["FG_MUTED"]
                        font.pixelSize: 11
                        elide: Text.ElideRight
                    }

                    // Password field with inline placeholder
                    Rectangle {
                        width: parent.width
                        height: 36
                        radius: 8
                        color: ActiveTheme.colors["BG_STRIPE"]
                        border {
                            width: passwordInput.activeFocus ? 1 : 0
                            color: ActiveTheme.colors["ACCENT_LOW"]
                        }

                        Text {
                            anchors { left: parent.left; leftMargin: 10; verticalCenter: parent.verticalCenter }
                            text: "Password:"
                            color: ActiveTheme.colors["DARK3"]
                            font.pixelSize: 13
                            visible: passwordInput.text.length === 0
                        }

                        TextInput {
                            id: passwordInput
                            anchors.fill: parent
                            anchors.margins: 10
                            verticalAlignment: TextInput.AlignVCenter
                            color: ActiveTheme.colors["FG"]
                            enabled: polkitAgent.flow ? polkitAgent.flow.isResponseRequired : false
                            echoMode: (polkitAgent.flow && polkitAgent.flow.responseVisible)
                                ? TextInput.Normal : TextInput.Password
                            onAccepted: authItem.submit()
                        }
                    }

                    // Buttons, right-aligned: bare-text Cancel + pill Authenticate
                    Item {
                        width: parent.width
                        height: buttonsRow.implicitHeight

                        Text {
                            id: errorText
                            visible: false
                            text: "Authentication failed, try again"
                            color: "#e06c75"
                            font.pixelSize: 11
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Row {
                            id: buttonsRow
                            spacing: 10
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter

                            Rectangle {
                                id: cancelLabel
                                width: cancelText.implicitWidth + 28
                                height: 30
                                radius: 8
                                color: ActiveTheme.colors["BG_FOCUSED"]
                                Text {
                                    id: cancelText
                                    anchors.centerIn: parent
                                    text: "Cancel"
                                    color: ActiveTheme.colors["FG"]
                                    font {
                                        pixelSize: 13
                                        bold: true
                                    }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: true

                                    onEntered:  cancelLabel.color = ActiveTheme.colors["BG_SELECTED"]
                                    onExited:   cancelLabel.color = ActiveTheme.colors["BG_FOCUSED"]
                                    onClicked:  authItem.cancel()
                                }
                            }

                            Rectangle {
                                id: authenticateLabel
                                width: authenticateText.implicitWidth + 28
                                height: 30
                                radius: 8
                                color: ActiveTheme.colors["ACCENT_LOW"]
                                Text {
                                    id: authenticateText
                                    anchors.centerIn: parent
                                    text: "Authenticate"
                                    color: ActiveTheme.colors["BG"]
                                    font {
                                        pixelSize: 13
                                        bold: true
                                    }
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: true

                                    onEntered:  authenticateLabel.color = ActiveTheme.colors["ACCENT_HIGH"]
                                    onExited:   authenticateLabel.color = ActiveTheme.colors["ACCENT_LOW"]
                                    onClicked:  authItem.submit()
                                }
                            }
                        }
                    }
                }
            }
        }
        Component {
            id: lockComponent
            LockVisual {
                implicitWidth:  panwin.screen ? panwin.screen.width  : 0
                implicitHeight: panwin.screen ? panwin.screen.height : 0
                wallpaper: LockService.currentWallpaper
                clockPixelSize: root._defaultClockPixelSize + _lockProgress * (64 - 16)
            }
        }
        LockScreen { id: lockScreen }

        onPillWidgetChanged: {
            if (pillWidget === "default") root.content = null
            else {
                root.defaultExpanded = false
                switch (pillWidget) {
                    case "volume":      root.content = volumeOsdComponent;      break
                    case "brightness":  root.content = brightnessOsdComponent;  break
                    case "launcher":    root.content = controlCenter;           break
                    case "workspace":   root.content = workspaceOsdComponent;   break
                    case "lock":        root.content = lockComponent;           break
                    case "session":     root.content = sessionMenuComponent;    break
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
