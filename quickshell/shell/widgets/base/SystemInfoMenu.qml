// quickshell/shell/widgets/base/SystemInfoMenu.qml

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import ElysianShell.Themes
import ElysianShell.Services

Item {
    id: root

    property bool expanded: false
    signal toggleRequested()

    // 1.0 at the collapsed size (300 x 105) and at the expanded size
    readonly property real c: Math.max(0.2, Math.min(width / 300, height / 105))
    readonly property real e: Math.max(0.2, Math.min(width / 660, height / 312))
    function s(v)  { return Math.round(v * c) }
    function se(v) { return Math.round(v * e) }

    // ── Expanded grid geometry: rail + 4 columns x 3 rows ──
    readonly property real gap: se(8)
    readonly property real railW: se(14)
    readonly property real gridW: width - 2 * se(16)
    readonly property real gridH: height - 2 * se(16) - se(42) - se(10)
    readonly property real cellW: (gridW - railW - 4 * gap) / 4
    readonly property real cellH: (gridH - 2 * gap) / 3
    function spanW(n) { return cellW * n + gap * (n - 1) }

    function cap(str) { return str ? str.charAt(0).toUpperCase() + str.slice(1) : "" }

    function healthColor(h) {
        const green  = Qt.color(ActiveTheme.colors["SUCCESS"])
        const yellow = Qt.color(ActiveTheme.colors["WARNING"])
        const red    = Qt.color(ActiveTheme.colors["ERROR_LOW"])
        const hi = 90, mid = 65, lo = 40   // fully green at or above hi, yellow at mid, red at or below lo

        const mix = (a, b, t) => Qt.rgba(a.r + (b.r - a.r) * t,
                                         a.g + (b.g - a.g) * t,
                                         a.b + (b.b - a.b) * t, 1)

        if (h >= hi)  return green
        if (h >= mid) return mix(green, yellow, (hi - h) / (hi - mid))
        if (h >= lo)  return mix(yellow, red, (mid - h) / (mid - lo))
        return red
    }

    // 0 = collapsed, 1 = expanded. Drives the avatar morph and the crossfade.
    property real t: expanded ? 1 : 0
    Behavior on t { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
    function mix(a, b) { return a + (b - a) * t }

    // Refresh uptime only while the card is open
    Timer {
        running: root.expanded
        interval: 60000
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            SystemInfoService.refreshUptime()
            SystemInfoService.refreshTerminal()
        }
    }

    // ── Base card: icon + caption, children go below ──
    component Card: Rectangle {
        id: card

        property real k: 1
        property string icon: ""
        property string label: ""
        property int gridRow: 0
        property int gridCol: 1
        property int span: 1
        property real w: 0
        property real h: 0
        property real bar: -1          // 0..1 draws a thin progress line on the bottom edge
        property color barColor: ActiveTheme.colors["ACCENT_LOW"]
        default property alias content: body.data

        Layout.row: gridRow
        Layout.column: gridCol
        Layout.columnSpan: span
        Layout.fillWidth: false
        Layout.fillHeight: false
        Layout.preferredWidth: w
        Layout.preferredHeight: h

        radius: Math.round(10 * k)

        color: Qt.alpha(ActiveTheme.colors["BG"], 0.5)
        border.width: 1
        border.color: Qt.alpha(ActiveTheme.colors["FG"], 0.05)

        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: Math.round(10 * card.k)
            anchors.rightMargin: Math.round(10 * card.k)
            anchors.topMargin: Math.round(8 * card.k)
            anchors.bottomMargin: Math.round(7 * card.k)
            spacing: 0

            RowLayout {
                Layout.fillWidth: true
                spacing: Math.round(5 * card.k)

                Text {
                    text: card.icon
                    font.pixelSize: Math.round(10 * card.k)
                    color: Qt.alpha(ActiveTheme.colors["ACCENT_LOW"], 0.75)
                }
                Text {
                    text: card.label.toUpperCase()
                    font.pixelSize: Math.round(9 * card.k)
                    font.letterSpacing: 0.8 * card.k
                    color: ActiveTheme.colors["FG_MUTED"]
                }
            }

            ColumnLayout {
                id: body
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 0
            }
        }
    }

    // ── Number tile: big value + unit, up to two muted lines at the bottom ──
    component Tile: Card {
        id: tile

        property string value: ""
        property string unit: ""
        property string sub1: ""
        property string sub2: ""
        property real valueSize: 17
        property bool strong: false    // sub1 in the main text colour

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: Math.round(2 * tile.k)
            spacing: Math.round(3 * tile.k)

            Text {
                Layout.minimumWidth: 0
                text: tile.value
                elide: Text.ElideRight
                font.pixelSize: Math.round(tile.valueSize * tile.k)
                font.weight: Font.Light
                color: ActiveTheme.colors["FG"]
            }
            Text {
                visible: tile.unit !== ""
                text: tile.unit
                Layout.alignment: Qt.AlignBaseline
                Layout.minimumWidth: implicitWidth
                font.pixelSize: Math.round(9 * tile.k)
                color: ActiveTheme.colors["FG_MUTED"]
            }
            Rectangle {
                visible: tile.bar >= 0
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                Layout.leftMargin: Math.round(8 * tile.k)
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredHeight: Math.max(2, Math.round(3 * tile.k))
                radius: height / 2
                color: Qt.alpha(ActiveTheme.colors["FG"], 0.2)

                Rectangle {
                    width: parent.width * Math.max(0, Math.min(1, tile.bar))
                    height: parent.height
                    radius: parent.radius
                    color: tile.barColor
                }
            }
        }

        Item { Layout.fillHeight: true }

        Marquee {
            Layout.fillWidth: true
            visible: tile.sub1 !== ""
            running: root.expanded
            text: tile.sub1
            font.pixelSize: Math.round(9 * tile.k)
            color: tile.strong ? ActiveTheme.colors["FG"] : ActiveTheme.colors["FG_MUTED"]
        }
        Marquee {
            Layout.fillWidth: true
            visible: tile.sub2 !== ""
            running: root.expanded
            text: tile.sub2
            font.pixelSize: Math.round(9 * tile.k)
            color: ActiveTheme.colors["FG_MUTED"]
        }
    }

    // ── Rotated group label on the left edge ──
    component Rail: Item {
        property string label: ""
        property int gridRow: 0
        property int rows: 1

        Layout.row: gridRow
        Layout.column: 0
        Layout.rowSpan: rows
        Layout.fillWidth: false
        Layout.fillHeight: false
        Layout.preferredWidth: root.railW
        Layout.preferredHeight: root.cellH * rows + root.gap * (rows - 1)

        Text {
            anchors.centerIn: parent
            rotation: -90
            text: parent.label.toUpperCase()
            font.pixelSize: Math.round(9 * root.e)
            font.letterSpacing: 1.2 * root.e
            color: ActiveTheme.colors["FG_MUTED"]
        }
    }

    // ── Background + click ───────────────────────────
    Glass {
        anchors.fill: parent
        radius: 12
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggleRequested()
    }

    // ── Collapsed text (fades out) ───────────────────
    ColumnLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: root.s(14 + 58 + 12)
        anchors.rightMargin: root.s(14)
        anchors.verticalCenter: parent.verticalCenter
        spacing: 0
        opacity: Math.max(0, 1 - root.t * 2)
        visible: opacity > 0

        Text {
            Layout.fillWidth: true
            text: SystemInfoService.user
            font.pixelSize: root.s(15)
            font.bold: true
            color: ActiveTheme.colors["FG"]
            elide: Text.ElideRight
        }
        Text {
            Layout.fillWidth: true
            text: SystemInfoService.hostname
            font.pixelSize: root.s(11)
            color: ActiveTheme.colors["FG_MUTED"]
            elide: Text.ElideRight
        }
        Text {
            Layout.fillWidth: true
            Layout.topMargin: root.s(6)
            text: SystemInfoService.wm
            font.pixelSize: root.s(12)
            color: ActiveTheme.colors["FG"]
            elide: Text.ElideRight
        }
        Text {
            Layout.fillWidth: true
            text: "Linux " + SystemInfoService.kernel
            font.pixelSize: root.s(11)
            color: ActiveTheme.colors["FG_MUTED"]
            elide: Text.ElideRight
        }
    }

    // ── Expanded content (fades in) ──────────────────
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.se(16)
        spacing: 0
        opacity: Math.max(0, root.t * 2 - 1)
        visible: opacity > 0

        // Header: the avatar (drawn below) sits at its left
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: root.se(42)

            ColumnLayout {
                anchors.left: parent.left
                anchors.leftMargin: root.se(42 + 12)
                anchors.right: uptimeChip.left
                anchors.rightMargin: root.se(12)
                anchors.verticalCenter: parent.verticalCenter
                spacing: 0

                Text {
                    Layout.fillWidth: true
                    text: SystemInfoService.hostname
                    font.pixelSize: root.se(26)
                    font.weight: Font.Light
                    color: ActiveTheme.colors["FG"]
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    text: SystemInfoService.user
                    font.pixelSize: root.se(11)
                    color: ActiveTheme.colors["FG_MUTED"]
                    elide: Text.ElideRight
                }
            }

            Rectangle {
                id: uptimeChip
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: chipRow.implicitWidth + root.se(24)
                height: root.se(26)
                radius: root.se(8)
                color: Qt.alpha(ActiveTheme.colors["FG"], 0.05)
                border.width: 1
                border.color: Qt.alpha(ActiveTheme.colors["FG"], 0.08)

                Row {
                    id: chipRow
                    anchors.centerIn: parent
                    spacing: root.se(6)
                    Text {
                        text: "\uf017"
                        font.pixelSize: root.se(12)
                        color: ActiveTheme.colors["ACCENT_LOW"]
                    }
                    Text {
                        text: "up " + SystemInfoService.uptime
                        font.pixelSize: root.se(12)
                        color: ActiveTheme.colors["FG"]
                    }
                }
            }
        }

        // Tile grid: column 0 is the rail, columns 1 to 4 are the tiles
        GridLayout {
            Layout.topMargin: root.se(10)
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 5
            columnSpacing: root.gap
            rowSpacing: root.gap

            Rail { label: "Software"; gridRow: 0; rows: 1 }
            Rail { label: "Hardware"; gridRow: 1; rows: 2 }

            // ── Row 0: software ──
            Tile {
                k: root.e; gridRow: 0; gridCol: 1; w: root.spanW(1); h: root.cellH
                icon: "\uf17c"; label: "System"
                value: SystemInfoService.osLabel
                       || (SystemInfoService.osName || "").split(" ")[0]
                unit: SystemInfoService.osVersion
                sub1: SystemInfoService.kernel !== "" ? "Linux " + SystemInfoService.kernel : ""
            }
            Tile {
                k: root.e; gridRow: 0; gridCol: 2; w: root.spanW(1); h: root.cellH
                icon: "\uf2d0"; label: "Graphic env"
                value: SystemInfoService.wm
                unit: SystemInfoService.wmVersion !== "" ? "v" + SystemInfoService.wmVersion : ""
                sub1: root.cap(SystemInfoService.session)
            }
            Tile {
                k: root.e; gridRow: 0; gridCol: 3; w: root.spanW(1); h: root.cellH
                icon: "\uf120"; label: "Shell"
                value: SystemInfoService.loginShell
                unit: SystemInfoService.loginShellVersion !== ""
                      ? "v" + SystemInfoService.loginShellVersion : ""
                sub1: SystemInfoService.terminal !== ""
                      ? SystemInfoService.terminal
                        + (SystemInfoService.terminalVersion !== ""
                           ? " v" + SystemInfoService.terminalVersion : "")
                      : ""
                strong: true
            }
            Tile {
                k: root.e; gridRow: 0; gridCol: 4; w: root.spanW(1); h: root.cellH
                icon: "\uf1b2"; label: "Rendering"
                value: SystemInfoService.panelScale
                unit: "scale"
                sub1: SystemInfoService.renderer
                sub2: SystemInfoService.panelVrr !== ""
                      ? "VRR " + SystemInfoService.panelVrr.toLowerCase()
                        + " · " + SystemInfoService.panelDepth : ""
            }

            // ── Row 1: CPU, memory, GPU ──
            Tile {
                k: root.e; gridRow: 1; gridCol: 1; w: root.spanW(1); h: root.cellH
                icon: "\uf2db"; label: "CPU"
                value: SystemInfoService.cpuCores > 0
                       ? SystemInfoService.cpuCores : SystemInfoService.cpuThreads
                unit: (SystemInfoService.cpuCores > 0
                       ? "c / " + SystemInfoService.cpuThreads + "t" : "threads")
                      + (SystemInfoService.cpuBoost !== ""
                         ? " · max " + SystemInfoService.cpuBoost : "")
                sub1: SystemInfoService.cpuModel
                strong: true
                sub2: SystemInfoService.cpuInfo
            }
            Tile {
                k: root.e; gridRow: 1; gridCol: 2; w: root.spanW(1); h: root.cellH
                icon: "\uf538"; label: "Memory"
                value: SystemInfoService.ramGb
                unit: "GB"
                sub1: SystemInfoService.swapText
            }
            Card {
                k: root.e; gridRow: 1; gridCol: 3; span: 2; w: root.spanW(2); h: root.cellH
                icon: "\uf0e4"; label: "GPU"

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: Math.round(3 * root.e)
                    spacing: root.se(12)

                    Repeater {
                        model: SystemInfoService.gpuRows

                        ColumnLayout {
                            id: gpu
                            required property var modelData
                            Layout.fillWidth: true
                            Layout.preferredWidth: 1
                            Layout.minimumWidth: 0
                            Layout.alignment: Qt.AlignTop
                            spacing: 0

                            Text {
                                text: gpu.modelData.k
                                font.pixelSize: root.se(9)
                                color: ActiveTheme.colors["ACCENT_LOW"]
                            }
                            Marquee {
                                Layout.fillWidth: true
                                running: root.expanded
                                text: gpu.modelData.v
                                font.pixelSize: root.se(12)
                                color: ActiveTheme.colors["FG"]
                            }
                            Marquee {
                                Layout.fillWidth: true
                                visible: !!gpu.modelData.sub
                                running: root.expanded
                                text: gpu.modelData.sub ?? ""
                                font.pixelSize: root.se(9)
                                color: ActiveTheme.colors["FG_MUTED"]
                            }
                        }
                    }
                }

                Item { Layout.fillHeight: true }
            }

            // ── Row 2: storage, panel, battery ──
            Tile {
                k: root.e; gridRow: 2; gridCol: 1; span: 2; w: root.spanW(2); h: root.cellH
                icon: "\uf0a0"; label: "Storage"
                value: SystemInfoService.storageValue
                unit: SystemInfoService.storageUnit
                sub1: SystemInfoService.storageModel
                strong: true
                sub2: SystemInfoService.storageInfo
            }
            Tile {
                // Takes the battery's column when there is no battery
                k: root.e; gridRow: 2; gridCol: 3
                span: BatteryService.hasBattery ? 1 : 2
                w: root.spanW(span); h: root.cellH
                icon: "\uf108"; label: "Panel"
                value: SystemInfoService.panelRes
                valueSize: 16
                sub1: SystemInfoService.panelHz
                      + (SystemInfoService.panelSize !== "" ? " · " + SystemInfoService.panelSize : "")
                sub2: SystemInfoService.panelModel
            }
            Tile {
                visible: BatteryService.hasBattery
                k: root.e; gridRow: 2; gridCol: 4; w: root.spanW(1); h: root.cellH
                icon: "\uf240"; label: "Battery"
                value: BatteryService.healthKnown
                       ? String(BatteryService.healthPercent) : String(BatteryService.chargePercent)
                unit: BatteryService.healthKnown ? "% health" : "% charge"
                bar: BatteryService.healthKnown ? BatteryService.healthPercent / 100 : -1
                barColor: root.healthColor(BatteryService.healthPercent)
                sub1: BatteryService.name
                strong: true
                sub2: BatteryService.detail
            }
        }
    }

    // ── Avatar + distro badge: one item that moves between states ──
    Item {
        id: avatarBox

        readonly property real size: root.mix(root.s(58), root.se(42))

        width: size
        height: size
        x: root.mix(root.s(14), root.se(16))
        y: root.mix((root.height - size) / 2, root.se(16))

        ClippingRectangle {
            anchors.fill: parent
            radius: width / 2
            color: Qt.alpha(ActiveTheme.colors["ACCENT_LOW"], 0.15)
            border.width: 1
            border.color: Qt.alpha(ActiveTheme.colors["FG"], 0.12)

            Image {
                id: avatar
                anchors.fill: parent
                source: SystemInfoService.avatarSource
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                visible: status === Image.Ready
            }
            Text {
                anchors.centerIn: parent
                visible: avatar.status !== Image.Ready
                text: "\uf007"
                font.pixelSize: avatarBox.size * 0.48
                color: ActiveTheme.colors["ACCENT_LOW"]
            }
        }

        Rectangle {
            width: avatarBox.size * 0.33
            height: width
            radius: width / 2
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.rightMargin: -1
            anchors.bottomMargin: -1
            color: ActiveTheme.colors["BG_FOCUSED"]
            border.width: 1
            border.color: Qt.alpha(ActiveTheme.colors["FG"], 0.12)

            Text {
                anchors.centerIn: parent
                text: SystemInfoService.distroGlyph
                font.pixelSize: parent.width * 0.58
                color: ActiveTheme.colors["ACCENT_LOW"]
            }
        }
    }
}
