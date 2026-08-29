/* quickshell/shell/widgets/components/auth/Authenticator.qml */


import QtQuick
import ElysianShell.Themes

Item {
    id: root

    property real padding: 20
    property var flow: null
    property bool showError: false

    implicitWidth: 450
    implicitHeight: authColumn.implicitHeight + padding * 2

    signal authSubmitRequested(string passwd)
    signal authCancelRequested()

    function trySubmit() {
        if (passwordInput.text.length > 0) {
            root.authSubmitRequested(passwordInput.text)
            passwordInput.text = ""
            errorText.visible = false
        }
    }

    function authFailed() {
        passwordInput.text = ""
        errorText.visible = true
        passwordInput.forceActiveFocus
    }

    Component.onCompleted: Qt.callLater(passwordInput.forceActiveFocus)
    Keys.onEscapePressed: root.authCancelRequested()

    Column {
        id: authColumn
        anchors {
            left: parent.left;
            top: parent.top
            margins: root.padding
        }
        width: root.implicitWidth - root.padding * 2
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
            text: root.flow ? root.flow.message : ""
            color: ActiveTheme.colors["FG_DARK"]
            font.pixelSize: 13
            wrapMode: Text.WordWrap
        }

        // Action id, muted small text
        Text {
            width: parent.width
            text: root.flow ? root.flow.actionId : ""
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
                enabled: root.flow ? root.flow.isResponseRequired : false
                echoMode: (root.flow && root.flow.responseVisible)
                    ? TextInput.Normal : TextInput.Password
                onAccepted: root.trySubmit()
            }
        }

        // Buttons, right-aligned: bare-text Cancel + pill Authenticate
        Item {
            width: parent.width
            height: buttonsRow.implicitHeight

            Text {
                id: errorText
                visible: root.showError
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
                        onClicked:  root.authCancelRequested()
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
                        text: "Submit"
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
                        onClicked:  root.trySubmit()
                    }
                }
            }
        }
    }
}
