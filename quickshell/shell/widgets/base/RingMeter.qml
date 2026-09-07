// quickshell/shell/widgets/base/RingMeter.qml


import QtQuick
import QtQuick.Shapes

Item {
    id: root

    property real minValue: 0
    property real value:    50
    property real maxValue: 100
    property real level:    maxValue > minValue
        ? Math.max(0, Math.min(1, (value - minValue) / (maxValue - minValue)))
        : 0

    property color minColor: "#378ADD"
    property color maxColor: "#E24B4A"

    property color ringColor: {
        level = Math.max(0, Math.min(1, level));
        var h = minColor.hslHue + (maxColor.hslHue - minColor.hslHue) * level;
        var s = minColor.hslSaturation + (maxColor.hslSaturation - minColor.hslSaturation) * level;
        var l = minColor.hslLightness + (maxColor.hslLightness - minColor.hslLightness) * level;
        return Qt.hsla(h, s, l, 1.0);
    }

    Behavior on ringColor { ColorAnimation { duration: 400 } }

    property real ringRadius: 90
    property real ringThickness: 8
    property real startAngle: 135   // 3 o'clock = 0, clockwise positive
    property real sweepTotal: 270   // leaves a 90° gap centered at top

    implicitWidth: 200
    implicitHeight: 200

    Shape {
        anchors.fill: parent
        antialiasing: true

        // background track
        ShapePath {
            strokeWidth: root.ringThickness
            strokeColor: "#33888888"
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: root.ringRadius
                radiusY: root.ringRadius
                startAngle: root.startAngle
                sweepAngle: root.sweepTotal
            }
        }

        // value arc
        ShapePath {
            strokeWidth: root.ringThickness
            strokeColor: root.ringColor
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                centerX: root.width / 2
                centerY: root.height / 2
                radiusX: root.ringRadius
                radiusY: root.ringRadius
                startAngle: root.startAngle
                sweepAngle: root.sweepTotal * root.level

                Behavior on sweepAngle {
                    NumberAnimation { duration: 400; easing.type: Easing.OutCubic }
                }
            }
        }
    }

    Text {
        anchors.bottom: parent.bottom
        // anchors.bottomMargin: 14
        anchors.horizontalCenter: parent.horizontalCenter
        text: Math.round(root.value) + "°C"
        font.pixelSize: 20
        font.weight: Font.Medium
        color: "#aaaaaa"
    }
}
