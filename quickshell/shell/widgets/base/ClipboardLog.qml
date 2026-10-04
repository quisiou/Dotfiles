/* quickshell/shell/widgets/base/ClipboardLog.qml */


pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Widgets
import ElysianShell.Themes
import ElysianShell.Services

Rectangle {
    id: root

    // Global UI size factor: 1 = default size, 0.8 = 80%, etc.
    // Scales fonts, icons, paddings, spacings and radii. Independent of the item's size.
    property real uiScale: 1
    function s(v) { return Math.round(v * uiScale) }

    property real padding: s(12)
    property var entries: []   // newest first: { time, app, summary, body }

    ListModel { id: listModel }

    function _sync() {
        const incoming = root.entries
        const keys = new Set(incoming.map(e => e.id))

        for (let i = listModel.count - 1; i >= 0; i--) {
            if (!keys.has(listModel.get(i).entryId))
                listModel.remove(i)
        }

        for (let i = 0; i < incoming.length; i++) {
            const e = incoming[i]
            if (i < listModel.count && listModel.get(i).entryId === e.id)
                continue
            listModel.insert(i, {
                entryId: e.id,
                kind:    e.kind ?? "text",
                text:    e.text ?? "",
                meta:    e.meta ?? "",
                thumb:   e.thumb ?? ""
            })
        }
    }

    onEntriesChanged: _sync()
    Component.onCompleted: _sync()

    clip: true
    color: "transparent"
    radius: s(12)

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
        spacing: root.s(8)

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Text {
                text: "Clipboard"
                font.pixelSize: root.s(14)
                font.bold: true
                color: ActiveTheme.colors["FG"]
            }
            Text {
                text: root.entries.length
                font.pixelSize: root.s(12)
                color: ActiveTheme.colors["FG_GHOST"]
            }
            Item { Layout.fillWidth: true }
            Rectangle {
                Layout.leftMargin: root.s(6)
                Layout.preferredWidth: root.s(18)
                Layout.preferredHeight: root.s(18)
                radius: root.s(4)
                color: clearArea.containsMouse ? ActiveTheme.colors["ACCENT_LOW"] : "transparent"

                Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.InOutCubic } }

                Text {
                    anchors.centerIn: parent
                    text: "\udb82\ude7a"
                    font.pixelSize: root.s(13)
                    color: clearArea.containsMouse ? ActiveTheme.colors["BG"] : ActiveTheme.colors["FG_GHOST"]

                    Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.InOutCubic } }
                }

                MouseArea {
                    id: clearArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ClipboardService.clearHistory()
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                id: list
                anchors.fill: parent
                clip: true
                spacing: root.s(6)
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

                    required property string entryId
                    required property string kind
                    required property string text
                    required property string meta
                    required property string thumb

                    width: list.width
                    height: cardCol.implicitHeight + root.s(16)
                    radius: root.s(8)
                    color: ActiveTheme.colors["BG_ACTIVE"]

                    ColumnLayout {
                        id: cardCol
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: root.s(8)
                        spacing: 1

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: root.s(5)

                            Text {
                                Layout.fillWidth: true
                                text: card.kind === "image" ? "\udb80\udee9  " + card.meta : "Text"
                                elide: Text.ElideRight
                                font.pixelSize: root.s(11)
                                color: ActiveTheme.colors["FG_GHOST"]
                            }

                            // Copy button
                            Rectangle {
                                Layout.preferredWidth: root.s(18)
                                Layout.preferredHeight: root.s(18)
                                radius: root.s(4)
                                color: copyArea.containsMouse ? ActiveTheme.colors["ACCENT_LOW"] : "transparent"
                                Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.InOutCubic } }

                                Text {
                                    anchors.centerIn: parent
                                    text: "\udb80\udd8f"
                                    font.pixelSize: root.s(11)
                                    color: copyArea.containsMouse ? ActiveTheme.colors["BG"] : ActiveTheme.colors["FG_GHOST"]
                                }
                                MouseArea {
                                    id: copyArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: ClipboardService.copy(card.entryId)
                                }
                            }

                            // delete button (same as the notification close button)
                            Rectangle {
                                Layout.preferredWidth: root.s(18)
                                Layout.preferredHeight: root.s(18)
                                radius: root.s(4)
                                color: closeArea.containsMouse ? ActiveTheme.colors["ACCENT_LOW"] : "transparent"
                                Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.InOutCubic } }

                                Text {
                                    anchors.centerIn: parent
                                    text: "\u2715"
                                    font.pixelSize: root.s(11)
                                    color: closeArea.containsMouse ? ActiveTheme.colors["BG"] : ActiveTheme.colors["FG_GHOST"]
                                }
                                MouseArea {
                                    id: closeArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: ClipboardService.remove(card.entryId)
                                }
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: card.kind === "text"
                            text: card.text
                            wrapMode: Text.WrapAnywhere
                            maximumLineCount: 3
                            elide: Text.ElideRight
                            font.pixelSize: root.s(12)
                            color: ActiveTheme.colors["FG"]
                        }

                        ClippingRectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: root.s(110)
                            Layout.topMargin: root.s(4)
                            visible: card.kind === "image"
                            radius: root.s(6)
                            color: ActiveTheme.colors["BG"]

                            Image {
                                anchors.fill: parent
                                anchors.margins: root.s(2)
                                source: card.kind === "image" ? card.thumb : ""
                                fillMode: Image.PreserveAspectFit
                                sourceSize: Qt.size(root.s(480), root.s(240))
                                smooth: true
                                asynchronous: true
                            }
                        }
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                opacity: root.entries.length === 0
                visible: opacity > 0
                text: "\udb85\ude1b"
                font.pixelSize: root.s(100)
                color: ActiveTheme.colors["FG_GHOST"]

                Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.InOutCubic } }
            }
        }
    }
}
