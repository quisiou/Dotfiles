/* quickshell/shell/widgets/base/NotificationLog.qml */


pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ElysianShell.Themes

Rectangle {
    id: root

    property real padding: 12
    property var entries: []   // newest first: { time, app, summary, body }

    signal dismissed(string time)

    ListModel { id: listModel }

    function _sync() {
        const incoming = root.entries
        const keys = new Set(incoming.map(e => e.time))

        // remove rows that are gone (back to front so indices stay valid)
        for (let i = listModel.count - 1; i >= 0; i--) {
            if (!keys.has(listModel.get(i).time))
                listModel.remove(i)
        }

        // insert rows that are new, keeping the incoming order
        for (let i = 0; i < incoming.length; i++) {
            const e = incoming[i]
            if (i < listModel.count && listModel.get(i).time === e.time)
                continue
            listModel.insert(i, {
                time:    e.time    ?? "",
                app:     e.app     ?? "",
                summary: e.summary ?? "",
                body:    e.body    ?? "",
                icon:    e.icon    ?? ""
            })
        }
    }

    onEntriesChanged: _sync()
    Component.onCompleted: _sync()

    clip: true
    color: "transparent"
    radius: 12

    readonly property real _scale: Math.max(0.6, Math.min(1.3, height / 250))

    function formatTime(iso) {
        const d = new Date(iso)
        if (isNaN(d.getTime()))
            return ""
        const time = Qt.formatTime(d, "HH:mm")
        if (d.toDateString() === new Date().toDateString())
            return time
        return Qt.formatDate(d, "dd MMM") + " " + time
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.padding
        spacing: 8

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "Notifications"
                font.pixelSize: Math.round(14 * root._scale)
                font.bold: true
                color: ActiveTheme.colors["FG"]
            }
            Item { Layout.fillWidth: true }
            Text {
                text: root.entries.length
                font.pixelSize: Math.round(12 * root._scale)
                color: ActiveTheme.colors["FG_GHOST"]
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                id: list
                anchors.fill: parent
                clip: true
                spacing: 6
                boundsBehavior: Flickable.StopAtBounds

                readonly property int _animDuration: 200

                model: listModel

                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                add: Transition { NumberAnimation {
                    duration: list._animDuration
                    easing.type: Easing.OutCubic
                    properties: "y"
                } }
                remove: Transition {
                    ParallelAnimation {
                        NumberAnimation {
                            property: "x"
                            to: list.width
                            duration: 200
                            easing.type: Easing.InCubic
                        }
                        NumberAnimation {
                            property: "opacity"
                            to: 0
                            duration: 200
                        }
                    }
                }

                displaced: Transition {
                    NumberAnimation {
                        properties: "y"
                        duration: 200
                        easing.type: Easing.OutCubic
                    }
                }

                delegate: Rectangle {
                    id: card

                    required property string time
                    required property string app
                    required property string summary
                    required property string body
                    required property string icon

                    width: list.width
                    height: cardRow.implicitHeight + 16
                    radius: 8
                    color: ActiveTheme.colors["BG_ACTIVE"]

                    RowLayout {
                        id: cardRow
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: 8
                        spacing: 8

                        Rectangle {
                            Layout.alignment: Qt.AlignTop
                            Layout.preferredWidth: Math.round(28 * root._scale)
                            Layout.preferredHeight: Math.round(28 * root._scale)
                            radius: width / 2
                            color: card.icon !== "" && iconImg.status === Image.Ready
                                ? "transparent"
                                : ActiveTheme.colors["ACCENT_LOW"]

                            Image {
                                id: iconImg
                                anchors.centerIn: parent
                                width: parent.width - 6
                                height: parent.height - 6
                                source: card.icon
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                asynchronous: true
                                visible: card.icon !== "" && status === Image.Ready
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: !iconImg.visible
                                text: (card.app || "?").charAt(0).toUpperCase()
                                font.pixelSize: Math.round(13 * root._scale)
                                font.bold: true
                                color: ActiveTheme.colors["BG"]
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 6

                                Text {
                                    Layout.fillWidth: true
                                    text: card.app
                                    elide: Text.ElideRight
                                    font.pixelSize: Math.round(11 * root._scale)
                                    color: ActiveTheme.colors["FG_GHOST"]
                                }

                                Text {
                                    text: root.formatTime(card.time)
                                    font.pixelSize: Math.round(11 * root._scale)
                                    color: ActiveTheme.colors["FG_GHOST"]
                                }

                                Rectangle {
                                    Layout.preferredWidth: 18
                                    Layout.preferredHeight: 18
                                    radius: 4
                                    color: closeArea.containsMouse ? ActiveTheme.colors["ACCENT_LOW"] : "transparent"

                                    Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.InOutCubic } }

                                    Text {
                                        anchors.centerIn: parent
                                        text: "\u2715"
                                        font.pixelSize: Math.round(11 * root._scale)
                                        color: closeArea.containsMouse ? ActiveTheme.colors["BG"] : ActiveTheme.colors["FG_GHOST"]

                                        Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.InOutCubic } }
                                    }

                                    MouseArea {
                                        id: closeArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.dismissed(card.time)
                                    }
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                visible: text !== ""
                                text: card.summary
                                elide: Text.ElideRight
                                font.pixelSize: Math.round(13 * root._scale)
                                font.bold: true
                                color: ActiveTheme.colors["FG"]
                            }

                            Text {
                                Layout.fillWidth: true
                                visible: text !== ""
                                text: card.body
                                wrapMode: Text.WordWrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                                font.pixelSize: Math.round(12 * root._scale)
                                color: ActiveTheme.colors["FG_LIGHT"]
                            }
                        }
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                opacity: root.entries.length === 0
                visible: opacity > 0
                text: "\udb82\ude91"
                font.pixelSize: Math.round(100 * root._scale)
                color: ActiveTheme.colors["FG_GHOST"]

                Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.InOutCubic } }
            }
        }
    }
}
