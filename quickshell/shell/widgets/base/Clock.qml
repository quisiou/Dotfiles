// quickshell/shell/widgets/base/Clock.qml


import QtQuick

Text {
    id: root

    property string timeFormat: "hh:mm"
    property real pixelSize: 16

    color: "white"
    font.bold: true
    text: Qt.formatTime(new Date(), root.timeFormat)
    font.pixelSize: pixelSize

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.text = Qt.formatTime(new Date(), root.timeFormat)
    }
}
