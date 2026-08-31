/* quickshell/shell/widgets/base/NotificationCard.qml */

import QtQuick
import ElysianShell.Themes

Item {
    id: card

    property var entry: null
    property int timeoutMs: 5000

    readonly property int d:           60
    readonly property int bw:          2
    readonly property int panelWidth:  300
    readonly property int panelHeight: d

    implicitWidth:  panelWidth
    implicitHeight: d

    onEntryChanged: {
        if (entry !== null) {
            circle.scale     = 0.0
            viewport.opacity = 0.0
            introTimer.restart()
        }
    }

    // ── Accent colour ──────────────────────────────────────────────────────
    property color accentColor: {
        const cat = entry?.category ?? ""
        if (cat.includes("error"))    return ActiveTheme.colors["ERROR_LOW"]
        if (cat.includes("complete")) return ActiveTheme.colors["SUCCESS_MUTED"]
        if (cat.includes("warning"))  return ActiveTheme.colors["WARNING_LOW"]
        switch (entry?.urgency ?? 1) {
            case 0:  return ActiveTheme.colors["FG_DISABLED"]
            case 2:  return ActiveTheme.colors["URGENT"]
            default: return ActiveTheme.colors["ANSI_BLUE"]
        }
    }

    // ── Panel clip ─────────────────────────────────────────────────────────
    Item {
        id: viewport
        width: card.panelWidth - x
        height: card.panelHeight
        x: circle.x + (card.d / 2)  // Every part of the rectangle that is left of the circle will NOT be visible
        anchors.verticalCenter: parent.verticalCenter
        clip: true
    
        Item {
            id: infoRect
            width:  card.panelWidth
            height: card.panelHeight
            x: -viewport.x - circle.x   // When animating, it will move away from the center, mirroring the circle

            Rectangle {
                anchors.fill: parent
                radius:       card.panelHeight / 2
                color:        card.accentColor
            }

            Rectangle {
                anchors { fill: parent; margins: card.bw }
                radius: (card.panelHeight - card.bw * 2) / 2
                color:  ActiveTheme.colors["ANSI_BLACK"]

                Item {
                    anchors {
                        fill:         parent
                        leftMargin:   card.d * (6 / 5)
                        rightMargin:  24
                    }
                    clip: true

                    Item {
                        id: summaryItem
                        anchors {
                            left:                   parent.left
                            right:                  parent.right
                            verticalCenter:         parent.verticalCenter
                            verticalCenterOffset:   0
                        }
                        height: summaryText.height
                        opacity: 1.0

                        Text {
                            id: summaryText
                            visible:          text !== ""
                            text:             card.entry?.summary ?? ""
                            color:            ActiveTheme.colors["FG"]
                            font.pixelSize:   15
                            font.bold:        true
                            font.family:      "JetBrainsMono Nerd Font"
                            
                            anchors {
                                left:           parent.left
                                right:          parent.right
                                verticalCenter: parent.verticalCenter
                            }
                            
                            wrapMode:               Text.Wrap            // Enables text wrapping to the next line
                            maximumLineCount:       2                    // Caps the rendering at exactly 2 lines
                            elide:                  Text.ElideRight      // Adds "..." at the end of the second line if it overflows
                            horizontalAlignment:    Text.AlignLeft
                        }
                    }

                    Item {
                        id: bodyItem
                        anchors {
                            left:                   parent.left
                            right:                  parent.right
                            verticalCenter:         parent.verticalCenter
                            verticalCenterOffset:   card.panelHeight
                        }
                        height: bodyText.height
                        opacity: 1.0

                        Text {
                            id: bodyText
                            visible:          text !== ""
                            text:             card.entry?.body ?? ""
                            color:            ActiveTheme.colors["FG_DARK"]
                            font.pixelSize:   13
                            font.family:      "JetBrainsMono Nerd Font"
                            
                            anchors {
                                left:           parent.left
                                right:          parent.right
                                verticalCenter: parent.verticalCenter
                            }
                            
                            wrapMode:               Text.Wrap            // Enables text wrapping to the next line
                            maximumLineCount:       2                    // Caps the rendering at exactly 2 lines
                            elide:                  Text.ElideRight      // Adds "..." at the end of the second line if it overflows
                            horizontalAlignment:    Text.AlignLeft
                        }
                    }
                }   
            }
        }
    }

    // ── Circle ────────────────────────────────────────────────────────────
    Item {
        id: circle
        width:  card.d
        height: card.d
        x:      (card.panelWidth - card.d) / 2
        anchors.verticalCenter: parent.verticalCenter
        z: card.z + 1

        // Track ring (background)
        Rectangle {
            anchors.fill: parent
            radius:       width / 2
            color:        ActiveTheme.colors["BG_HIGHLIGHT"]
        }

        // Inner face
        Rectangle {
            anchors { fill: parent; margins: card.bw }
            radius: width / 2
            color:  ActiveTheme.colors["ANSI_BLACK"]

            Image {
                anchors.centerIn: parent
                width:  parent.width  - 12
                height: parent.height - 12
                source:   card.entry?.icon ?? ""
                fillMode: Image.PreserveAspectFit
                smooth:   true
                visible:  status !== Image.Error && source !== ""
            }

            Text {
                anchors.centerIn: parent
                text:    card.entry?.appName?.charAt(0)?.toUpperCase() ?? "?"
                color:   card.accentColor
                font.pixelSize: 20
                font.family:    "JetBrainsMono Nerd Font"
                visible: (card.entry?.icon ?? "") === ""
            }
        }

        // Radial progress arc
        Canvas {
            id: progressArc
            anchors.fill: parent

            // 1.0 = full ring → 0.0 = empty
            property real progress: 1.0
            onProgressChanged: requestPaint()

            property color arcColor: card.accentColor
            onArcColorChanged: requestPaint()

            onPaint: {
                var ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                var cx  = width  / 2
                var cy  = height / 2
                var r   = (Math.min(width, height) - card.bw) / 2
                var startAngle = -Math.PI / 2
                var endAngle   = startAngle + progress * 2 * Math.PI
                ctx.beginPath()
                ctx.arc(cx, cy, r, startAngle, endAngle, false)
                ctx.strokeStyle = arcColor
                ctx.lineWidth   = card.bw
                ctx.lineCap     = "round"
                ctx.stroke()
            }
        }
    }

    // ── Sequence ───────────────────────────────────────────────────────────

    Timer {
        id: introTimer
        interval: 80
        repeat:   false
        running:  false
        onTriggered: {
            circle.x             = (card.panelWidth - card.d) / 2
            progressArc.progress = 1.0
            lifecycleAnim.restart()
        }
    }

    SequentialAnimation {
        id: exitAnim
        running: false

        // 1.a Slide circle right; Slide infoRect left → hide panel
        NumberAnimation {
            target:      circle
            property:    "x"
            to:          (card.panelWidth - card.d) / 2
            duration:    400
            easing.type: Easing.InCubic
        }

        // 1.b viewport hidden again before circle shrinks
        PropertyAction {
            target: viewport;
            property: "opacity";
            value: 0.0
        }

        // 2. Circle shrinks
        NumberAnimation {
            target:      circle
            property:    "scale"
            from:        1.0
            to:          0.0
            duration:    300
            easing.type: Easing.InBack
        }

        onStopped: { if (!exitAnim.running) card.entry?.dismiss() }
    }

    SequentialAnimation {
        id: lifecycleAnim
        running: false

        // 1.a Circle grows from nothing
        NumberAnimation {
            target:      circle
            property:    "scale"
            from:        0.0
            to:          1.0
            duration:    300
            easing.type: Easing.OutBack
        }

        // 1.b Pause before sliding
        PauseAnimation { duration: 250 }

        // 1.c viewport becomes visible just before the slide begins
        PropertyAction {
            target: viewport;
            property: "opacity";
            value: 1.0
        }

        // 2. Slide circle left; Slide infoRect right → reveal panel
        NumberAnimation {
            target:      circle
            property:    "x"
            from:        (card.panelWidth - card.d) / 2
            to:          0
            duration:    400
            easing.type: Easing.OutCubic
        }

        // 3. Radial countdown + Text change
        ParallelAnimation {
            NumberAnimation {
                target:      progressArc
                property:    "progress"
                from:        1.0
                to:          0.0
                duration:    card.timeoutMs
                easing.type: Easing.Linear
            }

            SequentialAnimation {
                // First text stays there for 40% of the total countdown time
                PauseAnimation { duration: card.timeoutMs * (2 / 5) }

                // Push-up + fade in/out of both texts
                ParallelAnimation {
                    ParallelAnimation {
                        NumberAnimation {
                            target:      summaryItem
                            property:    "anchors.verticalCenterOffset"
                            from:        0
                            to:          -card.panelWidth
                            duration:    400
                            easing.type: Easing.InCubic
                        }
                        NumberAnimation {
                            target:      summaryItem
                            property:    "opacity"
                            from:        1.0
                            to:          0.0
                            duration:    400
                            easing.type: Easing.InCubic
                        }
                    }
                    ParallelAnimation {
                        NumberAnimation {
                            target:      bodyItem
                            property:    "anchors.verticalCenterOffset"
                            from:        card.panelWidth
                            to:          0
                            duration:    400
                            easing.type: Easing.OutCubic
                        }
                        NumberAnimation {
                            target:      bodyItem
                            property:    "opacity"
                            from:        0.0
                            to:          1.0
                            duration:    400
                            easing.type: Easing.InCubic
                        }
                    }
                }
            }
        }

        // 4. Run exit animation
        onStopped: { if (!lifecycleAnim.running) exitAnim.start() }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape:  Qt.PointingHandCursor
        onClicked: {
            const actions = card.entry?._notif?.actions ?? []
            const def = actions.find(a => a.identifier === "default")
            if (def) def.invoke()

            lifecycleAnim.stop()
            exitAnim.start()
        }
    }
}
