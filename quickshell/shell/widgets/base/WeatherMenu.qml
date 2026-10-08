/* quickshell/shell/widgets/base/WeatherMenu.qml */


pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import ElysianShell.Themes
import ElysianShell.Services

// Weather block content.
//   collapsed (about 222 x 105 at the 768px design width): compact summary
//   expanded  (about 702 x 312): full panel, with a scrollable "more details" area
Item {
    id: root

    property bool expanded: false
    signal toggleRequested()

    // 1.0 at the expanded block size (702 wide), everything in the full view scales from it
    readonly property real s: Math.max(0.2, width / 702)
    // 1.0 at the collapsed block size (222 wide)
    readonly property real c: Math.max(0.2, width / 222)

    readonly property bool ready: WeatherService.loaded

    // ── Helpers ──────────────────────────────────────────────────
    function clr(name) { return ActiveTheme.colors[name] }

    function cur(key, fallback) {
        const v = WeatherService.current[key]
        return (v === undefined || v === null) ? fallback : v
    }

    function dly(key, i, fallback) {
        const a = WeatherService.daily[key]
        return (a && a[i] !== undefined && a[i] !== null) ? a[i] : fallback
    }

    function clamp01(v) { return Math.max(0, Math.min(1, v)) }

    function hhmm(iso) { return iso ? String(iso).slice(11, 16) : "—" }

    function compassName(deg) {
        const names = ["N", "NE", "E", "SE", "S", "SW", "W", "NW"]
        return names[Math.round(deg / 45) % 8]
    }

    function uvLabel(v) {
        if (v < 3) return "low"
        if (v < 6) return "moderate"
        if (v < 8) return "high"
        if (v < 11) return "very high"
        return "extreme"
    }

    function visibilityLabel(km) {
        if (km >= 20) return "Excellent"
        if (km >= 10) return "Good"
        if (km >= 4) return "Moderate"
        return "Poor"
    }

    function pressureLabel(hpa) {
        if (hpa >= 1020) return "High"
        if (hpa >= 1010) return "Normal"
        return "Low"
    }

    function moonName(p) {
        if (p < 0.03 || p > 0.97) return "New moon"
        if (p < 0.22) return "Waxing crescent"
        if (p < 0.28) return "First quarter"
        if (p < 0.47) return "Waxing gibbous"
        if (p < 0.53) return "Full moon"
        if (p < 0.72) return "Waning gibbous"
        if (p < 0.78) return "Last quarter"
        return "Waning crescent"
    }

    function duration(sec) {
        const h = Math.floor(sec / 3600)
        const m = Math.round((sec % 3600) / 60)
        return h + " h " + m + " m"
    }

    // ── Models ───────────────────────────────────────────────────
    readonly property var hourModel: {
        if (!WeatherService.loaded) return []
        const h = WeatherService.hourly
        const out = []
        for (let n = 0; n < 6; n++) {
            const i = WeatherService.hourIndex + n
            if (i >= h.time.length) break
            out.push({
                label: n === 0 ? "Now" : h.time[i].slice(11, 16),
                temp: Math.round(h.temperature_2m[i]),
                code: h.weather_code[i],
                day: h.is_day[i] === 1
            })
        }
        return out
    }

    readonly property var dayModel: {
        if (!WeatherService.loaded) return []
        const d = WeatherService.daily
        const n = d.time.length
        let lo = 1e9
        let hi = -1e9
        for (let i = 0; i < n; i++) {
            lo = Math.min(lo, d.temperature_2m_min[i])
            hi = Math.max(hi, d.temperature_2m_max[i])
        }
        const span = Math.max(1, hi - lo)
        const out = []
        for (let i = 0; i < n; i++) {
            const mn = d.temperature_2m_min[i]
            const mx = d.temperature_2m_max[i]
            out.push({
                name: i === 0 ? "Today" : Qt.formatDate(new Date(d.time[i] + "T12:00:00"), "ddd"),
                min: Math.round(mn),
                max: Math.round(mx),
                from: (mn - lo) / span,
                to: (mx - lo) / span
            })
        }
        return out
    }

    // ── Small building blocks ────────────────────────────────────
    component T: Text {
        property real s: 1
        property real fs: 10
        color: ActiveTheme.colors["FG"]
        font.pixelSize: Math.max(1, Math.round(fs * s))
    }

    // Small spaced-out caption
    component Cap: Text {
        property real s: 1
        property real fs: 9
        color: ActiveTheme.colors["FG_MUTED"]
        font.pixelSize: Math.max(1, Math.round(fs * s))
        font.letterSpacing: 0.8 * s
    }

    // Value tile: caption, big value + unit, subtitle. Bars / compass are added as children.
    component Tile: Rectangle {
        id: tile
        property real s: 1
        property string label: ""
        property string value: ""
        property string unit: ""
        property string sub: ""

        color: ActiveTheme.colors["BG_ACTIVE"]
        radius: 10 * s

        Cap { x: 9 * tile.s; y: 8 * tile.s; s: tile.s; text: tile.label }

        T {
            id: val
            x: 9 * tile.s
            y: 20 * tile.s
            s: tile.s
            fs: 17
            font.weight: Font.Light
            text: tile.value
        }

        T {
            anchors.left: val.right
            anchors.leftMargin: 3 * tile.s
            anchors.baseline: val.baseline
            s: tile.s
            fs: 9
            color: ActiveTheme.colors["FG_MUTED"]
            text: tile.unit
        }

        T {
            x: 9 * tile.s
            width: tile.width - 18 * tile.s
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 6 * tile.s
            s: tile.s
            fs: 9
            elide: Text.ElideRight
            color: ActiveTheme.colors["FG_MUTED"]
            text: tile.sub
        }
    }

    // Filled progress bar for a tile
    component Bar: Rectangle {
        property real s: 1
        property real ratio: 0
        property color fill: ActiveTheme.colors["ACCENT"]

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 9 * s
        anchors.rightMargin: 9 * s
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 20 * s
        height: Math.max(2, 4 * s)
        radius: height / 2
        color: ActiveTheme.colors["DARK6"]

        Rectangle {
            width: parent.width * Math.max(0, Math.min(1, parent.ratio))
            height: parent.height
            radius: parent.radius
            color: parent.fill
        }
    }

    // Gradient scale with a marker (UV, pressure)
    component ScaleBar: Rectangle {
        property real s: 1
        property real ratio: 0
        property color colorA: ActiveTheme.colors["SUCCESS"]
        property color colorB: ActiveTheme.colors["WARNING"]
        property color colorC: ActiveTheme.colors["ERROR_LOW"]

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 9 * s
        anchors.rightMargin: 9 * s
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 20 * s
        height: Math.max(2, 4 * s)
        radius: height / 2

        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: colorA }
            GradientStop { position: 0.5; color: colorB }
            GradientStop { position: 1.0; color: colorC }
        }

        Rectangle {
            x: parent.width * Math.max(0, Math.min(1, parent.ratio)) - width / 2
            y: -2 * parent.s
            width: Math.max(2, 3 * parent.s)
            height: parent.height + 4 * parent.s
            radius: width / 2
            color: ActiveTheme.colors["FG"]
        }
    }

    // Wind compass; `degrees` is where the wind comes FROM, the arrow points where it blows to
    component Compass: Canvas {
        property real degrees: 0
        property color ring: ActiveTheme.colors["DARK6"]
        property color arrow: ActiveTheme.colors["WARNING"]

        onDegreesChanged: requestPaint()
        onRingChanged: requestPaint()
        onArrowChanged: requestPaint()
        onWidthChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            if (width <= 0) return
            const cx = width / 2
            const r = cx - 1.5
            ctx.strokeStyle = ring
            ctx.lineWidth = 1.5
            ctx.beginPath()
            ctx.arc(cx, cx, r, 0, Math.PI * 2)
            ctx.stroke()
            ctx.save()
            ctx.translate(cx, cx)
            ctx.rotate((degrees + 180) * Math.PI / 180)
            ctx.fillStyle = arrow
            ctx.beginPath()
            ctx.moveTo(0, -r * 0.65)
            ctx.lineTo(r * 0.24, r * 0.32)
            ctx.lineTo(0, r * 0.12)
            ctx.lineTo(-r * 0.24, r * 0.32)
            ctx.closePath()
            ctx.fill()
            ctx.restore()
        }
    }

    // Card with a caption; children are stacked in a column
    component Card: Rectangle {
        id: card
        property real s: 1
        property string title: ""
        default property alias rows: list.data

        color: ActiveTheme.colors["BG_ACTIVE"]
        radius: 10 * s

        readonly property real naturalHeight: list.y + list.height + 12 * s
        height: naturalHeight

        Cap { x: 12 * card.s; y: 10 * card.s; s: card.s; text: card.title }

        Column {
            id: list
            x: 12 * card.s
            y: 28 * card.s
            width: card.width - 24 * card.s
            spacing: 7 * card.s
        }
    }

    // label ........ value
    component KV: Item {
        property real s: 1
        property string k: ""
        property string v: ""

        width: parent.width
        height: 14 * s

        T { s: parent.s; fs: 10; color: ActiveTheme.colors["FG_MUTED"]; anchors.verticalCenter: parent.verticalCenter; text: parent.k }
        T { s: parent.s; fs: 10; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; text: parent.v }
    }

    // label ..bar.. value
    component BarKV: Item {
        property real s: 1
        property string k: ""
        property string v: ""
        property real ratio: 0
        property color fill: ActiveTheme.colors["WARNING"]

        width: parent.width
        height: 14 * s

        T { s: parent.s; fs: 10; color: ActiveTheme.colors["FG_MUTED"]; anchors.verticalCenter: parent.verticalCenter; text: parent.k }

        Rectangle {
            x: 38 * parent.s
            width: parent.width - 38 * parent.s - 36 * parent.s
            height: Math.max(2, 4 * parent.s)
            radius: height / 2
            anchors.verticalCenter: parent.verticalCenter
            color: ActiveTheme.colors["DARK6"]

            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, parent.parent.ratio))
                height: parent.height
                radius: parent.radius
                color: parent.parent.fill
            }
        }

        T { s: parent.s; fs: 10; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; text: parent.v }
    }

    component WeatherIcon: Canvas {
        property int code: 0
        property bool day: true

        property color sunColor: ActiveTheme.colors["WARNING"]
        property color moonColor: ActiveTheme.colors["ACCENT_MUTED"]
        property color cloudColor: ActiveTheme.colors["FG_MUTED"]
        property color rainColor: ActiveTheme.colors["SECONDARY"]
        property color snowColor: ActiveTheme.colors["FG"]
        property color boltColor: ActiveTheme.colors["WARNING_LOW"]

        implicitWidth: 24
        implicitHeight: 24

        onCodeChanged: requestPaint()
        onDayChanged: requestPaint()
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onSunColorChanged: requestPaint()
        onMoonColorChanged: requestPaint()
        onCloudColorChanged: requestPaint()
        onRainColorChanged: requestPaint()
        onSnowColorChanged: requestPaint()
        onBoltColorChanged: requestPaint()

        function precipKind() {
            if (code === 45 || code === 48) return "fog"
            if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82)) return "rain"
            if ((code >= 71 && code <= 77) || code === 85 || code === 86) return "snow"
            if (code >= 95) return "storm"
            return ""
        }

        function drawSun(ctx, cx, cy, r) {
            ctx.fillStyle = sunColor
            ctx.strokeStyle = sunColor
            ctx.lineWidth = Math.max(1, width * 0.06)
            ctx.lineCap = "round"
            ctx.beginPath()
            ctx.arc(cx, cy, r * 0.62, 0, Math.PI * 2)
            ctx.fill()
            for (let i = 0; i < 8; i++) {
                const a = i * Math.PI / 4
                ctx.beginPath()
                ctx.moveTo(cx + Math.cos(a) * r * 0.88, cy + Math.sin(a) * r * 0.88)
                ctx.lineTo(cx + Math.cos(a) * r * 1.2, cy + Math.sin(a) * r * 1.2)
                ctx.stroke()
            }
        }

        function drawMoon(ctx, cx, cy, r) {
            ctx.fillStyle = moonColor
            ctx.beginPath()
            ctx.arc(cx, cy, r, 0, Math.PI * 2)
            ctx.fill()
            // carve the crescent out of the disc
            ctx.globalCompositeOperation = "destination-out"
            ctx.beginPath()
            ctx.arc(cx + r * 0.55, cy - r * 0.4, r * 0.85, 0, Math.PI * 2)
            ctx.fill()
            ctx.globalCompositeOperation = "source-over"
        }

        function drawCloud(ctx, x, y, w) {
            const yb = y + w * 0.55
            ctx.fillStyle = cloudColor
            ctx.beginPath()
            ctx.arc(x + w * 0.25, yb - w * 0.14, w * 0.14, 0, Math.PI * 2)
            ctx.fill()
            ctx.beginPath()
            ctx.arc(x + w * 0.47, yb - w * 0.24, w * 0.22, 0, Math.PI * 2)
            ctx.fill()
            ctx.beginPath()
            ctx.arc(x + w * 0.72, yb - w * 0.15, w * 0.15, 0, Math.PI * 2)
            ctx.fill()
            ctx.fillRect(x + w * 0.25, yb - w * 0.14, w * 0.47, w * 0.14)
        }

        function drawPrecip(ctx, kind, w) {
            const y0 = w * 0.66
            ctx.lineCap = "round"
            ctx.lineWidth = Math.max(1, w * 0.07)

            if (kind === "rain") {
                ctx.strokeStyle = rainColor
                for (let i = 0; i < 3; i++) {
                    const x = w * (0.32 + i * 0.2)
                    ctx.beginPath()
                    ctx.moveTo(x, y0)
                    ctx.lineTo(x - w * 0.06, y0 + w * 0.2)
                    ctx.stroke()
                }
            } else if (kind === "snow") {
                ctx.fillStyle = snowColor
                for (let i = 0; i < 3; i++) {
                    ctx.beginPath()
                    ctx.arc(w * (0.32 + i * 0.2), y0 + w * 0.12 + (i % 2) * w * 0.1, w * 0.05, 0, Math.PI * 2)
                    ctx.fill()
                }
            } else if (kind === "fog") {
                ctx.strokeStyle = cloudColor
                for (let i = 0; i < 2; i++) {
                    ctx.beginPath()
                    ctx.moveTo(w * 0.2, y0 + i * w * 0.15)
                    ctx.lineTo(w * 0.8, y0 + i * w * 0.15)
                    ctx.stroke()
                }
            } else if (kind === "storm") {
                ctx.fillStyle = boltColor
                ctx.beginPath()
                ctx.moveTo(w * 0.54, y0 - w * 0.04)
                ctx.lineTo(w * 0.38, y0 + w * 0.14)
                ctx.lineTo(w * 0.5, y0 + w * 0.14)
                ctx.lineTo(w * 0.44, y0 + w * 0.3)
                ctx.lineTo(w * 0.66, y0 + w * 0.08)
                ctx.lineTo(w * 0.54, y0 + w * 0.08)
                ctx.closePath()
                ctx.fill()
            }
        }

        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            const w = width
            if (w <= 0) return

            const kind = precipKind()
            const partly = code === 2

            if (code <= 2) {
                const cx = partly ? w * 0.38 : w * 0.5
                const cy = partly ? w * 0.38 : w * 0.5
                const r = partly ? w * 0.24 : w * 0.28
                if (day) drawSun(ctx, cx, cy, r)
                else drawMoon(ctx, cx, cy, r * 1.15)
            }

            if (code === 2) {
                drawCloud(ctx, w * 0.30, w * 0.42, w * 0.66)
            } else if (code >= 3) {
                drawCloud(ctx, w * 0.10, kind === "" ? w * 0.28 : w * 0.12, w * 0.80)
            }

            if (kind !== "") drawPrecip(ctx, kind, w)
        }
    }

    // ═════════════════════════════════════════════════════════════
    //  COLLAPSED
    // ═════════════════════════════════════════════════════════════
    Item {
        id: compact
        anchors.fill: parent
        opacity: root.expanded ? 0 : 1
        visible: opacity > 0

        Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

        T {
            id: cTemp
            x: 13 * root.c
            y: 7 * root.c
            s: root.c
            fs: 36
            font.weight: Font.Light
            text: root.ready ? Math.round(WeatherService.temperature) + "°" : "--"
        }

        WeatherIcon {
            anchors.right: parent.right
            anchors.rightMargin: 12 * root.c
            y: 11 * root.c
            width: 32 * root.c
            height: 32 * root.c
            code: root.ready ? WeatherService.weatherCode : 0
            day: WeatherService.isDay
        }

        T {
            x: 14 * root.c
            width: 150 * root.c
            anchors.top: cTemp.bottom
            anchors.topMargin: -3 * root.c
            s: root.c
            fs: 10
            elide: Text.ElideRight
            color: ActiveTheme.colors["FG_MUTED"]
            text: root.ready
                  ? WeatherService.description + " · feels " + Math.round(WeatherService.feelsLike) + "°"
                  : (WeatherService.error !== "" ? WeatherService.error : "Loading…")
        }

        Row {
            x: 14 * root.c
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 9 * root.c
            spacing: 12 * root.c
            visible: root.ready

            T {
                s: root.c; fs: 10
                text: Math.round(root.dly("temperature_2m_max", 0, 0)) + "° / " + Math.round(root.dly("temperature_2m_min", 0, 0)) + "°"
            }
            T { s: root.c; fs: 10; color: ActiveTheme.colors["ACCENT_MUTED"]; text: WeatherService.humidity + " %" }
            T { s: root.c; fs: 10; color: ActiveTheme.colors["WARNING"]; text: WeatherService.windSpeed.toFixed(1) + " km/h" }
        }

        MouseArea {
            anchors.fill: parent
            enabled: !root.expanded
            cursorShape: Qt.PointingHandCursor
            onClicked: root.toggleRequested()
        }
    }

    // ═════════════════════════════════════════════════════════════
    //  EXPANDED
    // ═════════════════════════════════════════════════════════════
    Item {
        id: full
        anchors.fill: parent
        opacity: root.expanded ? 1 : 0
        visible: opacity > 0

        Behavior on opacity { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        // ── Header (fixed, does not scroll) ─────────────────────
        Item {
            id: header
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.leftMargin: 20 * root.s
            anchors.rightMargin: 14 * root.s
            anchors.topMargin: 16 * root.s
            height: 28 * root.s

            T {
                id: title
                anchors.verticalCenter: parent.verticalCenter
                s: root.s; fs: 15
                font.bold: true
                text: "Weather"
            }

            T {
                anchors.left: title.right
                anchors.leftMargin: 8 * root.s
                anchors.baseline: title.baseline
                s: root.s; fs: 11
                color: ActiveTheme.colors["FG_MUTED"]
                text: WeatherService.city
            }

            MouseArea {
                anchors.left: title.left
                anchors.verticalCenter: title.verticalCenter
                width: title.width + 120 * root.s
                height: parent.height
                cursorShape: Qt.PointingHandCursor
                onClicked: root.toggleRequested()
            }

            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8 * root.s

                T {
                    anchors.verticalCenter: parent.verticalCenter
                    s: root.s; fs: 10
                    color: WeatherService.error !== "" ? ActiveTheme.colors["ERROR_LOW"] : ActiveTheme.colors["FG_MUTED"]
                    text: WeatherService.error !== "" ? "offline"
                          : (root.ready ? "updated " + Qt.formatTime(WeatherService.lastUpdated, "HH:mm") : "loading…")
                }

                // Refresh button: same hover treatment as the notification log's clear button
                Rectangle {
                    width: Math.round(18 * root.s)
                    height: Math.round(18 * root.s)
                    radius: Math.round(4 * root.s)
                    color: refreshArea.containsMouse ? ActiveTheme.colors["ACCENT_LOW"] : "transparent"

                    Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.InOutCubic } }

                    Text {
                        anchors.centerIn: parent
                        text: "󰑐"   // nf-md-refresh
                        font.pixelSize: Math.max(1, Math.round(13 * root.s))
                        color: refreshArea.containsMouse ? ActiveTheme.colors["BG"] : ActiveTheme.colors["FG_GHOST"]

                        Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.InOutCubic } }
                    }

                    MouseArea {
                        id: refreshArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: WeatherService.refresh()
                    }
                }
            }
        }

        // ── Scrollable content ──────────────────────────────────
        Flickable {
            id: flick
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: header.bottom
            anchors.bottom: parent.bottom
            anchors.leftMargin: 20 * root.s
            anchors.rightMargin: 8 * root.s
            anchors.topMargin: 10 * root.s

            clip: true
            contentWidth: width
            contentHeight: body.height + 20 * root.s
            boundsBehavior: Flickable.StopAtBounds
            flickableDirection: Flickable.VerticalFlick

            // Draggable bar, same as the notification log
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

            Column {
                id: body
                // leave a gutter on the right so the scroll bar never covers the cards
                width: flick.width - 12 * root.s
                spacing: 12 * root.s

                // ── First screen ────────────────────────────────
                Item {
                    id: topRow
                    width: parent.width
                    // slightly shorter than the viewport, so the "more details" caption peeks in
                    height: Math.max(120 * root.s, flick.height - 22 * root.s)

                    // Hero
                    Item {
                        id: hero
                        width: 140 * root.s
                        height: parent.height

                        Cap { s: root.s; text: "NOW" }

                        Column {
                            y: 18 * root.s
                            spacing: 0

                            T {
                                s: root.s; fs: 54
                                font.weight: Font.Light
                                text: root.ready ? Math.round(WeatherService.temperature) + "°" : "--"
                            }
                            T { s: root.s; fs: 13; text: root.ready ? WeatherService.description : "" }
                            T {
                                s: root.s; fs: 10
                                color: ActiveTheme.colors["FG_MUTED"]
                                text: root.ready ? "Feels like " + WeatherService.feelsLike.toFixed(1) + "°" : ""
                            }
                        }

                        Column {
                            anchors.left: parent.left
                            anchors.bottom: parent.bottom
                            spacing: 2 * root.s
                            visible: root.ready

                            T {
                                s: root.s; fs: 11
                                text: "H " + root.dly("temperature_2m_max", 0, 0).toFixed(1) + "°"
                            }
                            T {
                                s: root.s; fs: 11
                                color: ActiveTheme.colors["FG_MUTED"]
                                text: "L " + root.dly("temperature_2m_min", 0, 0).toFixed(1) + "°"
                            }
                        }

                        WeatherIcon {
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            width: 44 * root.s
                            height: 44 * root.s
                            code: root.ready ? WeatherService.weatherCode : 0
                            day: WeatherService.isDay
                        }
                    }

                    // Tiles + hourly strip
                    Item {
                        id: center
                        x: hero.width + 14 * root.s
                        width: parent.width - hero.width - 190 * root.s - 28 * root.s
                        height: parent.height

                        readonly property real gap: 8 * root.s
                        readonly property real tileW: (width - 2 * gap) / 3
                        readonly property real hourlyH: 62 * root.s
                        readonly property real tileH: (height - hourlyH - 2 * gap) / 2

                        Tile {
                            x: 0; y: 0
                            width: center.tileW; height: center.tileH
                            s: root.s
                            label: "HUMIDITY"
                            value: root.ready ? String(WeatherService.humidity) : "--"
                            unit: "%"
                            sub: "Dew point " + Number(root.cur("dew_point_2m", 0)).toFixed(1) + "°"

                            Bar { s: root.s; ratio: WeatherService.humidity / 100; fill: ActiveTheme.colors["ACCENT_MUTED"] }
                        }

                        Tile {
                            x: center.tileW + center.gap; y: 0
                            width: center.tileW; height: center.tileH
                            s: root.s
                            label: "WIND"
                            value: root.ready ? WeatherService.windSpeed.toFixed(1) : "--"
                            unit: "km/h"
                            sub: "Gusts " + Math.round(root.cur("wind_gusts_10m", 0)) + " · "
                                 + root.compassName(root.cur("wind_direction_10m", 0))

                            Compass {
                                anchors.right: parent.right
                                anchors.rightMargin: 8 * root.s
                                y: 6 * root.s
                                width: 26 * root.s
                                height: 26 * root.s
                                degrees: root.cur("wind_direction_10m", 0)
                            }
                        }

                        Tile {
                            x: 2 * (center.tileW + center.gap); y: 0
                            width: center.tileW; height: center.tileH
                            s: root.s
                            label: "PRESSURE"
                            value: root.ready ? Number(root.cur("pressure_msl", 0)).toFixed(1) : "--"
                            unit: "hPa"
                            sub: root.pressureLabel(root.cur("pressure_msl", 0))

                            ScaleBar {
                                s: root.s
                                ratio: root.clamp01((root.cur("pressure_msl", 1013) - 980) / 60)
                                colorA: ActiveTheme.colors["FG_GHOST"]
                                colorB: ActiveTheme.colors["ACCENT"]
                                colorC: ActiveTheme.colors["ACCENT_MUTED"]
                            }
                        }

                        Tile {
                            x: 0; y: center.tileH + center.gap
                            width: center.tileW; height: center.tileH
                            s: root.s
                            label: "UV · TODAY"
                            value: root.ready ? Number(root.dly("uv_index_max", 0, 0)).toFixed(1) : "--"
                            unit: root.uvLabel(root.dly("uv_index_max", 0, 0))
                            sub: "Peak at midday"

                            ScaleBar { s: root.s; ratio: root.clamp01(root.dly("uv_index_max", 0, 0) / 11) }
                        }

                        Tile {
                            x: center.tileW + center.gap; y: center.tileH + center.gap
                            width: center.tileW; height: center.tileH
                            s: root.s
                            label: "VISIBILITY"
                            value: root.ready ? (root.cur("visibility", 0) / 1000).toFixed(1) : "--"
                            unit: "km"
                            sub: root.visibilityLabel(root.cur("visibility", 0) / 1000)
                        }

                        Tile {
                            x: 2 * (center.tileW + center.gap); y: center.tileH + center.gap
                            width: center.tileW; height: center.tileH
                            s: root.s
                            label: "CLOUD COVER"
                            value: root.ready ? String(Math.round(root.cur("cloud_cover", 0))) : "--"
                            unit: "%"
                            sub: "Rain today " + Number(root.dly("precipitation_sum", 0, 0)).toFixed(1) + " mm"

                            Bar { s: root.s; ratio: root.cur("cloud_cover", 0) / 100; fill: ActiveTheme.colors["FG_MUTED"] }
                        }

                        // Next hours
                        Rectangle {
                            x: 0
                            y: 2 * (center.tileH + center.gap)
                            width: parent.width
                            height: center.hourlyH
                            radius: 10 * root.s
                            color: ActiveTheme.colors["BG_ACTIVE"]

                            Cap { x: 9 * root.s; y: 7 * root.s; s: root.s; text: "NEXT HOURS" }

                            Row {
                                id: hourRow
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                anchors.leftMargin: 6 * root.s
                                anchors.rightMargin: 6 * root.s
                                anchors.bottomMargin: 5 * root.s
                                height: 36 * root.s

                                Repeater {
                                    model: root.hourModel

                                    delegate: Item {
                                        id: hcell
                                        required property var modelData

                                        width: hourRow.width / 6
                                        height: hourRow.height

                                        T {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            s: root.s; fs: 9
                                            color: ActiveTheme.colors["FG_MUTED"]
                                            text: hcell.modelData.label
                                        }

                                        WeatherIcon {
                                            anchors.centerIn: parent
                                            width: 15 * root.s
                                            height: 15 * root.s
                                            code: hcell.modelData.code
                                            day: hcell.modelData.day
                                        }

                                        T {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            anchors.bottom: parent.bottom
                                            s: root.s; fs: 10
                                            text: hcell.modelData.temp + "°"
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // 7 days
                    Rectangle {
                        id: daysCard
                        x: parent.width - width
                        width: 190 * root.s
                        height: parent.height
                        radius: 10 * root.s
                        color: ActiveTheme.colors["BG_ACTIVE"]

                        Cap { x: 12 * root.s; y: 10 * root.s; s: root.s; text: "7 DAYS" }

                        Column {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.top: parent.top
                            anchors.leftMargin: 12 * root.s
                            anchors.rightMargin: 12 * root.s
                            anchors.topMargin: 28 * root.s

                            Repeater {
                                model: root.dayModel

                                delegate: Item {
                                    id: drow
                                    required property var modelData

                                    width: parent.width
                                    height: (daysCard.height - 36 * root.s) / 7

                                    T {
                                        width: 34 * root.s
                                        anchors.verticalCenter: parent.verticalCenter
                                        s: root.s; fs: 10
                                        color: ActiveTheme.colors["FG_MUTED"]
                                        text: drow.modelData.name
                                    }

                                    T {
                                        x: 34 * root.s
                                        width: 24 * root.s
                                        anchors.verticalCenter: parent.verticalCenter
                                        horizontalAlignment: Text.AlignRight
                                        s: root.s; fs: 10
                                        color: ActiveTheme.colors["FG_MUTED"]
                                        text: drow.modelData.min + "°"
                                    }

                                    Rectangle {
                                        id: dtrack
                                        x: 64 * root.s
                                        width: drow.width - 64 * root.s - 30 * root.s
                                        height: Math.max(2, 4 * root.s)
                                        radius: height / 2
                                        anchors.verticalCenter: parent.verticalCenter
                                        color: ActiveTheme.colors["DARK6"]

                                        Rectangle {
                                            x: drow.modelData.from * dtrack.width
                                            width: Math.max(dtrack.height, (drow.modelData.to - drow.modelData.from) * dtrack.width)
                                            height: dtrack.height
                                            radius: dtrack.radius
                                            gradient: Gradient {
                                                orientation: Gradient.Horizontal
                                                GradientStop { position: 0.0; color: ActiveTheme.colors["SUCCESS"] }
                                                GradientStop { position: 1.0; color: ActiveTheme.colors["URGENT"] }
                                            }
                                        }
                                    }

                                    T {
                                        x: drow.width - 24 * root.s
                                        width: 24 * root.s
                                        anchors.verticalCenter: parent.verticalCenter
                                        s: root.s; fs: 10
                                        text: drow.modelData.max + "°"
                                    }
                                }
                            }
                        }
                    }
                }

                // ── Below the fold ──────────────────────────────
                Cap { s: root.s; text: "MORE DETAILS" }

                Row {
                    id: detailRow
                    width: parent.width
                    spacing: 8 * root.s

                    readonly property real cw: (width - 3 * spacing) / 4
                    readonly property real rowH: Math.max(sunCard.naturalHeight, windCard.naturalHeight,
                                      precipCard.naturalHeight, moonCard.naturalHeight)

                    Card {
                        id: sunCard
                        width: detailRow.cw
                        height: detailRow.rowH
                        s: root.s
                        title: "SUN"

                        KV { s: root.s; k: "Sunrise"; v: root.hhmm(root.dly("sunrise", 0, "")) }
                        KV { s: root.s; k: "Sunset"; v: root.hhmm(root.dly("sunset", 0, "")) }
                        KV { s: root.s; k: "Daylight"; v: root.duration(root.dly("daylight_duration", 0, 0)) }
                    }

                    Card {
                        id: windCard
                        width: detailRow.cw
                        height: detailRow.rowH
                        s: root.s
                        title: "WIND ALOFT · km/h"

                        BarKV { s: root.s; k: "10 m"; v: Number(root.cur("wind_speed_10m", 0)).toFixed(1); ratio: root.cur("wind_speed_10m", 0) / 50 }
                        BarKV { s: root.s; k: "80 m"; v: Number(root.cur("wind_speed_80m", 0)).toFixed(1); ratio: root.cur("wind_speed_80m", 0) / 50 }
                        BarKV { s: root.s; k: "120 m"; v: Number(root.cur("wind_speed_120m", 0)).toFixed(1); ratio: root.cur("wind_speed_120m", 0) / 50 }
                        BarKV { s: root.s; k: "180 m"; v: Number(root.cur("wind_speed_180m", 0)).toFixed(1); ratio: root.cur("wind_speed_180m", 0) / 50 }
                    }

                    Card {
                        id: precipCard
                        width: detailRow.cw
                        height: detailRow.rowH
                        s: root.s
                        title: "PRECIPITATION"

                        KV { s: root.s; k: "Today"; v: Number(root.dly("precipitation_sum", 0, 0)).toFixed(1) + " mm" }
                        KV { s: root.s; k: "Wet hours"; v: root.dly("precipitation_hours", 0, 0) + " h" }
                        KV { s: root.s; k: "Chance"; v: root.dly("precipitation_probability_max", 0, 0) + " %" }
                    }

                    Card {
                        id: moonCard
                        width: detailRow.cw
                        height: detailRow.rowH
                        s: root.s
                        title: "MOON"

                        KV { s: root.s; k: "Phase"; v: root.moonName(root.dly("moon_phase", 0, 0)) }
                        KV { s: root.s; k: "Rise"; v: root.hhmm(root.dly("moonrise", 0, "")) }
                        KV { s: root.s; k: "Set"; v: root.hhmm(root.dly("moonset", 0, "")) }
                    }
                }
            }
        }
    }
}
