// quickshell/shell/widgets/base/FillMeter.qml


import QtQuick
import ElysianShell.Themes

Item {
    id: root
    
    property var infoTextFormat: (value, displayValue) => { return Math.round(displayValue * 100) + "%" }
    property string _infoText: infoTextFormat(root.value, root.smoothLevel)

    property var infoSubTextFormat: (value, displayValue) => { return "" }
    property string _infoSubText: infoSubTextFormat(root.value, root.smoothLevel)

    property real minValue: 0
    property real value:    0.5
    property real maxValue: 1
    property real level:    maxValue > minValue
        ? Math.max(0, Math.min(1, (value - minValue) / (maxValue - minValue)))
        : 0

    property real smoothLevel: level
    Behavior on smoothLevel { NumberAnimation { duration: 500; easing.type: Easing.OutCubic } }

    property color liquidColor: ActiveTheme.colors["ACCENT_LOW"]
    property real waveAmplitude: 5
    property real waveLengthFactor: 1.5
    property int animDuration: 2000

    implicitWidth: 140
    implicitHeight: 140

    property real phase: 0
    NumberAnimation on phase {
        from: 0
        to: Math.PI * 2
        duration: root.animDuration
        loops: Animation.Infinite
        running: true
    }

    onPhaseChanged: canvas.requestPaint()
    onSmoothLevelChanged: canvas.requestPaint()

    Canvas {
        id: canvas
        anchors.fill: parent
        onPaint: {
            var ctx = getContext("2d");
            ctx.reset();
            var w = width, h = height;
            var r = Math.min(w, h) / 2 - 1;
            var cx = w / 2, cy = h / 2;

            ctx.save();
            ctx.beginPath();
            ctx.arc(cx, cy, r, 0, Math.PI * 2);
            ctx.clip();

            var waterY = cy + r - (root.smoothLevel * 2 * r);
            ctx.beginPath();
            ctx.moveTo(cx - r - 4, waterY);
            var waveLength = w / root.waveLengthFactor;
            for (var x = cx - r - 4; x <= cx + r + 4; x += 4) {
                var y = waterY + Math.sin((x / waveLength) * 2 * Math.PI + root.phase) * root.waveAmplitude;
                ctx.lineTo(x, y);
            }
            ctx.lineTo(cx + r + 4, cy + r + 4);
            ctx.lineTo(cx - r - 4, cy + r + 4);
            ctx.closePath();
            ctx.fillStyle = root.liquidColor;
            ctx.globalAlpha = 0.82;
            ctx.fill();
            ctx.restore();

            ctx.beginPath();
            ctx.arc(cx, cy, r, 0, Math.PI * 2);
            ctx.lineWidth = 1.5;
            ctx.strokeStyle = ActiveTheme.colors["FG_MUTED"];
            ctx.stroke();
        }
    }

    Text {
        id: percentLabel
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: root._infoSubText.length > 0 ? -10 : 0
        text: root._infoText
        font.pixelSize: 24
        font.weight: Font.Medium
        color: ActiveTheme.colors["FG"]
    }

    Text {
        anchors.top: percentLabel.bottom
        anchors.topMargin: 2
        anchors.horizontalCenter: parent.horizontalCenter
        text: root._infoSubText
        font.pixelSize: 12
        color: ActiveTheme.colors["FG_MUTED"]
        visible: root._infoSubText.length > 0
    }
}
