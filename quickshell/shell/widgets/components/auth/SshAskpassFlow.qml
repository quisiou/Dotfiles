// quickshell/shell/widgets/components/auth/SshAskpassFlow.qml
import QtQuick
import Quickshell.Io

QtObject {
    id: root

    property string message: ""
    property string actionId: "ssh-askpass"
    property bool isResponseRequired: true
    property bool responseVisible: false
    property bool isCompleted: false
    property bool failed: false

    property string pipePath: ""

    function start(prompt, pipe) {
        message = prompt
        pipePath = pipe
        isCompleted = false
        failed = false
    }

    function submit(passwd) {
        writer.passwd = passwd
        writer.running = true
    }

    function cancelAuthenticationRequest() {
        writer.passwd = ""   // unblocks the waiting `cat` in the askpass script with empty output -> ssh treats as failed auth, doesn't hang
        writer.running = true
    }

    property Process writer: Process {
        property string passwd: ""
        command: ["sh", "-c", "cat > \"$1\"", "_", root.pipePath]
        stdinEnabled: true
        onStarted: {
            write(passwd + "\n")
            stdinEnabled = false
        }
        onExited: root.isCompleted = true
    }
}
