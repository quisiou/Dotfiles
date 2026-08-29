// quickshell/shell/widgets/components/auth/AskpassFlow.qml
import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property string message: ""
    property string actionId: "askpass"
    property bool isResponseRequired: true
    property bool responseVisible: false
    property bool isCompleted: false
    property string pipePath: ""

    signal submitted()

    function start(prompt, pipe) {
        message = prompt
        pipePath = pipe
        isCompleted = false
    }

    function submit(passwd) {
        writer.wasCancel = false
        writer.stdinEnabled = true
        writer.passwd = passwd
        writer.running = true
    }

    function cancelAuthenticationRequest() {
        writer.wasCancel = true
        writer.stdinEnabled = true
        writer.passwd = ""
        writer.running = true
    }

    property Process writer: Process {
        property string passwd: ""
        property bool wasCancel: false
        command: wasCancel
            ? ["sh", "-c", "touch \"$1.cancel\"; cat > \"$1\"", "_", root.pipePath]
            : ["sh", "-c", "cat > \"$1\"", "_", root.pipePath]
        stdinEnabled: true
        onStarted: {
            stdinEnabled = true
            write(passwd + "\n")
            stdinEnabled = false
        }
        onExited: {
            root.isCompleted = true
            if (!wasCancel) root.submitted()
        }
    }
}
