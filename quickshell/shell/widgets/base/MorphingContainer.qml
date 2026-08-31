/* quickshell/shell/widgets/base/MorphingContainer.qml */


import QtQuick
import QtQuick.Effects
import QtQuick.Shapes

Item {
    id: root

    readonly property int _animDuration: 200
    readonly property int _fadeDuration: _animDuration / 2
    readonly property var _easingType: Easing.InOutCubic

    property Component content: null
    property Item defaultItem: null

    property string _activeSlot: "default"   // "A" | "B" | "default"
    property bool _lastHeapWasA: true

    readonly property Item item: {
        switch (_activeSlot) {
            case "A": return loaderA.item as Item
            case "B": return loaderB.item as Item
            default:  return defaultItem
        }
    }

    signal morphFinished()

    // Non-animated shape toggle: false = rounded, true = flat rectangle
    property real cornerRadius: 20
    property bool square: false
    property var color: "#000000"
    readonly property real radius: square ? 0 : cornerRadius

    // Clamp so radii can never exceed half the box, and top+bottom can't exceed full height
    readonly property real _br: square ? 0 : Math.min(cornerRadius, width / 2, 3 * height / 5)
    readonly property real _tr: square ? 0 : Math.min(cornerRadius, width / 2, Math.max(height - _br, 0))

    property bool _morphing: false

    onContentChanged: {
        _morphing = true
        if (content === null) {
            _activeSlot = "default"
        } else {
            const incoming = _lastHeapWasA ? loaderB : loaderA
            incoming.sourceComponent = content
            _activeSlot = _lastHeapWasA ? "B" : "A"   // moved up, same value as `incoming`
            _lastHeapWasA = !_lastHeapWasA            // toggle last
        }
    }

    onDefaultItemChanged: {
        if (defaultItem) {
            defaultItem.parent = contentClip
            defaultItem.opacity = Qt.binding(() => root._activeSlot === "default" ? 1 : 0)
        }
    }

    width:  item ? item.implicitWidth  : width
    height: item ? item.implicitHeight : height

    Behavior on width  { NumberAnimation {
        id: widthAnim
        duration: root._animDuration
        easing.type: root._easingType
    }}
    Behavior on height { NumberAnimation {
        id: heightAnim
        duration: root._animDuration
        easing.type: root._easingType
    }}

    function _checkFinished() {
        if (_morphing && !widthAnim.running && !heightAnim.running) {
            _morphing = false
            morphFinished()
        }
    }

    Connections { target: widthAnim;  function onRunningChanged() { root._checkFinished() } }
    Connections { target: heightAnim; function onRunningChanged() { root._checkFinished() } }

    Shape {
        id: background
        anchors.fill: parent
        antialiasing: true
        preferredRendererType: Shape.CurveRenderer // smoother arcs, Qt 6.6+

        ShapePath {
            fillColor: root.color
            strokeWidth: 0

            startX: -root._tr
            startY: 0

            // top edge
            PathLine { x: root.width + root._tr; y: 0 }

            // top-right: concave (blends into the bar above)
            PathArc {
                x: root.width; y: root._tr
                radiusX: root._tr; radiusY: root._tr
                direction: PathArc.Counterclockwise
            }

            // right edge
            PathLine { x: root.width; y: root.height - root._br }

            // bottom-right: convex (pill)
            PathArc {
                x: root.width - root._br; y: root.height
                radiusX: root._br; radiusY: root._br
                direction: PathArc.Clockwise
            }

            // bottom edge
            PathLine { x: root._br; y: root.height }

            // bottom-left: convex (pill)
            PathArc {
                x: 0; y: root.height - root._br
                radiusX: root._br; radiusY: root._br
                direction: PathArc.Clockwise
            }

            // left edge
            PathLine { x: 0; y: root._tr }

            // top-left: concave (blends into the bar above)
            PathArc {
                x: -root._tr; y: 0
                radiusX: root._tr; radiusY: root._tr
                direction: PathArc.Counterclockwise
            }
        }

        layer.enabled: false
        // layer.effect: MultiEffect {
        //     shadowEnabled: true
        //     shadowColor: "#80000000"
        //     shadowBlur: 0.8
        //     shadowHorizontalOffset: 0
        //     shadowVerticalOffset: 3
        //     autoPaddingEnabled: true
        // }
    }

    Item {
        id: contentClip
        anchors.fill: parent
        clip: true

        Loader {
            id: loaderA
            anchors.fill: parent
            opacity: root._activeSlot === "A" ? 1 : 0
            Behavior on opacity {
                NumberAnimation {
                    id: fadeAnimA
                    duration: root._fadeDuration
                    easing.type: root._easingType
                    onRunningChanged: if (!running && loaderA.opacity === 0) loaderA.sourceComponent = null
                }
            }
        }
        Loader {
            id: loaderB
            anchors.fill: parent
            opacity: root._activeSlot === "B" ? 1 : 0
            Behavior on opacity {
                NumberAnimation {
                    id: fadeAnimB
                    duration: root._fadeDuration
                    easing.type: root._easingType
                    onRunningChanged: if (!running && loaderB.opacity === 0) loaderB.sourceComponent = null
                }
            }
        }
    }
}
