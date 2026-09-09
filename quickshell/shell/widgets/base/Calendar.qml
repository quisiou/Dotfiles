// quickshell/shell/widgets/base/Calendar.qml


pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import ElysianShell.Themes

Item {
    ColumnLayout {
        anchors.fill: parent
        spacing: 4

        DayOfWeekRow {
            id: daysRow
            Layout.fillWidth: true
            locale: grid.locale
        }

        MonthGrid {
            id: grid
            Layout.fillWidth: true
            Layout.fillHeight: true
            month: (new Date()).getMonth()
            year: (new Date()).getFullYear()
            locale: Qt.locale()

            delegate: Item {
                id: dayCell
                required property var model

                implicitWidth: 44
                implicitHeight: 44

                Rectangle {
                    id: todayBubble
                    anchors.centerIn: parent
                    width: 34
                    height: 34
                    radius: width / 2
                    color: dayCell.model.today ? ActiveTheme.colors["ACCENT_LOW"] : "transparent"
                }

                Text {
                    anchors.centerIn: parent
                    text: dayCell.model.day
                    font.pixelSize: 16
                    color: {
                        if (dayCell.model.today)
                            return ActiveTheme.colors["BG"];
                        if (dayCell.model.month === grid.month)
                            return ActiveTheme.colors["FG_MUTED"];
                        return ActiveTheme.colors["BG_ACTIVE"];
                    }
                }
            }
        }
    }
}
