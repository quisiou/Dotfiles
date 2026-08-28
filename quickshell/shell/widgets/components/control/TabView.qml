/* quickshell/shell/widgets/components/control/TabView.qml */


import QtQuick
import QtQuick.Layouts
import Quickshell
import ElysianShell.Themes

Item {
    id: root

    property var tabs: []   // [{ name: "Dashboard", item: <Item> }, ...]
    property int currentIndex: 0

    readonly property int _animDuration: 200
    property bool _pagesReady: false

    signal tabRequested(int newIndex)

    Component.onCompleted: Qt.callLater(() => root._pagesReady = true)

    Keys.onRightPressed:    root.tabRequested(Math.min(root.currentIndex + 1, root.tabs.length - 1))
    Keys.onLeftPressed:     root.tabRequested(Math.max(root.currentIndex - 1, 0))

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        Item {
            id: tabBarContainer
            Layout.fillWidth: true
            Layout.preferredHeight: tabBarColumn.implicitHeight

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
                            
                            readonly property alias labelWidth: label.implicitWidth
                            property bool selected: root.currentIndex === index

                            Column {
                                id: labelCol
                                anchors.centerIn: parent

                                Text {
                                    id: icon
                                    text: (modelData.icon ?? "") === "" ? "X" : modelData.icon
                                    font.pixelSize: 24
                                    color: ActiveTheme.colors[tabDelegate.selected ? "ACCENT_LOW" : "FG"]
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    
                                    Behavior on color {
                                        ColorAnimation { duration: root._animDuration; easing.type: Easing.InOutCubic }
                                    }
                                }

                                Text {
                                    id: label
                                    text: modelData.name
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
                                onClicked: root.tabRequested(index)
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
            color: ActiveTheme.colors["BG_ACTIVE"]
            implicitWidth: 300
            implicitHeight: 1
            Layout.fillWidth: true
        }

        Item {
            id: pageContainer
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: 8
            clip: true

            Repeater {
                id: pageRepeater
                model: root.tabs

                delegate: Item {
                    id: pageSlot
                    visible: Math.abs(index - root.currentIndex) <= 1
                    width: pageContainer.width
                    height: pageContainer.height
                    y: 0
                    x: (index - root.currentIndex) * pageContainer.width

                    Behavior on x {
                        enabled: root._pagesReady
                        NumberAnimation { duration: root._animDuration; easing.type: Easing.InOutCubic }
                    }

                    Component.onCompleted: {
                        const page = modelData.item
                        if (page) {
                            page.parent = pageSlot
                            page.anchors.fill = pageSlot
                        }
                    }
                }
            }
        }
    }
}