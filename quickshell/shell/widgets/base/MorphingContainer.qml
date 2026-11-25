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

    property real cornerRadius: 20
    property bool isPill: false                 // TARGET shape: false = lip, true = pill
    property int  pillMorphDuration: 300
    property real earPhase: 0.25

    property var  color: "#000000"

    // 0 = lip, 1 = pill. Animated, so the shape morphs instead of snapping.
    property real _p: isPill ? 1 : 0
    Behavior on _p { NumberAnimation { duration: root.pillMorphDuration; easing.type: Easing.OutCubic } }

    readonly property real _earK: Math.max(0, 1 - _p / earPhase)                  // 1 -> 0 over p in [0, earPhase]
    readonly property real detach: Math.max(0, (_p - earPhase) / (1 - earPhase))

    readonly property real _pillR: Math.min(cornerRadius, width / 2, height / 2)
    readonly property real _brLip: Math.min(cornerRadius, width / 2, 3 * height / 5)
    readonly property real _trLip: Math.min(cornerRadius, width / 2, Math.max(height - _brLip, 0))

    // Clamp so radii can never exceed half the box, and top+bottom can't exceed full height
    readonly property real _br:    _brLip + (_pillR - _brLip) * _p   // bottom corners
    readonly property real _ear:   _trLip * _earK                    // concave top radius
    readonly property real _round: _pillR * detach                   // convex top radius
    readonly property real _tr:    _ear + _round                     // only one is non-zero at a time

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
            defaultItem.enabled = Qt.binding(() => root._activeSlot === "default")
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
        if (_morphing && !widthAnim.running && !heightAnim.running)
            _morphing = false
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

            startX: root._round - root._ear
            startY: 0

            // top edge
            PathLine { x: root.width - root._round + root._ear; y: 0 }

            // top-right: concave while p < 0.5, convex after
            PathArc {
                x: root.width; y: root._tr
                radiusX: root._tr; radiusY: root._tr
                direction: root._round > 0 ? PathArc.Clockwise : PathArc.Counterclockwise
            }

            // right edge
            PathLine { x: root.width; y: root.height - root._br }

            // bottom-right: convex
            PathArc {
                x: root.width - root._br; y: root.height
                radiusX: root._br; radiusY: root._br
                direction: PathArc.Clockwise
            }

            // bottom edge
            PathLine { x: root._br; y: root.height }

            // bottom-left: convex
            PathArc {
                x: 0; y: root.height - root._br
                radiusX: root._br; radiusY: root._br
                direction: PathArc.Clockwise
            }

            // left edge
            PathLine { x: 0; y: root._tr }

            // top-left: concave while p < 0.5, convex after
            PathArc {
                x: root._round - root._ear; y: 0
                radiusX: root._tr; radiusY: root._tr
                direction: root._round > 0 ? PathArc.Clockwise : PathArc.Counterclockwise
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
