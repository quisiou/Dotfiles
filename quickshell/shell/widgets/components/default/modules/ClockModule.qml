/* quickshell/shell/widgets/components/default/modules/ClockModule.qml */


import QtQuick
import ElysianShell.Themes
import "../../../base"     // For ClockText widget

Column {
    id: root

    property bool expanded: false
    property real clockPixelSize: 16

    spacing: root.expanded ? 2 : 0

    Behavior on spacing {
        NumberAnimation { duration: 200; easing.type: Easing.InOutCubic }
    }

    ClockText {
        id: clock
        anchors.horizontalCenter: parent.horizontalCenter
        pixelSize: root.clockPixelSize

        Behavior on pixelSize {
            NumberAnimation { duration: 200; easing.type: Easing.InOutCubic }
        }
    }

    Item {
        id: dateWrapper
        anchors.horizontalCenter: parent.horizontalCenter
        width: dateText.implicitWidth
        height: root.expanded ? dateMetrics.height : 0
        clip: true

        Behavior on height {
            NumberAnimation { duration: 200; easing.type: Easing.InOutCubic }
        }

        Text {
            id: dateText
            anchors.top: parent.top   // pin to top of wrapper so clipping trims cleanly as height shrinks
            opacity: root.expanded ? 1 : 0
            text: Qt.formatDate(new Date(), "ddd, MMM d")
            color: ActiveTheme.colors["FG_MUTED"]
            font.pixelSize: 11

            Behavior on opacity {
                NumberAnimation { duration: 200; easing.type: Easing.InOutCubic }
            }
        }
    }
}
