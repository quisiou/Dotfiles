/* quickshell/shell/widgets/components/control/ControlCenter.qml */


import QtQuick

Item {
    id: root
    property var tabs: []
    property int currentIndex: 0

    implicitWidth: 700
    implicitHeight: tabView.implicitHeight + 32
    width: root.implicitWidth
    height: root.implicitHeight

    Component.onCompleted: Qt.callLater(tabView.forceActiveFocus)

    signal closeRequested()
    signal tabChanged(int newIndex)

    TabView {
        id: tabView
        tabs: root.tabs
        currentIndex: root.currentIndex

        clip: true
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: 16
        }
        height: implicitHeight

        onTabRequested: (index) => root.tabChanged(index)
        Keys.onEscapePressed: root.closeRequested()
    }
}
