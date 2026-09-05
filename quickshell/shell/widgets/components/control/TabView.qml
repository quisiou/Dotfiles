/* quickshell/shell/widgets/components/control/TabView.qml */


pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import ElysianShell.Themes

Item {
    id: root

    property var tabs: []   // [{ name: "Dashboard", item: <Item> }, ...]
    property int currentIndex: 0

    readonly property int _animDuration: 200
    property bool _pagesReady: false

    readonly property Item _currentPageItem:
        (root.currentIndex >= 0 && root.currentIndex < root.tabs.length)
            ? root.tabs[root.currentIndex].item
            : null

    readonly property real _pageHeight: root._currentPageItem ? root._currentPageItem.implicitHeight : 0

    implicitHeight: tabBarContainer.height + separator.height + 8 + pageContainer.height

    signal tabRequested(int newIndex)

    Component.onCompleted: Qt.callLater(() => root._pagesReady = true)

    Keys.forwardTo:         root._currentPageItem ? [root._currentPageItem] : []
    Keys.onRightPressed:    root.tabRequested(Math.min(root.currentIndex + 1, root.tabs.length - 1))
    Keys.onLeftPressed:     root.tabRequested(Math.max(root.currentIndex - 1, 0))

    Item {
        id: tabBarContainer
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: tabBarColumn.implicitHeight

        ColumnLayout {
            id: tabBarColumn
            anchors.fill: parent
            spacing: 6

            RowLayout {
                id: tabRow
                Layout.fillWidth: true
                Layout.topMargin: 8
                spacing: 32

                Repeater {
                    id: tabRepeater
                    model: root.tabs

                    delegate: Item {
                        id: tabDelegate
                        Layout.fillWidth: true
                        Layout.preferredHeight: labelCol.implicitHeight

                        required property int index
                        required property var modelData
                        readonly property alias labelWidth: label.implicitWidth
                        property bool selected: root.currentIndex === index

                        Column {
                            id: labelCol
                            anchors.centerIn: parent

                            Text {
                                id: icon
                                text: (tabDelegate.modelData.icon ?? "") === "" ? "X" : tabDelegate.modelData.icon
                                font.pixelSize: 24
                                color: ActiveTheme.colors[tabDelegate.selected ? "ACCENT_LOW" : "FG"]
                                anchors.horizontalCenter: parent.horizontalCenter

                                Behavior on color {
                                    ColorAnimation { duration: root._animDuration; easing.type: Easing.InOutCubic }
                                }
                            }

                            Text {
                                id: label
                                text: tabDelegate.modelData.name
                                font.pixelSize: 15
                                color: ActiveTheme.colors[tabDelegate.selected ? "ACCENT_LOW" : "FG"]

                                Behavior on color {
                                    ColorAnimation { duration: root._animDuration; easing.type: Easing.InOutCubic }
                                }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.tabRequested(tabDelegate.index)
                        }
                    }
                }
            }

            Item {
                id: indicatorTrack
                Layout.fillWidth: true
                Layout.preferredHeight: 3

                Rectangle {
                    id: indicator
                    height: 3
                    radius: 1.5
                    color: ActiveTheme.colors["ACCENT_LOW"]

                    property var currentTab: tabRepeater.count > 0 ? tabRepeater.itemAt(root.currentIndex) : null

                    x: currentTab ? tabRow.x + currentTab.x + (currentTab.width - currentTab.labelWidth * 5/4) / 2 : 0
                    width: currentTab ? currentTab.labelWidth * 5/4 : 0

                    Behavior on x {
                        NumberAnimation { duration: root._animDuration; easing.type: Easing.InOutCubic }
                    }
                    Behavior on width {
                        NumberAnimation { duration: root._animDuration; easing.type: Easing.InOutCubic }
                    }
                }
            }
        }
    }

    Rectangle {
        id: separator
        anchors.top: tabBarContainer.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        color: ActiveTheme.colors["BG_ACTIVE"]
        height: 1
    }

    Item {
        id: pageContainer
        anchors.top: separator.bottom
        anchors.topMargin: 8
        anchors.left: parent.left
        anchors.right: parent.right
        height: root._pageHeight
        clip: true

        Repeater {
            id: pageRepeater
            model: root.tabs

            delegate: Item {
                id: pageSlot

                required property int index
                required property var modelData

                visible: Math.abs(index - root.currentIndex) <= 1
                width: pageContainer.width
                height: modelData.item ? modelData.item.implicitHeight : pageContainer.height
                y: 0
                x: (index - root.currentIndex) * pageContainer.width

                Behavior on x {
                    enabled: root._pagesReady
                    NumberAnimation { duration: root._animDuration; easing.type: Easing.InOutCubic }
                }

                Component.onCompleted: {
                    const page = pageSlot.modelData.item
                    if (page) {
                        page.parent = pageSlot
                        page.anchors.fill = pageSlot
                        page.visible = true
                    }
                }
            }
        }
    }
}
