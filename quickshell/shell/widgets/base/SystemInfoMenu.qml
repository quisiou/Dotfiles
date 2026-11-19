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

    // 1.0 at the collapsed size (300 x 105) and at the expanded size (702 x 312)
    readonly property real c: Math.max(0.2, Math.min(width / 300, height / 105))
    readonly property real e: Math.max(0.2, Math.min(width / 702, height / 312))
    function s(v)  { return Math.round(v * c) }
    function se(v) { return Math.round(v * e) }

    readonly property real tilesW: width - 2 * se(18) - 2 * se(12)

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
        onTriggered: SystemInfoService.refreshUptime()
    }

    // ── Reusable tile: title, big figures, divider, rows ──
    component Tile: Rectangle {
        id: tile

        property real k: 1
        property string icon: ""
        property string title: ""
        property var stats: []   // [{ v: "8", u: "c / 16t", l: "CPU cores" }]
        property var rows: []    // [{ k: "Kernel", v: "6.12.4" }], empty v is skipped
        property real share: 0.33   // fraction of the tiles row
        property real rowW: 0       // total width available to the tiles

        Layout.fillWidth: false
        Layout.fillHeight: true
        Layout.minimumWidth: 0
        Layout.preferredWidth: rowW * share

        radius: Math.round(10 * k)
        color: Qt.alpha(ActiveTheme.colors["FG"], 0.05)
        border.width: 1
        border.color: Qt.alpha(ActiveTheme.colors["FG"], 0.08)

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Math.round(14 * tile.k)
            spacing: 0

            // Title
            RowLayout {
                spacing: Math.round(6 * tile.k)
                Text {
                    text: tile.icon
                    font.pixelSize: Math.round(13 * tile.k)
                    color: ActiveTheme.colors["ACCENT"]
                }
                Text {
                    text: tile.title
                    font.pixelSize: Math.round(11 * tile.k)
                    color: ActiveTheme.colors["FG_MUTED"]
                }
            }

            // Big figures
            RowLayout {
                Layout.topMargin: Math.round(8 * tile.k)
                spacing: Math.round(14 * tile.k)

                Repeater {
                    model: tile.stats

                    ColumnLayout {
                        id: stat
                        required property var modelData
                        spacing: Math.round(2 * tile.k)

                        RowLayout {
                            spacing: Math.round(4 * tile.k)
                            Text {
                                text: stat.modelData.v
                                font.pixelSize: Math.round(26 * tile.k)
                                font.weight: Font.Light
                                color: ActiveTheme.colors["FG"]
                            }
                            Text {
                                visible: (stat.modelData.u ?? "") !== ""
                                text: stat.modelData.u ?? ""
                                Layout.alignment: Qt.AlignBaseline
                                font.pixelSize: Math.round(12 * tile.k)
                                color: ActiveTheme.colors["FG_MUTED"]
                            }
                        }
                        Text {
                            text: stat.modelData.l ?? ""
                            font.pixelSize: Math.round(11 * tile.k)
                            color: ActiveTheme.colors["FG_MUTED"]
                        }
                    }
                }
            }

            // Divider
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                Layout.topMargin: Math.round(10 * tile.k)
                Layout.bottomMargin: Math.round(8 * tile.k)
                color: Qt.alpha(ActiveTheme.colors["FG"], 0.07)
            }

            // Detail rows
            Repeater {
                model: tile.rows.filter(r => !!r.v)

                RowLayout {
                    id: row
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.bottomMargin: Math.round(4 * tile.k)
                    spacing: Math.round(8 * tile.k)

                    Text {
                        text: row.modelData.k
                        Layout.preferredWidth: Math.round(56 * tile.k)
                        Layout.alignment: Qt.AlignTop
                        font.family: "monospace"
                        font.pixelSize: Math.round(11 * tile.k)
                        color: ActiveTheme.colors["ACCENT"]
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        spacing: 0

                        Text {
                            Layout.fillWidth: true
                            text: row.modelData.v
                            font.family: "monospace"
                            font.pixelSize: Math.round(11 * tile.k)
                            color: ActiveTheme.colors["FG"]
                            elide: Text.ElideRight
                        }
                        Text {
                            Layout.fillWidth: true
                            visible: !!row.modelData.sub
                            text: row.modelData.sub ?? ""
                            font.family: "monospace"
                            font.pixelSize: Math.round(10 * tile.k)
                            color: ActiveTheme.colors["FG_MUTED"]
                            elide: Text.ElideRight
                        }
                    }
                }
            }

            Item { Layout.fillHeight: true }
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
        anchors.margins: root.se(18)
        spacing: 0
        opacity: Math.max(0, root.t * 2 - 1)
        visible: opacity > 0

        // Header: the avatar (drawn below) sits at its left
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: root.se(52)

            ColumnLayout {
                anchors.left: parent.left
                anchors.leftMargin: root.se(52 + 14)
                anchors.right: uptimeChip.left
                anchors.rightMargin: root.se(12)
                anchors.verticalCenter: parent.verticalCenter
                spacing: root.se(2)

                Text {
                    Layout.fillWidth: true
                    text: SystemInfoService.hostname
                    font.pixelSize: root.se(30)
                    font.weight: Font.Light
                    color: ActiveTheme.colors["FG"]
                    elide: Text.ElideRight
                }
                Text {
                    Layout.fillWidth: true
                    text: SystemInfoService.user + " · " + SystemInfoService.wm
                          + " · Linux " + SystemInfoService.kernel
                    font.pixelSize: root.se(12)
                    color: ActiveTheme.colors["FG_MUTED"]
                    elide: Text.ElideRight
                }
            }

            Rectangle {
                id: uptimeChip
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: chipRow.implicitWidth + root.se(24)
                height: root.se(28)
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
                        font.pixelSize: root.se(13)
                        color: ActiveTheme.colors["ACCENT"]
                    }
                    Text {
                        text: "up " + SystemInfoService.uptime
                        font.pixelSize: root.se(12)
                        color: ActiveTheme.colors["FG"]
                    }
                }
            }
        }

        // Tiles
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.topMargin: root.se(14)
            spacing: root.se(12)

            Tile {
                k: root.e
                icon: "\uf120"
                title: "Software"
                share: 0.25
                rowW: root.tilesW
                stats: [{
                    v: (SystemInfoService.osName || "").split(" ")[0],
                    l: (SystemInfoService.osName || "").split(" ").slice(1).join(" ")
                }]
                rows: [
                    { k: "Kernel",  v: SystemInfoService.kernel },
                    { k: "WM",      v: SystemInfoService.wm },
                    { k: "Shell",   v: "Quickshell" },
                    { k: "Session", v: SystemInfoService.session }
                ]
            }
            Tile {
                k: root.e
                icon: "\uf2db"
                title: "Hardware"
                share: 0.45
                rowW: root.tilesW
                stats: [
                    { v: SystemInfoService.cpuCores > 0
                           ? SystemInfoService.cpuCores : SystemInfoService.cpuThreads,
                      u: SystemInfoService.cpuCores > 0
                           ? "c / " + SystemInfoService.cpuThreads + "t" : "threads",
                      l: "CPU" },
                    { v: SystemInfoService.ramGb, u: "GB", l: "Memory" }
                ]
                rows: [{ k: "CPU", v: SystemInfoService.cpuModel }]
                    .concat(SystemInfoService.gpuRows)
                    .concat([{ k: "Storage", v: SystemInfoService.storage }])
            }
            Tile {
                k: root.e
                icon: "\uf108"
                title: "Display"
                share: 0.3
                rowW: root.tilesW
                stats: [{
                    v: SystemInfoService.panelRes,
                    l: SystemInfoService.panelHz !== ""
                       ? "Panel · " + SystemInfoService.panelHz : "Panel"
                }]
                rows: [
                    { k: "Scale",    v: SystemInfoService.panelScale },
                    { k: "Monitor",  v: SystemInfoService.panelModel },
                    { k: "Renderer", v: SystemInfoService.renderer }
                ]
            }
        }
    }

    // ── Avatar + distro badge: one item that moves between states ──
    Item {
        id: avatarBox

        readonly property real size: root.mix(root.s(58), root.se(52))

        width: size
        height: size
        x: root.mix(root.s(14), root.se(18))
        y: root.mix((root.height - size) / 2, root.se(18))

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
                color: ActiveTheme.colors["ACCENT"]
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
                color: ActiveTheme.colors["ACCENT"]
            }
        }
    }
}
