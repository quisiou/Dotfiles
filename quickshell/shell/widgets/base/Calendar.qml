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

        component NavButton: Rectangle {
            id: navBtn
            property alias text: navText.text
            signal clicked()
            Layout.preferredWidth: 20
            Layout.preferredHeight: 20
            radius: 4
            color: navMouseArea.containsMouse ? ActiveTheme.colors["ACCENT_LOW"] : "transparent"

            Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.InOutCubic } }

            Text {
                id: navText
                anchors.centerIn: parent
                font.pixelSize: Math.round(16 * root._scale)
                font.bold: true
                color: navMouseArea.containsMouse ? ActiveTheme.colors["BG"] : ActiveTheme.colors["FG"]

                Behavior on color { ColorAnimation { duration: 150; easing.type: Easing.InOutCubic } }
            }

            MouseArea {
                id: navMouseArea
                cursorShape: Qt.PointingHandCursor
                anchors.fill: parent
                hoverEnabled: true
                onClicked: navBtn.clicked()
            }
        }

        component NavLabel: RowLayout {
            id: navLabelRow
            spacing: 0

            property string text: ""
            property var prev: () => {}
            property var next: () => {}
            property int direction: 1

            NavButton {
                text: "\u2039"
                onClicked: {
                    navLabelRow.direction = -1
                    navLabelRow.prev()
                }
            }

            Item {
                id: textSlot
                Layout.fillWidth: true
                Layout.preferredHeight: outText.implicitHeight
                clip: true

                Text {
                    id: outText
                    anchors.verticalCenter: parent.verticalCenter
                    width: textSlot.width
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: Math.round(14 * root._scale)
                    font.bold: true
                    color: ActiveTheme.colors["FG"]
                }

                Text {
                    id: inText
                    anchors.verticalCenter: parent.verticalCenter
                    width: textSlot.width
                    horizontalAlignment: Text.AlignHCenter
                    font.pixelSize: Math.round(14 * root._scale)
                    font.bold: true
                    color: ActiveTheme.colors["FG"]
                    visible: false
                }

                NumberAnimation {
                    id: outAnim
                    target: outText
                    property: "x"
                    duration: 220
                    easing.type: Easing.InOutCubic
                    onStopped: {
                        outText.text = inText.text
                        outText.x = 0
                        inText.visible = false
                    }
                }

                NumberAnimation {
                    id: inAnim
                    target: inText
                    property: "x"
                    duration: 220
                    easing.type: Easing.InOutCubic
                }

                Component.onCompleted: outText.text = navLabelRow.text
            }

            onTextChanged: {
                if (outText.text === text) return

                inText.text = text
                inText.x = direction > 0 ? textSlot.width : -textSlot.width
                inText.visible = true

                outAnim.to = direction > 0 ? -textSlot.width : textSlot.width
                inAnim.to = 0

                outAnim.restart()
                inAnim.restart()
            }

            NavButton {
                text: "\u203A"
                onClicked: {
                    navLabelRow.direction = 1
                    navLabelRow.next()
                }
            }
        }

        RowLayout {
            id: headerRow
            Layout.fillWidth: false
            Layout.preferredWidth: parent.implicitWidth * 0.8
            Layout.alignment: Qt.AlignHCenter
            spacing: 0

            NavLabel {
                text: root.locale.monthName(root.currentMonth, Locale.ShortFormat)
                prev: root.goToPreviousMonth
                next: root.goToNextMonth
            }

            Item { Layout.fillWidth: true }

            NavLabel {
                text: root.currentYear
                prev: () => { root.currentYear -= 1 }
                next: () => { root.currentYear += 1 }
            }
        }

        DayOfWeekRow {
            id: daysRow
            Layout.fillWidth: true
            locale: grid.locale

            delegate: Text {
                required property var model
                horizontalAlignment: Text.AlignHCenter
                text: model.narrowName
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
                        let dayOfWeek = dayCell.model.date.getDay()

                        if (dayCell.model.today)
                            return ActiveTheme.colors["BG"];
                        if ((dayOfWeek === 0 || dayOfWeek === 6) && dayCell.model.month === grid.month)
                            return ActiveTheme.colors["ANSI_RED"]
                        if (dayCell.model.month === grid.month)
                            return ActiveTheme.colors["FG_LIGHT"];
                        return ActiveTheme.colors["FG_GHOST"];
                    }
                }
            }
        }
    }
}
