/* quickshell/shell/widgets/components/lock/LockScreen.qml */


import QtQuick
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import ElysianShell.Themes
import ElysianShell.Services

Item {
    id: root
    property string passwordText: ""
    property string errorMessage: ""
    property bool errorVisible: false
    property real secondsTillBlackOut: 60
    readonly property bool isLocked: sessionLock.locked
    readonly property int _fadeDuration: 200

    signal readyToUnlock()

    function lock() {
        errorVisible = false
        errorMessage = ""
        sessionLock.locked = true
        sessionLock.blackedOut = false
        idleTimer.restart() 
    }
    function unlock() { sessionLock.locked = false }

    PamContext {
        id: pam
        onPamMessage: if (responseRequired) respond(root.passwordText)
        onCompleted: (result) => {
            root.passwordText = ""
            if (result === PamResult.Success) {
                root.readyToUnlock()          // signal TopBar; don't unlock directly
            } else {
                root.errorMessage = "Incorrect password"
                root.errorVisible = true
            }
        }
        onError: (error) => console.log("PAM error:", error)
    }

    function tryUnlock() {
        if (passwordText.length === 0) return
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
        running: sessionLock.locked
        onTriggered: {
            sessionLock.blackedOut = true
            dpmsOff.running = true
        }
    }

    function resetIdle() {
        if (sessionLock.blackedOut) {
            sessionLock.blackedOut = false
            dpmsOn.running = true
        }
        idleTimer.restart()
    }

    WlSessionLock {
        id: sessionLock
        property bool blackedOut: false

        WlSessionLockSurface {
            color: "#000000"
            // color: ActiveTheme.colors["BG"]

            Item {
                id: sessionItem
                anchors.fill: parent
                focus: true

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    propagateComposedEvents: true
                    onPositionChanged: root.resetIdle()
                    onPressed: (mouse) => { root.resetIdle(); mouse.accepted = false }
                }

                Keys.onPressed: (event) => { root.resetIdle(); event.accepted = false }

                Loader {
                    anchors.fill: parent
                    active: !sessionLock.blackedOut
                    sourceComponent: Component { LockVisual { wallpaper: LockService.currentWallpaper } }
                }

                Column {
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: 40 }
                    spacing: 8
                    opacity: sessionLock.blackedOut ? 0 : 1

                    Behavior on opacity { NumberAnimation { duration: root._fadeDuration; easing.type: Easing.InOutQuad } }

                    Text {
                        color: ActiveTheme.colors["ERROR"]
                        font.pixelSize: 14
                        text: root.errorMessage
                        visible: root.errorVisible
                    }

                    Rectangle {
                        anchors.left: parent.left; anchors.right: parent.right
                        height: 50; radius: 12
                        color: ActiveTheme.colors["BG_STRIPE"]

                        TextInput {
                            anchors.fill: parent
                            anchors.margins: 16
                            color: ActiveTheme.colors["FG"]
                            font.pixelSize: 16
                            echoMode: TextInput.Password
                            enabled: !pam.active
                            text: root.passwordText
                            onTextChanged: { root.passwordText = text; root.resetIdle() }
                            onAccepted: root.tryUnlock()
                            Keys.onEscapePressed: sessionItem.forceActiveFocus()
                            HoverHandler { cursorShape: Qt.IBeamCursor }
                        }
                    }
                }
            }
        }
    }
}
