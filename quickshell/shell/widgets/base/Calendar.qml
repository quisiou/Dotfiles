// quickshell/shell/widgets/base/Calendar.qml


pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ElysianShell.Themes

Rectangle {
    id: root

    property real padding: 12

    implicitWidth: contentColumn.implicitWidth + padding * 2
    implicitHeight: contentColumn.implicitHeight + padding * 2
    width: implicitWidth
    height: implicitHeight

    clip: true
    color: ActiveTheme.colors["BG_FOCUSED"]

    radius: 12

    property int currentMonth: 0
    property int currentYear: 1970
    property var locale: Qt.locale("")

    readonly property real _scale: Math.max(0.6, Math.min(1.3, width / 320))

    function refreshLocale() {
        currentMonth = (new Date()).getMonth()
        currentYear  = (new Date()).getFullYear()
    }

    function goToPreviousMonth() {
        if (currentMonth === 0) {
            currentMonth = 11
            currentYear -= 1
        } else {
            currentMonth -= 1
        }
    }

    function goToNextMonth() {
        if (currentMonth === 11) {
            currentMonth = 0
            currentYear += 1
        } else {
            currentMonth += 1
        }
    }

    Component.onCompleted: refreshLocale()

    ColumnLayout {
        id: contentColumn
        anchors.fill: parent
        anchors.margins: root.padding
        spacing: 4

        RowLayout {
            id: headerRow
            Layout.fillWidth: true
            spacing: 0

            component NavButton: Rectangle {
                id: navBtn
                property alias text: navLabel.text
                signal clicked()
                Layout.preferredWidth: 20
                Layout.preferredHeight: 20
                radius: 4
                color: navMouseArea.containsMouse ? ActiveTheme.colors["ACCENT_LOW"] : "transparent"

                Text {
                    id: navLabel
                    anchors.centerIn: parent
                    font.pixelSize: Math.round(16 * root._scale)
                    color: ActiveTheme.colors["FG"]
                }

                MouseArea {
                    id: navMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: navBtn.clicked()
                }
            }

            NavButton {
                text: "\u2039"
                onClicked: root.goToPreviousMonth()
            }

            Item { Layout.fillWidth: true }

            Text {
                horizontalAlignment: Text.AlignHCenter
                text: root.locale.monthName(root.currentMonth, Locale.ShortFormat)
                font.pixelSize: Math.round(14 * root._scale)
                font.bold: true
                color: ActiveTheme.colors["FG"]
            }

            Item { Layout.fillWidth: true }

            NavButton {
                text: "\u203A"
                onClicked: root.goToNextMonth()
            }

            Item { Layout.preferredWidth: 12 } // fixed gap between month/year clusters

            NavButton {
                text: "\u2039"
                onClicked: root.currentYear -= 1
            }

            Item { Layout.fillWidth: true }

            Text {
                horizontalAlignment: Text.AlignHCenter
                text: root.currentYear
                font.pixelSize: Math.round(14 * root._scale)
                font.bold: true
                color: ActiveTheme.colors["FG"]
            }

            Item { Layout.fillWidth: true }

            NavButton {
                text: "\u203A"
                onClicked: root.currentYear += 1
            }
        }

        DayOfWeekRow {
            id: daysRow
            Layout.fillWidth: true
            locale: grid.locale

            delegate: Text {
                required property var model
                horizontalAlignment: Text.AlignHCenter
                text: model.shortName
                font.pixelSize: Math.round(15 * root._scale)
                font.bold: true
                color: ActiveTheme.colors["FG"]
            }
        }

        MonthGrid {
            id: grid
            Layout.fillWidth: true
            Layout.fillHeight: true
            month: root.currentMonth
            year: root.currentYear
            locale: root.locale

            delegate: Item {
                id: dayCell
                required property var model

                implicitWidth: Math.round(30 * root._scale)
                implicitHeight: Math.round(30 * root._scale)

                Rectangle {
                    id: todayBubble
                    anchors.centerIn: parent
                    width: Math.round(28 * root._scale)
                    height: Math.round(28 * root._scale)
                    radius: width / 2
                    color: dayCell.model.today ? ActiveTheme.colors["ACCENT_LOW"] : "transparent"
                }

                Text {
                    anchors.centerIn: parent
                    text: dayCell.model.day
                    font.pixelSize: Math.round(14 * root._scale)
                    color: {
                        if (dayCell.model.today)
                            return ActiveTheme.colors["BG"];
                        if (dayCell.model.month === grid.month)
                            return ActiveTheme.colors["FG_LIGHT"];
                        return ActiveTheme.colors["FG_GHOST"];
                    }
                }
            }
        }
    }
}
