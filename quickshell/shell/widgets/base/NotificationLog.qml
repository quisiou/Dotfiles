/* quickshell/shell/widgets/base/NotificationLog.qml */


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
        const keys = new Set(incoming.map(e => e.time))

        // remove rows that are gone (back to front so indices stay valid)
        for (let i = listModel.count - 1; i >= 0; i--) {
            if (!keys.has(listModel.get(i).time))
                listModel.remove(i)
        }

        // insert rows that are new, keeping the incoming order
        for (let i = 0; i < incoming.length; i++) {
            const e = incoming[i]
            if (i < listModel.count && listModel.get(i).time === e.time) {
                // row exists: pick up a changed icon (e.g. the saved avatar)
                if (listModel.get(i).icon !== (e.icon ?? ""))
                    listModel.setProperty(i, "icon", e.icon ?? "")
                continue
            }
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

    signal toggleRequested()

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.padding
        spacing: root.s(8)

        Rectangle {
            id: header
            Layout.fillWidth: true
            implicitHeight: headerRow.implicitHeight + root.s(12)
            radius: root.s(8)

            color: "transparent"

            HoverHandler { id: headerHover }

            // Declared before the content so the clear button's MouseArea stays on top.
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.toggleRequested()
            }

            RowLayout {
                id: headerRow
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                anchors.leftMargin: root.s(8)
                anchors.rightMargin: root.s(8)
                spacing: 10

                Text {
                    text: "Notifications"
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

                // Clear button: unchanged
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
                        onClicked: NotificationService.clearHistory()
                    }
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

                    required property string time
                    required property string app
                    required property string summary
                    required property string body
                    required property string icon

                    width: list.width
                    height: cardRow.implicitHeight + root.s(16)
                    radius: root.s(8)
                    color: ActiveTheme.colors["BG_ACTIVE"]

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: NotificationService.invokeDefault(card.time)
                    }

                    RowLayout {
                        id: cardRow
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.margins: root.s(8)
                        spacing: root.s(8)

                        ClippingRectangle {
                            Layout.alignment: Qt.AlignTop
                            Layout.preferredWidth: root.s(28)
                            Layout.preferredHeight: root.s(28)
                            radius: width / 2
                            color: card.icon !== "" && iconImg.status === Image.Ready
                                ? "transparent"
                                : ActiveTheme.colors["ACCENT_LOW"]

                            Image {
                                id: iconImg
                                anchors.fill: parent
                                source: card.icon
                                fillMode: Image.PreserveAspectCrop
                                sourceSize: Qt.size(width * 1.5, height * 1.5)
                                smooth: true
                                asynchronous: true
                                visible: card.icon !== "" && status === Image.Ready
                            }

                            Text {
                                anchors.centerIn: parent
                                visible: !iconImg.visible
                                text: (card.app || "?").charAt(0).toUpperCase()
                                font.pixelSize: root.s(13)
                                font.bold: true
                                color: ActiveTheme.colors["BG"]
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: root.s(6)

                                Text {
                                    Layout.fillWidth: true
                                    text: card.app
                                    elide: Text.ElideRight
                                    font.pixelSize: root.s(11)
                                    color: ActiveTheme.colors["FG_GHOST"]
                                }

                                Text {
                                    text: root.formatTime(card.time)
                                    font.pixelSize: root.s(11)
                                    color: ActiveTheme.colors["FG_GHOST"]
                                }

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

                                        Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.InOutCubic } }
                                    }

                                    MouseArea {
                                        id: closeArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: NotificationService.removeHistory(card.time)
                                    }
                                }
                            }

                            Text {
                                Layout.fillWidth: true
                                visible: text !== ""
                                text: card.summary
                                elide: Text.ElideRight
                                font.pixelSize: root.s(13)
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
                                font.pixelSize: root.s(12)
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
                font.pixelSize: root.s(100)
                color: ActiveTheme.colors["FG_GHOST"]

                Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.InOutCubic } }
            }
        }
    }
}
