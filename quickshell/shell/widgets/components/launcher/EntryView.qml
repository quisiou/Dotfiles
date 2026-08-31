/* quickshell/shell/widgets/components/launcher/EntryView.qml */


pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import ElysianShell.Themes

Item {
    id: root

    // ── Public API ────────────────────────────────────────────────────
    property var    model:        []
    property int    currentIndex: 0
    property string displayMode:         "items"   // "items" | "carousel" | (grid)

    signal closeRequested()
    signal activated(var entry)

    implicitWidth:  loader.item ? loader.item.implicitWidth  : 0
    implicitHeight: loader.item ? loader.item.implicitHeight : 0

    function positionAt(index) {
        if (loader.item && loader.item.positionAt)
            loader.item.positionAt(index)
    }

    Loader {
        id: loader
        anchors.fill: parent
        sourceComponent: {
            switch (root.displayMode) {
                case "carousel": return carouselDisplay
                default: return itemsDisplay
            }
        }
        onLoaded: {
            item.model = root.model
            item.currentIndex = Qt.binding(() => root.currentIndex)
        }
    }

    Connections {
        target: root
        function onModelChanged() {
            if (loader.item) loader.item.model = root.model
        }
    }

    Component {
        id: itemsDisplay

        Item {
            id: itemsRoot
            property var model:        []
            property int currentIndex: 0

            implicitWidth:  600 // 480 before
            implicitHeight: 360

            function positionAt(index) {
                listView.positionViewAtIndex(index, ListView.Contain)
            }

            ListView {
                id: listView
                anchors.fill: parent
                anchors.margins: 8
                spacing: 8
                clip: true

                readonly property int _animDuration: 200

                model: ScriptModel {
                    values: itemsRoot.model
                    objectProp: "id"
                }
                
                currentIndex: itemsRoot.currentIndex

                add:            Transition { NumberAnimation {
                    duration: listView._animDuration
                    easing.type: Easing.OutCubic
                    properties: "y"
                } }
                remove:         Transition { NumberAnimation {
                    duration: listView._animDuration
                    properties: "opacity"
                    from: 1
                    to: 0
                } }
                displaced:      Transition { NumberAnimation {
                    duration: listView._animDuration
                    easing.type: Easing.OutCubic
                    properties: "y"
                } }
                move:           Transition { NumberAnimation {
                    duration: listView._animDuration
                    easing.type: Easing.OutCubic
                    properties: "y"
                } }
                moveDisplaced:  Transition { NumberAnimation {
                    duration: listView._animDuration
                    easing.type: Easing.OutCubic
                    properties: "y"
                } }
                populate:       Transition { NumberAnimation {
                    duration: listView._animDuration
                    easing.type: Easing.OutCubic
                    properties: "y"
                } }

                delegate: Item {
                    id: entryItem
                    required property var modelData
                    required property int index
                    height: 52
                    width: ListView.view.width

                    Rectangle {
                        anchors.fill: parent
                        radius: 8
                        color: entryItem.index === itemsRoot.currentIndex ? ActiveTheme.colors["DARK4"]
                             : mouseArea.containsMouse           ? "#0fffffff"
                             : "transparent"

                        Rectangle {
                            visible: entryItem.modelData.isModeEntry ?? false
                            width: 3
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.margins: 6
                            color: ActiveTheme.colors["ACCENT_DIM"]
                            radius: 2
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            anchors.leftMargin: (entryItem.modelData.isModeEntry ?? false) ? 14 : 8
                            spacing: 12

                            Item {
                                Layout.preferredWidth: 32
                                Layout.preferredHeight: 32

                                Image {
                                    id: iconImage
                                    anchors.fill: parent
                                    source: entryItem.modelData.icon ?? ""
                                    fillMode: Image.PreserveAspectFit
                                    smooth: true
                                    visible: status === Image.Ready
                                }

                                Rectangle {
                                    anchors.fill: parent
                                    color: (entryItem.modelData.isModeEntry ?? false)
                                                ? ActiveTheme.colors["BG_TINTED"] : ActiveTheme.colors["BG_HIGHLIGHT"]
                                    radius: 4
                                    visible: iconImage.status !== Image.Ready

                                    Text {
                                        anchors.centerIn: parent
                                        text: entryItem.modelData.fallbackText ?? (entryItem.modelData.name ?? "").charAt(0).toUpperCase()
                                        color: (entryItem.modelData.isModeEntry ?? false)
                                                    ? ActiveTheme.colors["ACCENT_DIM"] : ActiveTheme.colors["FG"]
                                        font.pixelSize: 14
                                        font.weight: Font.Medium
                                    }
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    text: entryItem.modelData.name ?? ""
                                    color: (entryItem.modelData.isModeEntry ?? false)
                                            ? ActiveTheme.colors["ACCENT_DIM"] : ActiveTheme.colors["FG"]
                                    font.pixelSize: 14
                                    font.weight: Font.Medium
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }

                                Text {
                                    text: entryItem.modelData.comment ?? ""
                                    color: ActiveTheme.colors["FG_DARK"]
                                    font.pixelSize: 12
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                    visible: text !== ""
                                }
                            }

                            Text {
                                visible: entryItem.modelData.isModeEntry ?? false
                                text: "→"
                                color: ActiveTheme.colors["DARK4"]
                                font.pixelSize: 16
                            }
                        }

                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: {
                                root.activated(entryItem.modelData)
                                if (!(entryItem.modelData.stayOpen ?? false))
                                    root.closeRequested()
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: carouselDisplay

        Item {
            id: carouselRoot
            property var model:        []
            property int currentIndex: 0

            readonly property int itemSize: 180
            implicitWidth:  itemSize * 3 + 60
            implicitHeight: itemSize + 20

            function positionAt(index) { /* no-op — currentIndex binding already drives PathView */ }

            PathView {
                id: pathView
                anchors.fill: parent

                model:        carouselRoot.model
                currentIndex: carouselRoot.currentIndex
                interactive:  false   // see note below

                pathItemCount:  3
                cacheItemCount: 2
                snapMode: PathView.SnapToItem
                preferredHighlightBegin: 0.5
                preferredHighlightEnd:   0.5
                highlightRangeMode: PathView.StrictlyEnforceRange

                path: Path {
                    startY: pathView.height / 2
                    PathAttribute { name: "z"; value: 0 }
                    PathLine { x: pathView.width / 2; relativeY: 0 }
                    PathAttribute { name: "z"; value: 1 }
                    PathLine { x: pathView.width;      relativeY: 0 }
                }

                onCurrentIndexChanged: {
                    if (model && model.length > currentIndex && currentIndex >= 0) {
                        var activeData = model[currentIndex];
                        root.activated(activeData)
                    }
                }

                delegate: Item {
                    id: cell
                    required property var modelData

                    property real aspectRatio: 16 / 9

                    scale: 0.5
                    opacity: 0
                    z: cell.PathView.isCurrentItem ? 1 : 0

                    Component.onCompleted: {
                        scale   = Qt.binding(() => PathView.isCurrentItem ? 1 : PathView.onPath ? 0.7 : 0)
                        opacity = Qt.binding(() => PathView.onPath ? 1 : 0)
                    }

                    implicitHeight: 135
                    implicitWidth:  implicitHeight * aspectRatio

                    Behavior on scale   { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                    Behavior on opacity { NumberAnimation { duration: 220 } }

                    ClippingRectangle {
                        id: clipRect
                        anchors.fill: parent
                        radius: 12
                        color: "transparent"
                        contentInsideBorder: true 

                        Image {
                            id: carouselImg
                            anchors.fill: parent
                            source: cell.modelData.icon ?? ""
                            fillMode: Image.PreserveAspectCrop
                            smooth: true
                            asynchronous: true
                        }
                    }

                    MultiEffect {
                        id: shadowEffect
                        anchors.fill: clipRect
                        source: clipRect
                        
                        shadowEnabled: true
                        shadowColor: "#80000000" // Semi-transparent black
                        shadowBlur: 1.0          // Softness of the shadow
                        shadowHorizontalOffset: 0
                        shadowVerticalOffset: 6  // Push it down slightly for depth
                        
                        // Only show the shadow on the active center item
                        opacity: cell.PathView.isCurrentItem ? 1.0 : 0.0
                        Behavior on opacity { NumberAnimation { duration: 220 } }
                    }
                }
            }
        }
    }
}
