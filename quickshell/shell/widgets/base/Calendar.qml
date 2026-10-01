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
    color: "transparent"

    radius: 12

    // Single source of truth: year * 12 + month
    property int monthIndex: new Date().getFullYear() * 12 + new Date().getMonth()
    readonly property int currentMonth: ((monthIndex % 12) + 12) % 12
    readonly property int currentYear: Math.floor(monthIndex / 12)
    property var locale: Qt.locale("")

    property bool _aActive: true
    property int _lastIndex: monthIndex   // binding is broken in onCompleted

    readonly property real _scale: Math.max(0.6, Math.min(1.3, width / 320))

    function refreshLocale() {
        const d = new Date()
        monthIndex = d.getFullYear() * 12 + d.getMonth()
    }

    function goToPreviousMonth() { monthIndex -= 1 }
    function goToNextMonth()     { monthIndex += 1 }

    onMonthIndexChanged: {
        const dir = monthIndex > _lastIndex ? 1 : -1
        _lastIndex = monthIndex
        slideTo(dir)
    }

    function slideTo(dir) {
        const outgoing = _aActive ? gridA : gridB
        const incoming = _aActive ? gridB : gridA
        const h = gridSlot.height

        slideAnim.stop()

        incoming.idx = monthIndex
        incoming.y = dir * h          // next month: enters from below; prev: from above

        outOut.target = outgoing
        outOut.to = -dir * h
        inIn.target = incoming
        inIn.to = 0
        slideAnim.restart()

        _aActive = !_aActive
    }

    Component.onCompleted: _lastIndex = monthIndex

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

        // Shared month grid (used by both gridA and gridB)
        component DayGrid: MonthGrid {
            id: dg
            // Which month this grid shows (year * 12 + month); starts at the current one
            property int idx: root.monthIndex
            month: ((idx % 12) + 12) % 12
            year: Math.floor(idx / 12)
            width: parent ? parent.width : implicitWidth
            height: parent ? parent.height : implicitHeight
            topPadding: 4
            bottomPadding: 4
            locale: root.locale

            delegate: Item {
                id: dayCell
                required property var model

                implicitWidth: Math.round(30 * root._scale)
                implicitHeight: Math.round(30 * root._scale)

                Rectangle {
                    anchors.centerIn: parent
                    width: Math.round(28 * root._scale)
                    height: width
                    radius: width / 2
                    color: dayCell.model.today ? ActiveTheme.colors["ACCENT_LOW"] : "transparent"
                }

                Text {
                    anchors.centerIn: parent
                    text: dayCell.model.day
                    font.pixelSize: Math.round(14 * root._scale)
                    color: {
                        const dow = dayCell.model.date.getDay()
                        if (dayCell.model.today)
                            return ActiveTheme.colors["BG"]
                        if ((dow === 0 || dow === 6) && dayCell.model.month === dg.month)
                            return ActiveTheme.colors["ANSI_RED"]
                        if (dayCell.model.month === dg.month)
                            return ActiveTheme.colors["FG_LIGHT"]
                        return ActiveTheme.colors["FG_GHOST"]
                    }
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
                prev: () => { root.monthIndex -= 12 }
                next: () => { root.monthIndex += 12 }
            }
        }

        DayOfWeekRow {
            id: daysRow
            Layout.fillWidth: true
            locale: root.locale

            delegate: Text {
                required property var model
                horizontalAlignment: Text.AlignHCenter
                text: model.narrowName
                font.pixelSize: Math.round(15 * root._scale)
                font.bold: true
                color: ActiveTheme.colors["FG"]
            }
        }

        Item {
            id: gridSlot
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredWidth: gridA.implicitWidth
            Layout.preferredHeight: gridA.implicitHeight
            implicitWidth: gridA.implicitWidth
            implicitHeight: gridA.implicitHeight
            clip: true

            DayGrid { id: gridA; y: 0 }
            DayGrid { id: gridB; y: height }   // parked off-screen until needed

            ParallelAnimation {
                id: slideAnim
                NumberAnimation {
                    id: outOut
                    property: "y"
                    duration: 260
                    easing.type: Easing.InOutCubic
                }
                NumberAnimation {
                    id: inIn
                    property: "y"
                    duration: 260
                    easing.type: Easing.InOutCubic
                }
            }
        }
    }
}
