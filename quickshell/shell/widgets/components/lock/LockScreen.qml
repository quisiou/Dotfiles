/* quickshell/shell/widgets/components/lock/LockScreen.qml */


pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import ElysianShell.Themes
import "../../base"          // ClockText

Item {
    id: root
    property string passwordText: ""
    property string errorMessage: ""
    property bool errorVisible: false
    property real secondsTillBlackOut: 30
    property bool isLocked: false
    property bool unlocking: false                  // correct password, waiting for the pill to reshape
    readonly property bool busy: pam.active

    property real tintAlpha: 0.35
    property int  blurFadeMs: 400                   // keep equal to Hyprland's layer fade
    property int  pillMorphMs: 300
    property bool _blurOn: false

    function lock() {
        errorVisible = false
        errorMessage = ""
        passwordText = ""
        unlocking = false
        _blurOn = true
        sessionLock.locked = true
        sessionLock.blackedOut = false
        isLocked = true
        idleTimer.restart()
    }
    function unlock() {
        idleTimer.stop()
        unlockTimer.stop()
        _blurOn = false
        sessionLock.locked = false
        isLocked = false
        unlocking = false
        passwordText = ""
    }

    PamContext {
        id: pam
        onPamMessage: if (responseRequired) respond(root.passwordText)
        onCompleted: (result) => {
            if (result === PamResult.Success) {
                root.unlocking = true          // panel reshapes the pill back to a lip
                root._blurOn = false           // blur fades out meanwhile
                unlockTimer.restart()
            } else {
                root.passwordText = ""
                root.errorMessage = "Incorrect password"
                root.errorVisible = true
            }
        }
        onError: (error) => console.log("PAM error:", error)
    }

    Timer { id: unlockTimer; interval: Math.max(root.pillMorphMs, root.blurFadeMs) + 20; onTriggered: root.unlock() }

    function tryUnlock() {
        if (passwordText.length === 0 || unlocking) return
        errorVisible = false
        if (!pam.start()) {
            errorMessage = "Couldn't start authentication"
            errorVisible = true
        }
    }

    Process { id: dpmsOff; command: ["wlopm", "--off", "*"] }
    Process { id: dpmsOn;  command: ["wlopm", "--on", "*"] }

    Timer {
        id: idleTimer
        interval: root.secondsTillBlackOut * 1000
        onTriggered: {
            if (!sessionLock.locked) return
            sessionLock.blackedOut = true
            dpmsOff.running = true
        }
    }

    function resetIdle(reason) {
        if (!sessionLock.locked) return
        if (sessionLock.blackedOut) {
            sessionLock.blackedOut = false
            dpmsOn.running = true
        }
        idleTimer.restart()
    }

    // Empty fullscreen layer. Hyprland blurs whatever is behind it (layer rule).
    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData
            visible: root._blurOn

            anchors { top: true; bottom: true; left: true; right: true }
            exclusionMode: ExclusionMode.Ignore
            WlrLayershell.layer: WlrLayer.Overlay
            WlrLayershell.namespace: "elysian-lock-blur"
            color: Qt.rgba(0, 0, 0, root.tintAlpha)
            mask: Region {}
        }
    }

    WlSessionLock {
        id: sessionLock
        property bool blackedOut: false
        onLockedChanged: if (!locked) root.isLocked = false

        // Transparent shell: satisfies the protocol and carries the clock. The pill lives in the panel.
        WlSessionLockSurface {
            color: "transparent"

            Item {
                id: sessionItem
                anchors.fill: parent
                focus: true

                property bool shown: false
                Timer { running: true; interval: 30; onTriggered: sessionItem.shown = true }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    propagateComposedEvents: true
                    onPositionChanged: root.resetIdle("mouse-move")
                    onPressed: (mouse) => {
                        root.resetIdle("mouse-press")
                        passwordInput.forceActiveFocus()
                        mouse.accepted = false
                    }
                }

                // Hidden input: the lock surface is what Hyprland gives keyboard focus to.
                // The pill in the panel just displays what is typed here.
                TextInput {
                    id: passwordInput
                    width: 1; height: 1; opacity: 0
                    focus: true
                    echoMode: TextInput.Password
                    readOnly: root.busy || root.unlocking
                    text: root.passwordText
                    onTextChanged: {
                        root.passwordText = text
                        if (text.length > 0) root.errorVisible = false
                        root.resetIdle("typing")
                    }
                    onAccepted: root.tryUnlock()
                    Keys.onEscapePressed: root.passwordText = ""
                    Component.onCompleted: forceActiveFocus()
                }

                ClockText {
                    anchors.centerIn: parent
                    pixelSize: 64
                    opacity: sessionItem.shown && !root.unlocking && !sessionLock.blackedOut ? 1 : 0
                    Behavior on opacity { NumberAnimation { duration: root.blurFadeMs; easing.type: Easing.InOutQuad } }
                }
            }
        }
    }
}
