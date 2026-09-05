/* quickshell/shell/widgets/components/control/pages/MediaPage.qml */


pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import ElysianShell.Themes
import ElysianShell.Services

Item {
    id: root

    property string visualizerShape: "sphere"

    implicitWidth: 320
    implicitHeight: textColumn.implicitHeight

    anchors.fill: parent

    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: 50

        Item {
            id: visualizerItem

            property int   artSize: 160

            // Rect visualizer options
            property int   radius: artSize/2 + 5 // +N is the gap between art and visualizer
            property int   barWidth: 5
            property int   maxBarHeight: 40
            property color barColor: ActiveTheme.colors["ACCENT_LOW"]

            // Sphere visualizer options
            property int   spherePointCount: 220
            property real  sphereRotationSpeed: 0.4 // deg/frame
            property real  sphereTiltDeg: 20
            property real  sphereRotationY: 0

            anchors.verticalCenter: parent.verticalCenter

            width: (radius + maxBarHeight) * 2
            height: width

            // drive the cava process only while this is actually visible
            onVisibleChanged: VisualizerService.active = visible
            Component.onCompleted: VisualizerService.active = visible
            Component.onDestruction: VisualizerService.active = false

            // shared projection helper
            function _projectSpherePoints(points, values, rotY, tiltDeg, bars, R, spike) {
                const cosY = Math.cos(rotY), sinY = Math.sin(rotY)
                const tilt = tiltDeg * Math.PI / 180
                const cosX = Math.cos(tilt), sinX = Math.sin(tilt)

                let out = []
                for (let i = 0; i < points.length; i++) {
                    const p = points[i]
                    let x1 = p.x * cosY - p.z * sinY
                    let z1 = p.x * sinY + p.z * cosY
                    let y1 = p.y
                    let y2 = y1 * cosX - z1 * sinX
                    let z2 = y1 * sinX + z1 * cosX

                    const barIndex = Math.floor((i / points.length) * bars)
                    const amp = (values[barIndex] ?? 0) / 100
                    const r = R + amp * spike

                    const px = x1 * r, py = y2 * r, pz = z2 * r
                    const persp = 300 / (300 + pz)
                    out.push({ x: px * persp, y: py * persp, z: pz, s: persp })
                }
                return out
            }

            Repeater {
                model: VisualizerService.bars

                delegate: Rectangle {
                    id: bar
                    required property int index

                    readonly property real rawValue: (VisualizerService.displayValues[index] ?? 0)
                    readonly property real targetHeight: Math.max(2, (rawValue / 100) * visualizerItem.maxBarHeight)

                    visible: root.visualizerShape === "rect" && MediaService.hasPlayer

                    width: visualizerItem.barWidth
                    height: targetHeight
                    radius: width / 2
                    color: visualizerItem.barColor
                    antialiasing: true

                    // fixed base at `radius` from center; grows outward as height increases
                    x: visualizerItem.width / 2 - width / 2
                    y: visualizerItem.height / 2 - visualizerItem.radius - height

                    transform: Rotation {
                        origin.x: bar.width / 2
                        origin.y: visualizerItem.radius + bar.height
                        angle: bar.index * (360 / VisualizerService.bars)
                    }

                    Behavior on height {
                        NumberAnimation { duration: 1250 / VisualizerService.frameRate; easing.type: Easing.OutQuad }
                    }
                }
            }

            Canvas {
                id: sphereCanvas
                anchors.fill: parent
                visible: root.visualizerShape === "sphere" && MediaService.hasPlayer
                antialiasing: true

                property var points: []
                Component.onCompleted: points = _generatePoints(visualizerItem.spherePointCount)

                Timer {
                    interval: 1000 / VisualizerService.frameRate
                    running: sphereCanvas.visible
                    repeat: true
                    onTriggered: {
                        visualizerItem.sphereRotationY += visualizerItem.sphereRotationSpeed * Math.PI / 180
                        sphereCanvas.requestPaint()
                    }
                }

                Connections {
                    target: VisualizerService
                    function onValuesChanged() {
                        if (sphereCanvas.visible) sphereCanvas.requestPaint()
                    }
                }

                onPaint: {
                    const ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)
                    const cx = width / 2, cy = height / 2

                    let projected = visualizerItem._projectSpherePoints(
                        points, VisualizerService.values, visualizerItem.sphereRotationY,
                        visualizerItem.sphereTiltDeg, VisualizerService.bars,
                        visualizerItem.radius, visualizerItem.maxBarHeight)

                    projected.sort((a, b) => a.z - b.z)
                    const c = visualizerItem.barColor
                    for (const pr of projected) {
                        const size = Math.max(0.8, 2 * pr.s)
                        const alpha = Math.min(1, Math.max(0.2, pr.s))
                        ctx.fillStyle = Qt.rgba(c.r, c.g, c.b, alpha)
                        ctx.beginPath()
                        ctx.arc(cx + pr.x, cy + pr.y, size, 0, Math.PI * 2)
                        ctx.fill()
                    }
                }

                function _generatePoints(n) {
                    const pts = []
                    const offset = 2 / n
                    const increment = Math.PI * (3 - Math.sqrt(5))
                    for (let i = 0; i < n; i++) {
                        const y = (i * offset - 1) + offset / 2
                        const rr = Math.sqrt(Math.max(0, 1 - y * y))
                        const phi = i * increment
                        pts.push({
                            x: Math.cos(phi) * rr,
                            y: y,
                            z: Math.sin(phi) * rr
                        })
                    }
                    // normalize onto unit sphere at radius 1 (scaled by R at paint time)
                    return pts
                }
            }

            ClippingRectangle {
                id: albumArtMask
                width: visualizerItem.artSize
                height: visualizerItem.artSize
                radius: height / 2
                color: "transparent"
                anchors.centerIn: parent

                Text {
                    text: "\udb81\udf5b"
                    font.pixelSize: albumArtMask.height
                    color: ActiveTheme.colors["FG_MUTED"]
                    visible: !MediaService.hasPlayer
                    anchors.centerIn: parent
                }

                Image {
                    anchors.fill: parent
                    source: MediaService.artUrl
                    sourceSize {
                        width:  albumArtMask.width
                        height: albumArtMask.height
                    }
                    width:  albumArtMask.width
                    height: albumArtMask.height
                    fillMode: Image.PreserveAspectFit
                    asynchronous: true
                    visible: MediaService.hasPlayer
                }

                Canvas {
                    id: sphereShading
                    anchors.fill: parent
                    visible: MediaService.hasPlayer

                    onPaint: {
                        const ctx = getContext("2d")
                        ctx.clearRect(0, 0, width, height)
                        const cx = width / 2, cy = height / 2
                        const r = width / 2

                        // vignette: darken toward the rim to fake curvature falloff
                        const shade = ctx.createRadialGradient(cx, cy, r * 0.3, cx, cy, r)
                        shade.addColorStop(0, "rgba(0,0,0,0)")
                        shade.addColorStop(1, "rgba(0,0,0,0.55)")
                        ctx.fillStyle = shade
                        ctx.beginPath()
                        ctx.arc(cx, cy, r, 0, Math.PI * 2)
                        ctx.fill()

                        // specular highlight, offset up-left like a light source
                        const hl = ctx.createRadialGradient(cx - r * 0.35, cy - r * 0.35, 0, cx - r * 0.35, cy - r * 0.35, r * 0.6)
                        hl.addColorStop(0, "rgba(255,255,255,0.35)")
                        hl.addColorStop(1, "rgba(255,255,255,0)")
                        ctx.fillStyle = hl
                        ctx.beginPath()
                        ctx.arc(cx, cy, r, 0, Math.PI * 2)
                        ctx.fill()
                    }

                    Component.onCompleted: requestPaint()
                }
            }

            Canvas {
                id: sphereFrontCanvas
                anchors.fill: parent
                visible: root.visualizerShape === "sphere" && MediaService.hasPlayer
                antialiasing: true
                opacity: 0.25

                Timer {
                    interval: 1000 / VisualizerService.frameRate
                    running: sphereFrontCanvas.visible
                    repeat: true
                    onTriggered: sphereFrontCanvas.requestPaint()
                }

                onPaint: {
                    const ctx = getContext("2d")
                    ctx.clearRect(0, 0, width, height)
                    const cx = width / 2, cy = height / 2

                    let projected = visualizerItem._projectSpherePoints(
                        sphereCanvas.points, VisualizerService.values, visualizerItem.sphereRotationY,
                        visualizerItem.sphereTiltDeg, VisualizerService.bars,
                        visualizerItem.radius, visualizerItem.maxBarHeight)

                    let front = projected.filter(p => p.z < 0)
                    front.sort((a, b) => a.z - b.z)

                    const c = visualizerItem.barColor
                    for (const pr of front) {
                        const size = Math.max(0.8, 2 * pr.s)
                        const alpha = Math.min(1, Math.max(0.3, pr.s))
                        ctx.fillStyle = Qt.rgba(c.r, c.g, c.b, alpha)
                        ctx.beginPath()
                        ctx.arc(cx + pr.x, cy + pr.y, size, 0, Math.PI * 2)
                        ctx.fill()
                    }
                }
            }
        }


        ColumnLayout {
            id: textColumn
            anchors.verticalCenter: parent.verticalCenter
            Layout.maximumWidth: root.width
            spacing: 6

            Text {
                id: titleText
                Layout.alignment: Qt.AlignHCenter
                Layout.maximumWidth: root.width
                text: MediaService.title || "Idle"
                color: ActiveTheme.colors["ACCENT_LOW"]
                font.pixelSize: 17
                font.bold: true
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
            }

            Text {
                id: albumText
                Layout.alignment: Qt.AlignHCenter
                text: MediaService.album || "No media playing"
                color: ActiveTheme.colors["FG_MUTED"]
                font.pixelSize: 13
                elide: Text.ElideRight
            }

            Text {
                id: artistText
                Layout.alignment: Qt.AlignHCenter
                text: MediaService.artist || "No media playing"
                color: ActiveTheme.colors["FG"]
                font.pixelSize: 13
                elide: Text.ElideRight
            }
        }
    }
}