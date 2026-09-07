/* quickshell/shell/widgets/components/control/pages/PerformancePage.qml */


import QtQuick
import "../../../base"

Item {
    implicitWidth: 200
    implicitHeight: 200

    RingMeter {
        anchors.fill: parent
        minValue: 0
        value: 50
        maxValue: 100
    }

    FillMeter {
        anchors.centerIn: parent
        width: 140
        height: 140
        minValue: 0
        value: 68
        maxValue: 100
    }
}
