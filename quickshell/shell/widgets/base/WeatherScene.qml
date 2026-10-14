/* quickshell/shell/widgets/base/WeatherScene.qml */


pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects

// Animated weather background. Layers are added on top of the sky in later steps.
Item {
    id: root

    property bool active: true
    readonly property bool live: active && visible

    // ── Inputs ───────────────────────────────────────────────────
    property int code: 0
    property bool isDay: true
    property real moonPhase: 0.5      // 0 new, 0.25 first quarter, 0.5 full, 0.75 last quarter
    property real cloudCover: 50      // 0..100
    property real windSpeed: 10       // km/h
    property real windDir: 270        // degrees the wind comes FROM

        // ── Time of day ──────────────────────────────────────────────
    property real sunriseMin: -1      // minutes since local midnight, -1 = unknown
    property real sunsetMin: -1
    property int utcOffset: 0         // seconds, from the API

    // Debug: plays a full day, 15 minutes per tick
    property bool debugSweep: false
    property real sweepMin: 0

    Timer {
        interval: 250
        repeat: true
        running: root.debugSweep && root.live
        onTriggered: root.sweepMin = (root.sweepMin + 15) % 1440
    }

    // Bumped every minute so the clock-based bindings re-evaluate
    property real _tick: 0
    Timer {
        interval: 60000
        repeat: true
        running: true
        onTriggered: root._tick++
    }

    readonly property real realMin: {
        _tick
        return ((Date.now() / 60000 + utcOffset / 60) % 1440 + 1440) % 1440
    }
    readonly property real clockMin: debugSweep ? sweepMin : realMin

    readonly property real riseMin: sunriseMin >= 0 ? sunriseMin : 450     // fallbacks only matter for the sweep
    readonly property real setMin:  sunsetMin  >= 0 ? sunsetMin  : 1170
    readonly property bool haveSun: debugSweep || sunriseMin >= 0

    readonly property real twilightMin: 40     // half-width of the night <-> day blend
    readonly property real glowMin: 55         // how far from sunrise / sunset the warm tint reaches

    function smoothen(t) {
        t = Math.max(0, Math.min(1, t))
        return t * t * (3 - 2 * t)
    }

    // 0 = night, 1 = day
    readonly property real daylight: {
        if (debugCycle) return _tests[_step][1] ? 1 : 0
        if (!haveSun) return isDay ? 1 : 0
        const up = smoothen((clockMin - (riseMin - twilightMin)) / (2 * twilightMin))
        const down = smoothen(((setMin + twilightMin) - clockMin) / (2 * twilightMin))
        return Math.min(up, down)
    }

    // 0..1, peaks at sunrise and sunset
    readonly property real twilightGlow: {
        if (debugCycle || !haveSun) return 0
        const d = Math.min(Math.abs(clockMin - riseMin), Math.abs(clockMin - setMin))
        return smoothen(1 - d / glowMin)
    }

    // How much of the warm tint survives each condition (clouds and rain mute it)
    readonly property var glowStrength: ({
        clear: 1, partly: 0.85, overcast: 0.35, fog: 0.3,
        drizzle: 0.3, rain: 0.2, snow: 0.35, storm: 0.1
    })

    property real cornerRadius: 12
    property bool expanded: false
    property real bodyX: expanded ? 0.20 : 0.80     // where the sun / moon sits, as a ratio
    property real bodyY: expanded ? 0.80 : 0.32

    Behavior on bodyX { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }
    Behavior on bodyY { NumberAnimation { duration: 350; easing.type: Easing.OutCubic } }

    // Clip everything to the rounded rectangle
    layer.enabled: true
    layer.effect: MultiEffect {
        maskEnabled: true
        maskSource: cornerMask
        maskThresholdMin: 0.5
        maskSpreadAtMin: 1.0
    }

    Item {
        id: cornerMask
        anchors.fill: parent
        visible: false
        layer.enabled: true

        Rectangle {
            anchors.fill: parent
            radius: root.cornerRadius
            color: "black"
        }
    }

    // ── Debug: cycles through test conditions every few seconds ──
    property bool debugCycle: false
    property int _step: 0
    // [code, isDay, moonPhase]
    readonly property var _tests: [
        [0, true, 0.5],  [0, false, 0.12], [0, false, 0.40], [0, false, 0.62],
        [0, false, 0.88], [2, true, 0.5],  [2, false, 0.30], [3, true, 0.5],
        [45, true, 0.5], [45, false, 0.5], [53, true, 0.5],  [63, false, 0.5],
        [73, true, 0.5], [95, false, 0.5]
    ]

    readonly property int effCode: debugCycle ? _tests[_step][0] : code
    readonly property bool effDay: daylight >= 0.5
    readonly property real effMoon: debugCycle ? _tests[_step][2] : moonPhase
    readonly property real effCover: debugCycle ? 50 : cloudCover
    readonly property real effWind: debugCycle ? 14 : windSpeed
    readonly property real effDir: debugCycle ? 270 : windDir

    Timer {
        interval: 2500
        repeat: true
        running: root.debugCycle && root.live
        onTriggered: root._step = (root._step + 1) % root._tests.length
    }

    // ── WMO code → one of a handful of conditions ────────────────
    readonly property string condition: {
        const c = effCode
        if (c <= 1) return "clear"
        if (c === 2) return "partly"
        if (c === 3) return "overcast"
        if (c === 45 || c === 48) return "fog"
        if (c >= 51 && c <= 57) return "drizzle"
        if ((c >= 61 && c <= 67) || (c >= 80 && c <= 82)) return "rain"
        if ((c >= 71 && c <= 77) || c === 85 || c === 86) return "snow"
        if (c >= 95) return "storm"
        return "overcast"
    }

    // ── Sky palettes: [top, bottom] per condition and time of day ─
    readonly property var palettes: ({
        clear:    { day: ["#24508f", "#5b95cf"], night: ["#060b1c", "#18284d"] },
        partly:   { day: ["#3d6a9e", "#7fa3c4"], night: ["#0a1126", "#1d2b4a"] },
        overcast: { day: ["#4f5b68", "#7a8794"], night: ["#161a22", "#2a313b"] },
        fog:      { day: ["#6f7a84", "#9aa4ac"], night: ["#222830", "#3a414a"] },
        drizzle:  { day: ["#4a5a6b", "#72869a"], night: ["#131923", "#222c3a"] },
        rain:     { day: ["#37444f", "#566877"], night: ["#0c1118", "#1a222c"] },
        snow:     { day: ["#6b7d92", "#b3c1d0"], night: ["#1a2231", "#33425a"] },
        storm:    { day: ["#262c36", "#454e5a"], night: ["#06080c", "#141820"] }
    })

    function mixc(a, b, t) {
        return Qt.rgba(a.r + (b.r - a.r) * t,
                       a.g + (b.g - a.g) * t,
                       a.b + (b.b - a.b) * t, 1)
    }

    function skyColor(i) {
        const p = palettes[condition]
        const base = mixc(Qt.color(p.night[i]), Qt.color(p.day[i]), daylight)
        // violet at the top, orange at the horizon
        const warm = Qt.color(i === 0 ? "#4a3f7a" : "#e8946a")
        const amount = twilightGlow * glowStrength[condition] * (i === 0 ? 0.35 : 0.6)
        return mixc(base, warm, amount)
    }

    property color topColor: skyColor(0)
    property color bottomColor: skyColor(1)

    Behavior on topColor    { ColorAnimation { duration: 900; easing.type: Easing.InOutQuad } }
    Behavior on bottomColor { ColorAnimation { duration: 900; easing.type: Easing.InOutQuad } }

    // ── Layer 1: sky ─────────────────────────────────────────────
    Rectangle {
        id: sky
        anchors.fill: parent
        radius: root.cornerRadius

        gradient: Gradient {
            GradientStop { position: 0.0; color: root.topColor }
            GradientStop { position: 1.0; color: root.bottomColor }
        }
    }

        // ── Layer 2: celestial ───────────────────────────────────────
    // How visible each body is, per condition (0 = hidden)
    readonly property real sunAlpha:  smoothen((daylight - 0.5) / 0.5)  * (({ clear: 1, partly: 0.85, fog: 0.25 })[condition] ?? 0)
    readonly property real moonAlpha: smoothen((0.5 - daylight) / 0.5)  * (({ clear: 1, partly: 0.80, fog: 0.25 })[condition] ?? 0)
    readonly property real starAlpha: (1 - daylight)                  * (({ clear: 1, partly: 0.50, fog: 0.15 })[condition] ?? 0)

    // Reference size: the disc is about 28% of the shorter side's 1/260 scale (see `body`)
    readonly property real bodyScale: Math.max(0.2, Math.min(width, height) / 260)

    // Stars: fixed pseudo-random layout, so they never jump around on re-evaluation
    readonly property var starData: {
        const out = []
        let seed = 42
        const rnd = () => { seed = (seed * 1664525 + 1013904223) % 4294967296; return seed / 4294967296 }
        for (let i = 0; i < 55; i++) {
            out.push({
                x: 0.03 + rnd() * 0.94,
                y: rnd() * 0.85,
                size: 1 + rnd() * 1.6,
                lo: 0.10 + rnd() * 0.25,
                hi: 0.55 + rnd() * 0.45,
                dur: 1200 + rnd() * 2800,
                warm: rnd() < 0.3
            })
        }
        return out
    }

    Item {
        id: stars
        anchors.fill: parent
        opacity: root.starAlpha
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 900; easing.type: Easing.InOutQuad } }

        Repeater {
            model: root.starData

            delegate: Rectangle {
                id: star
                required property var modelData

                x: modelData.x * stars.width
                y: modelData.y * stars.height
                width: modelData.size
                height: modelData.size
                radius: width / 2
                color: modelData.warm ? "#cfdcff" : "#ffffff"
                opacity: modelData.lo

                SequentialAnimation on opacity {
                    loops: Animation.Infinite
                    running: root.live && stars.visible
                    NumberAnimation { to: star.modelData.hi; duration: star.modelData.dur / 2; easing.type: Easing.InOutSine }
                    NumberAnimation { to: star.modelData.lo; duration: star.modelData.dur / 2; easing.type: Easing.InOutSine }
                }
            }
        }

        // Occasional shooting star
        Item {
            id: shoot
            property real sx: 0
            property real sy: 0
            width: 60; height: 2
            rotation: 28
            opacity: 0

            Rectangle {
                anchors.fill: parent
                radius: 1
                gradient: Gradient {
                    orientation: Gradient.Horizontal
                    GradientStop { position: 0.0; color: "#00ffffff" }
                    GradientStop { position: 1.0; color: "#ffffff" }
                }
            }

            ParallelAnimation {
                id: shootAnim
                NumberAnimation { target: shoot; property: "x"; from: shoot.sx; to: shoot.sx + 120; duration: 700; easing.type: Easing.OutQuad }
                NumberAnimation { target: shoot; property: "y"; from: shoot.sy; to: shoot.sy + 64;  duration: 700; easing.type: Easing.OutQuad }
                SequentialAnimation {
                    NumberAnimation { target: shoot; property: "opacity"; to: 0.9; duration: 100 }
                    NumberAnimation { target: shoot; property: "opacity"; to: 0;   duration: 600 }
                }
            }
        }

        Timer {
            interval: 9000
            repeat: true
            running: root.live && stars.visible && root.starAlpha > 0.6
            onTriggered: {
                shoot.sx = stars.width * (0.1 + Math.random() * 0.6)
                shoot.sy = stars.height * (0.05 + Math.random() * 0.25)
                shootAnim.restart()
                interval = 6000 + Math.random() * 12000
            }
        }
    }

    // Sun and moon live in a 160x160 box, positioned by ratio and scaled as a whole
    Item {
        id: body
        width: 160; height: 160
        x: root.width * root.bodyX - width / 2
        y: root.height * root.bodyY - height / 2
        scale: root.bodyScale
        transformOrigin: Item.Center

        // ── Sun ──
        Item {
            id: sun
            anchors.fill: parent
            opacity: root.sunAlpha
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 900; easing.type: Easing.InOutQuad } }

            // slowly rotating rays
            Canvas {
                id: rays
                anchors.fill: parent
                opacity: 0.35
                onPaint: {
                    const ctx = getContext("2d")
                    ctx.reset()
                    ctx.translate(80, 80)
                    ctx.strokeStyle = "#ffe08a"
                    ctx.lineWidth = 3
                    ctx.lineCap = "round"
                    for (let i = 0; i < 12; i++) {
                        const a = i * Math.PI / 6
                        ctx.beginPath()
                        ctx.moveTo(Math.cos(a) * 32, Math.sin(a) * 32)
                        ctx.lineTo(Math.cos(a) * 46, Math.sin(a) * 46)
                        ctx.stroke()
                    }
                }
                RotationAnimation on rotation {
                    from: 0; to: 360; duration: 90000
                    loops: Animation.Infinite
                    running: root.live && sun.visible
                }
            }

            // breathing glow + core
            Canvas {
                id: glow
                anchors.fill: parent
                onPaint: {
                    const ctx = getContext("2d")
                    ctx.reset()
                    const g = ctx.createRadialGradient(80, 80, 0, 80, 80, 80)
                    g.addColorStop(0.0, Qt.rgba(1.0, 0.88, 0.54, 0.85))
                    g.addColorStop(0.3, Qt.rgba(1.0, 0.70, 0.28, 0.30))
                    g.addColorStop(1.0, Qt.rgba(1.0, 0.70, 0.28, 0.0))
                    ctx.fillStyle = g
                    ctx.beginPath()
                    ctx.arc(80, 80, 80, 0, Math.PI * 2)
                    ctx.fill()

                    ctx.fillStyle = "#ffe08a"
                    ctx.beginPath()
                    ctx.arc(80, 80, 22, 0, Math.PI * 2)
                    ctx.fill()
                }

                SequentialAnimation on scale {
                    loops: Animation.Infinite
                    running: root.live && sun.visible
                    NumberAnimation { to: 1.08; duration: 3500; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1.0;  duration: 3500; easing.type: Easing.InOutSine }
                }
            }
        }

        // ── Moon ──
        Canvas {
            id: moon
            anchors.fill: parent
            opacity: root.moonAlpha
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 900; easing.type: Easing.InOutQuad } }

            property real phase: root.effMoon
            onPhaseChanged: requestPaint()

            onPaint: {
                const ctx = getContext("2d")
                ctx.reset()
                const R = 26

                // soft halo
                const g = ctx.createRadialGradient(80, 80, R * 0.8, 80, 80, 80)
                g.addColorStop(0.0, Qt.rgba(0.80, 0.86, 1.0, 0.22))
                g.addColorStop(1.0, Qt.rgba(0.80, 0.86, 1.0, 0.0))
                ctx.fillStyle = g
                ctx.beginPath()
                ctx.arc(80, 80, 80, 0, Math.PI * 2)
                ctx.fill()

                // unlit part of the disc (faint earthshine)
                ctx.fillStyle = Qt.rgba(0.91, 0.93, 0.99, 0.10)
                ctx.beginPath()
                ctx.arc(80, 80, R, 0, Math.PI * 2)
                ctx.fill()

                // lit part: right limb + terminator ellipse. Waning phases are mirrored.
                const p = phase
                const k = Math.cos(2 * Math.PI * p)          // +1 new ... -1 full
                const rx = Math.max(0.001, Math.abs(k) * R)

                ctx.save()
                ctx.translate(80, 80)
                if (p > 0.5) ctx.scale(-1, 1)

                ctx.fillStyle = "#e8eefc"
                ctx.beginPath()
                ctx.arc(0, 0, R, -Math.PI / 2, Math.PI / 2, false)   // right limb, top to bottom

                ctx.save()
                ctx.scale(rx / R, 1)                                  // squash the circle into the terminator ellipse
                if (k > 0) ctx.arc(0, 0, R, Math.PI / 2, -Math.PI / 2, true)    // crescent: terminator bulges right
                else       ctx.arc(0, 0, R, Math.PI / 2, -Math.PI / 2, false)   // gibbous:  terminator bulges left
                ctx.restore()

                ctx.closePath()
                ctx.fill()
                ctx.restore()
            }
        }
    }

        // ── Layer 3: clouds ──────────────────────────────────────────
    // How many of the 12 pooled clouds are shown
    readonly property int cloudCount: {
        const f = Math.max(0, Math.min(1, effCover / 100))
        switch (condition) {
        case "clear":    return Math.round(f * 3)
        case "partly":   return 4 + Math.round(f * 3)
        case "fog":      return 3
        case "drizzle":  return 10
        case "snow":     return 11
        default:         return 12      // overcast, rain, storm
        }
    }

    readonly property var cloudTints: ({
        clear:    { day: "#e6ecf3", night: "#3a4452" },
        partly:   { day: "#e6ecf3", night: "#3a4452" },
        overcast: { day: "#b9c3ce", night: "#2c3440" },
        fog:      { day: "#dfe5ea", night: "#4a525c" },
        drizzle:  { day: "#a3afbc", night: "#262e3a" },
        rain:     { day: "#8794a2", night: "#1f2630" },
        snow:     { day: "#d5dde6", night: "#4a566a" },
        storm:    { day: "#5b6572", night: "#161b24" }
    })

    property color cloudColor: {
        const t = cloudTints[condition]
        const base = mixc(Qt.color(t.night), Qt.color(t.day), daylight)
        return mixc(base, Qt.color("#ffb98a"), twilightGlow * glowStrength[condition] * 0.55)
    }
    Behavior on cloudColor { ColorAnimation { duration: 900; easing.type: Easing.InOutQuad } }

    // Wind FROM `effDir` blows TOWARD effDir + 180, so the screen-x component is -sin(effDir)
    readonly property real driftX: -Math.sin(effDir * Math.PI / 180)
    readonly property real driftSign: driftX >= 0 ? 1 : -1
    // Time for a mid-layer cloud to cross the scene; a north/south wind still creeps along
    readonly property real traverseMs: Math.max(20000, 240000 / (0.6 + effWind / 8))
                                       / Math.max(0.35, Math.abs(driftX))

        // ── Precipitation helpers ────────────────────────────────────
    readonly property string precipKind: {
        if (condition === "snow") return "snow"
        if (condition === "drizzle" || condition === "rain" || condition === "storm") return "rain"
        return ""
    }

    readonly property int dropCount: {
        switch (condition) {
        case "drizzle": return 25
        case "rain":    return 55
        case "storm":   return 80
        case "snow":    return 45
        }
        return 0
    }

    // Time for a drop to fall from top to bottom
    readonly property real rainMs: condition === "storm" ? 480 : (condition === "drizzle" ? 1100 : 650)

    // Rain slant in degrees: positive = falls toward the right. Follows the wind.
    readonly property real slantDeg: driftX * Math.min(effWind, 40) / 40 * 25

    // Particle size factor (never smaller than 0.6, so the collapsed view stays visible)
    readonly property real ps: Math.max(0.6, bodyScale)

    // Fixed pseudo-random pool shared by rain and snow (80 entries)
    readonly property var dropData: {
        const out = []
        let seed = 99
        const rnd = () => { seed = (seed * 1664525 + 1013904223) % 4294967296; return seed / 4294967296 }
        for (let i = 0; i < 80; i++) {
            out.push({
                x: rnd(),
                offset: rnd(),
                len: rnd(),
                alpha: rnd(),
                size: rnd(),
                speed: 0.8 + rnd() * 0.4,
                amp: 3 + rnd() * 7,
                freq: 2 + rnd() * 2,
                phase: rnd() * Math.PI * 2
            })
        }
        return out
    }

    // Fixed pseudo-random pool: layer 0 = far, 1 = mid, 2 = near
    readonly property var cloudData: {
        const out = []
        let seed = 7
        const rnd = () => { seed = (seed * 1664525 + 1013904223) % 4294967296; return seed / 4294967296 }
        const yBase = [0.04, 0.14, 0.26]
        const ySpan = [0.22, 0.26, 0.28]
        const sizes = [0.34, 0.46, 0.62]
        const alphas = [0.45, 0.70, 0.85]
        const speeds = [1.7, 1.0, 0.65]      // duration multiplier: far = slow
        for (let i = 0; i < 12; i++) {
            const l = i % 3
            out.push({
                y: yBase[l] + rnd() * ySpan[l],
                size: sizes[l] * (0.85 + rnd() * 0.3),
                offset: (i * 0.618) % 1,      // golden-ratio spread along the path
                alpha: alphas[l],
                speed: speeds[l]
            })
        }
        return out
    }

    Item {
        id: clouds
        anchors.fill: parent
        clip: true

        Repeater {
            model: root.cloudData

            delegate: Canvas {
                id: cloud
                required property var modelData
                required property int index

                readonly property bool active: index < root.cloudCount
                readonly property real k: root.width * modelData.size / 200   // scale from the 200x90 drawing
                property real progress: 0
                property color tint: root.cloudColor

                width: 200
                height: 90
                scale: k
                transformOrigin: Item.TopLeft
                x: -width * k + ((modelData.offset + progress) % 1) * (root.width + width * k)
                y: modelData.y * root.height

                opacity: active ? modelData.alpha * (root.condition === "fog" ? 0.5 : 1) : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 900; easing.type: Easing.InOutQuad } }

                onTintChanged: requestPaint()

                onPaint: {
                    const ctx = getContext("2d")
                    ctx.reset()
                    const t = tint
                    // [x, y, radius] of the soft puffs that make up one cloud
                    const puffs = [[50, 60, 28], [82, 46, 36], [124, 52, 34], [156, 62, 26],
                                   [100, 68, 30], [68, 70, 22], [136, 70, 22]]
                    for (const p of puffs) {
                        const g = ctx.createRadialGradient(p[0], p[1], 0, p[0], p[1], p[2])
                        g.addColorStop(0.0, Qt.rgba(t.r, t.g, t.b, 0.95))
                        g.addColorStop(0.55, Qt.rgba(t.r, t.g, t.b, 0.70))
                        g.addColorStop(1.0, Qt.rgba(t.r, t.g, t.b, 0.0))
                        ctx.fillStyle = g
                        ctx.beginPath()
                        ctx.arc(p[0], p[1], p[2], 0, Math.PI * 2)
                        ctx.fill()
                    }
                }

                NumberAnimation on progress {
                    from: root.driftSign > 0 ? 0 : 1
                    to: root.driftSign > 0 ? 1 : 0
                    duration: root.traverseMs * cloud.modelData.speed
                    loops: Animation.Infinite
                    running: root.live && cloud.visible
                }
            }
        }
    }

        // ── Layer 4: fog ─────────────────────────────────────────────
    Item {
        id: fogLayer
        anchors.fill: parent
        clip: true
        opacity: root.condition === "fog" ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 1200; easing.type: Easing.InOutQuad } }

        Repeater {
            model: [
                { y: 0.15, h: 0.34, alpha: 0.22, dur: 38000, shift: 0.00 },
                { y: 0.38, h: 0.30, alpha: 0.30, dur: 52000, shift: 0.35 },
                { y: 0.58, h: 0.34, alpha: 0.26, dur: 44000, shift: 0.70 },
                { y: 0.76, h: 0.32, alpha: 0.34, dur: 60000, shift: 0.15 }
            ]

            delegate: Rectangle {
                id: band
                required property var modelData

                // wider than the scene, so it can drift sideways without showing an edge
                readonly property real travel: root.width * 0.4
                property real phase: modelData.shift

                width: root.width * 1.4
                height: root.height * modelData.h
                x: -travel / 2 + Math.sin(phase * 2 * Math.PI) * travel / 2 - root.width * 0.0
                y: modelData.y * root.height - height / 2
                opacity: modelData.alpha

                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#00dfe5ea" }
                    GradientStop { position: 0.5; color: "#ffdfe5ea" }
                    GradientStop { position: 1.0; color: "#00dfe5ea" }
                }

                NumberAnimation on phase {
                    from: band.modelData.shift
                    to: band.modelData.shift + 1
                    duration: band.modelData.dur
                    loops: Animation.Infinite
                    running: root.live && fogLayer.visible
                }
            }
        }
    }

    // ── Layer 5: precipitation ───────────────────────────────────
    Item {
        id: precip
        anchors.fill: parent
        clip: true

        // Rain / drizzle / storm: slanted streaks
        Repeater {
            model: root.dropData

            delegate: Rectangle {
                id: drop
                required property var modelData
                required property int index

                readonly property bool active: root.precipKind === "rain" && index < root.dropCount
                property real progress: 0
                readonly property real p: (progress + modelData.offset) % 1
                readonly property real travel: root.height * Math.tan(root.slantDeg * Math.PI / 180)

                width: Math.max(1, 1.2 * root.ps)
                height: (9 + modelData.len * 9) * root.ps
                radius: width / 2
                color: "#a9c7e8"
                opacity: active ? 0.18 + 0.32 * modelData.alpha : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 700 } }

                // a vertical bar tilted counter-clockwise leans like a drop falling to the right
                rotation: -root.slantDeg
                transformOrigin: Item.Center

                x: modelData.x * root.width + (p - 0.5) * travel
                y: -height + p * (root.height + height)

                NumberAnimation on progress {
                    from: 0
                    to: 1
                    duration: root.rainMs * drop.modelData.speed
                    loops: Animation.Infinite
                    running: root.live && drop.active
                }
            }
        }

        // Snow: round flakes that sway while they fall
        Repeater {
            model: root.dropData

            delegate: Rectangle {
                id: flake
                required property var modelData
                required property int index

                readonly property bool active: root.precipKind === "snow" && index < root.dropCount
                property real progress: 0
                readonly property real p: (progress + modelData.offset) % 1
                readonly property real windPush: root.driftX * Math.min(root.effWind, 30) / 30 * root.width * 0.15

                width: (2 + modelData.size * 3) * root.ps
                height: width
                radius: width / 2
                color: "#ffffff"
                opacity: active ? 0.45 + 0.5 * modelData.alpha : 0
                visible: opacity > 0
                Behavior on opacity { NumberAnimation { duration: 700 } }

                x: modelData.x * root.width
                   + Math.sin(p * 2 * Math.PI * modelData.freq + modelData.phase) * modelData.amp * root.ps
                   + (p - 0.5) * windPush
                y: -height + p * (root.height + height)

                NumberAnimation on progress {
                    from: 0
                    to: 1
                    // big flakes fall faster than small ones
                    duration: (11000 - flake.modelData.size * 5000) * flake.modelData.speed
                    loops: Animation.Infinite
                    running: root.live && flake.active
                }
            }
        }
    }

    // ── Scrim: keeps text readable on bright skies ───────────────
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Horizontal
            // collapsed: dark on the text side (left), clear on the sun side
            // expanded: an even, light veil
            GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, root.expanded ? 0.22 : 0.42) }
            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, root.expanded ? 0.22 : 0.06) }
        }
    }

    // ── Layer 6: lightning ───────────────────────────────────────
    property real strikeX: 0.5        // horizontal position of the next bolt, 0..1
    property bool strikeBolt: true    // whether this strike also draws a bolt

    function strike() {
        strikeX = 0.15 + Math.random() * 0.7
        strikeBolt = Math.random() < 0.6
        bolt.requestPaint()
        strikeAnim.restart()
    }

    // Bolt: drawn in a fixed 80x200 box, scaled to 80% of the scene height
    Canvas {
        id: bolt
        readonly property real k: root.height * 0.8 / 200

        width: 80
        height: 200
        scale: k
        transformOrigin: Item.TopLeft
        x: root.strikeX * root.width - 40 * k
        y: 0
        opacity: 0
        visible: opacity > 0

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()

            // main path: 10 jagged segments from the top downward
            const pts = [[40, 0]]
            let x = 40
            for (let i = 1; i <= 10; i++) {
                x += (Math.random() - 0.5) * 30
                x = Math.max(8, Math.min(72, x))
                pts.push([x, i * 18])
            }

            // a short branch that splits off the middle of the main path
            const bi = 4 + Math.floor(Math.random() * 3)
            const dir = Math.random() < 0.5 ? -1 : 1
            const branch = [pts[bi]]
            let bx = pts[bi][0]
            for (let j = 1; j <= 3; j++) {
                bx += dir * (6 + Math.random() * 10)
                bx = Math.max(4, Math.min(76, bx))
                branch.push([bx, pts[bi][1] + j * 14])
            }

            ctx.lineJoin = "round"
            ctx.lineCap = "round"

            const trace = (path) => {
                ctx.beginPath()
                ctx.moveTo(path[0][0], path[0][1])
                for (let i = 1; i < path.length; i++) ctx.lineTo(path[i][0], path[i][1])
                ctx.stroke()
            }

            // wide soft glow, then a thin bright core
            ctx.strokeStyle = "rgba(219, 230, 255, 0.28)"
            ctx.lineWidth = 7
            trace(pts); trace(branch)

            ctx.strokeStyle = "#dbe6ff"
            ctx.lineWidth = 2
            trace(pts)
            ctx.lineWidth = 1.2
            trace(branch)
        }
    }

    // Sky flash: bright at the top, fading toward the bottom
    Rectangle {
        id: flash
        anchors.fill: parent
        radius: root.cornerRadius
        opacity: 0
        visible: opacity > 0

        gradient: Gradient {
            GradientStop { position: 0.0; color: "#dbe6ff" }
            GradientStop { position: 1.0; color: "#00dbe6ff" }
        }
    }

    ParallelAnimation {
        id: strikeAnim

        // double flash: hit, dip, stronger hit, slow fade
        SequentialAnimation {
            NumberAnimation { target: flash; property: "opacity"; to: 0.55; duration: 40 }
            NumberAnimation { target: flash; property: "opacity"; to: 0.08; duration: 90 }
            NumberAnimation { target: flash; property: "opacity"; to: 0.75; duration: 50 }
            NumberAnimation { target: flash; property: "opacity"; to: 0.0;  duration: 450; easing.type: Easing.OutQuad }
        }

        // the bolt shows for the first part only
        SequentialAnimation {
            NumberAnimation { target: bolt; property: "opacity"; to: root.strikeBolt ? 1 : 0; duration: 30 }
            PauseAnimation { duration: 170 }
            NumberAnimation { target: bolt; property: "opacity"; to: 0; duration: 280; easing.type: Easing.OutQuad }
        }
    }

    Timer {
        id: stormTimer
        interval: 900
        repeat: true
        running: root.live && root.condition === "storm"

        // the first strike comes shortly after the storm starts
        onRunningChanged: if (running) interval = 900

        onTriggered: {
            root.strike()
            interval = 3500 + Math.random() * 8000
        }
    }

    // Debug label, only visible while cycling
    Text {
        visible: root.debugCycle || root.debugSweep
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 6
        color: "white"
        font.pixelSize: 10
        text: root.condition
              + (root.debugSweep
                 ? " · " + String(Math.floor(root.clockMin / 60)).padStart(2, "0") + ":"
                   + String(Math.floor(root.clockMin % 60)).padStart(2, "0")
                 : "")
              + " · d=" + root.daylight.toFixed(2)
    }
}
