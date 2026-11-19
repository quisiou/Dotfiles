/* quickshell/shell/widgets/base/SystemInfoMenu.qml */


import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import ElysianShell.Themes
import ElysianShell.Services

Item {
    id: root

    property bool expanded: false
    signal toggleRequested()

    // 1.0 at the collapsed block size (300 x 105 at the 768px design width)
    readonly property real c: Math.max(0.2, Math.min(width / 300, height / 105))
    function s(v) { return Math.round(v * c) }

    Glass {
        anchors.fill: parent
        radius: 12
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggleRequested()
    }

    // ── Collapsed ────────────────────────────────────
    Item {
        id: collapsedView
        anchors.fill: parent
        visible: !root.expanded

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: root.s(14)
            anchors.rightMargin: root.s(14)
            spacing: root.s(12)

            // Avatar + badge
            Item {
                Layout.preferredWidth: root.s(58)
                Layout.preferredHeight: root.s(58)
                Layout.alignment: Qt.AlignVCenter

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

                    // Fallback while the image is missing or loading
                    Text {
                        anchors.centerIn: parent
                        visible: avatar.status !== Image.Ready
                        text: "\uf007"
                        font.pixelSize: root.s(28)
                        color: ActiveTheme.colors["ACCENT"]
                    }
                }

                // Distro badge, bottom right, overlapping the avatar edge
                Rectangle {
                    width: root.s(19); height: width
                    radius: width / 2
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.rightMargin: -root.s(1)
                    anchors.bottomMargin: -root.s(1)
                    color: ActiveTheme.colors["BG_FOCUSED"]
                    border.width: 1
                    border.color: Qt.alpha(ActiveTheme.colors["FG"], 0.12)

                    Text {
                        anchors.centerIn: parent
                        text: SystemInfoService.distroGlyph
                        font.pixelSize: root.s(11)
                        color: ActiveTheme.colors["ACCENT"]
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                Layout.alignment: Qt.AlignVCenter
                spacing: 0

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
        }
    }

    // ── Expanded (placeholder until we build it) ─────
    Text {
        anchors.centerIn: parent
        visible: root.expanded
        text: "Expanded view coming next"
        color: ActiveTheme.colors["FG_MUTED"]
        font.pixelSize: 14
    }
}
