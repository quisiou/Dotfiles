/* quickshell/shell/widgets/components/control/TabView.qml */


import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property var tabs: ["Dashboard", "Media"]
    property int currentIndex: 0

    implicitWidth: 600
    implicitHeight: 300
    width: root.implicitWidth
    height: root.implicitHeight

    signal closeRequested()

    Keys.onEscapePressed: root.closeRequested()

    ColumnLayout {
        anchors{
            fill: parent
            topMargin: 20
        }
        spacing: 8

        Item {
            id: tabBarContainer
            Layout.fillWidth: true
            Layout.preferredHeight: 36

            RowLayout {
                id: tabRow
                anchors {
                    left: parent.left
                    right: parent.right
                    top: parent.top
                    topMargin: 8
                }
                spacing: 32

                Repeater {
                    id: tabRepeater
                    model: root.tabs

                    delegate: Item {
                        id: tabDelegate
                        Layout.fillWidth: true          // divides space evenly between tabs
                        Layout.preferredHeight: label.implicitHeight
                        readonly property alias labelWidth: label.implicitWidth

                        property bool selected: root.currentIndex === index

                        Text {
                            id: label
                            anchors.centerIn: parent
                            text: modelData
                            font.pixelSize: 15
                            color: tabDelegate.selected ? "#8b3a3a" : "#9a8b86"
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.currentIndex = index
                        }
                    }
                }
            }

            Rectangle {
                id: indicator
                height: 3
                radius: 1.5
                color: '#1859ca'  // placeholder, you'll wire this up
                y: tabRow.y + tabRow.height - height

                property var currentTab: tabRepeater.count > 0 ? tabRepeater.itemAt(root.currentIndex) : null

                x: currentTab ? tabRow.x + currentTab.x + (currentTab.width - currentTab.labelWidth * 3/2) / 2 : 0
                width: currentTab ? currentTab.labelWidth * 3/2 : 0

                Behavior on x {
                    NumberAnimation { duration: 250; easing.type: Easing.InOutCubic }
                }
                Behavior on width {
                    NumberAnimation { duration: 250; easing.type: Easing.InOutCubic }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            // paged content goes here
        }
    }
}