// quickshell/shell/widgets/base/RingMeter.qml


import QtQuick
import QtQuick.Shapes
import ElysianShell.Themes

Item {
    id: root

    property var infoTextFormat: (value, displayValue) => { return Math.round(value) + "°C" }
    property string _infoText: infoTextFormat(root.smoothValue, root.level)

    property var infoSubTextFormat: (value, displayValue) => { return "" }
    property string _infoSubText: infoSubTextFormat(root.smoothValue, root.level)

    property real minValue: 0
    property real value:    50
    property real maxValue: 100
    property real level:    maxValue > minValue
        ? Math.max(0, Math.min(1, (value - minValue) / (maxValue - minValue)))
        : 0

    property real smoothValue: value
    Behavior on smoothValue { NumberAnimation { duration: 400; easing.type: Easing.InOutCubic } }

    property color minColor: ActiveTheme.colors["ANSI_BLUE"]
    property color maxColor: ActiveTheme.colors["ANSI_RED"]

    property color ringColor: {
        var t = Math.max(0, Math.min(1, level));
        var h = minColor.hslHue + (maxColor.hslHue - minColor.hslHue) * t;
        var s = minColor.hslSaturation + (maxColor.hslSaturation - minColor.hslSaturation) * t;
        var l = minColor.hslLightness + (maxColor.hslLightness - minColor.hslLightness) * t;
        return Qt.hsla(h, s, l, 1.0);
    }

    Behavior on ringColor { ColorAnimation { duration: 400 } }

    property real ringRadius: 90
    property real ringThickness: 8
    property real startAngle: -30   // 3 o'clock = 0, clockwise positive
    property real sweepTotal: 300

    property real textRadius: root.ringRadius + root.ringThickness
    property real gapAngle: (root.startAngle + 180 + root.sweepTotal / 2) * Math.PI / 180

    implicitWidth: 2 * ringRadius + ringThickness
    implicitHeight: 2 * ringRadius + ringThickness

    Shape {
        anchors.fill: parent
        antialiasing: true

        // background track
        ShapePath {
            strokeWidth: root.ringThickness
            strokeColor: ActiveTheme.colors["BG_DEEP"]
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
                    NumberAnimation { duration: 400; easing.type: Easing.InOutCubic }
                }
            }
        }
    }

    Column {
        id: gapLabel
        spacing: 2

        x: root.width / 2 + root.textRadius * Math.cos(root.gapAngle) - width / 2
            + (width / 2) * Math.cos(root.gapAngle)
        y: root.height / 2 + root.textRadius * Math.sin(root.gapAngle) - height / 2

        Text {
            id: infoLabel
            anchors.horizontalCenter: parent.horizontalCenter
            text: root._infoText
            font.pixelSize: 15
            font.weight: Font.Medium
            color: ActiveTheme.colors["FG"]
        }

        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root._infoSubText
            font.pixelSize: 12
            color: ActiveTheme.colors["FG_MUTED"]
            visible: root._infoSubText.length > 0
        }
    }
}
