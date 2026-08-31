/* quickshell/shell/widgets/CallOSD.qml */


pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import ElysianShell.Themes

// qmllint disable uncreatable-type
PanelWindow {
// qmllint enable uncreatable-type
    id: panwin

    // anchor to a corner/edge — adjust to taste
    anchors {
        top: true
        left: true
    }

    // qmllint disable unqualified unresolved-type
    margins {
        top: 20
        left: 20
    }
    // qmllint enable unqualified unresolved-type

    // size the window itself — you'll likely want this to grow/shrink
    // with content once CallOSD has real visuals; for now, fix it
    implicitWidth: 400
    implicitHeight: 300

    color: "transparent" // so only your Rectangle/tiles show, not a solid backdrop

    WlrLayershell.layer:         WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    WlrLayershell.namespace:     "vesktop-overlay"
    exclusionMode:               ExclusionMode.Ignore

    mask: Region { item: null }

    Item {
        id: root

        // tiles[channelId][userId] = UserTile instance (the source of truth for "who's on screen")
        readonly property string imgCacheDir: Quickshell.cacheDir
        readonly property int animDuration: 150
        readonly property real noSpeakOpacity: 0.5
        property var tiles: ({})
        property var downloadQueue: []
        property bool downloading: false

        // Where tiles get parented once created — swap Column for whatever layout you want later
        Column {
            id: userContainer
            spacing: 15
        }

        Component {
            id: userTileComponent

            Item {
                id: tile

                property string userId: ""
                property string channelId: ""
                property string username: ""
                property string avatarUrl: ""
                property string avatarExt: ""
                property bool micro: false
                property bool audio: false
                property bool video: false
                property bool screen: false
                property bool speak: false

                property bool avatarReady: false

                implicitWidth: tileRow.implicitWidth
                implicitHeight: tileRow.implicitHeight
                width: implicitWidth
                height: implicitHeight

                Row {
                    id: tileRow
                    anchors.centerIn: parent
                    spacing: 5

                    ClippingRectangle {
                        id: avatarRect
                        width: avatarImg.width
                        height: avatarImg.height
                        radius: height / 2
                        anchors.verticalCenter: parent.verticalCenter

                        layer.enabled: true
                        opacity: tile.speak ? 1.0 : root.noSpeakOpacity
                        Behavior on opacity { NumberAnimation { duration: root.animDuration } }

                        // Avatar
                        Image {
                            id: avatarImg
                            anchors.verticalCenter: parent.verticalCenter
                            width: 32; height: 32
                            source: tile.avatarReady
                                ? (root.imgCacheDir + "/" + tile.userId + "-" + tile.username + "." + tile.avatarExt)
                                : ""
                            fillMode: Image.PreserveAspectFit
                            smooth: true
                        }

                        // Darken (not fade) when not speaking, Discord-style
                        Rectangle {
                            anchors.fill: avatarImg
                            color: "black"
                            opacity: tile.speak ? 0.0 : root.noSpeakOpacity / 2
                            Behavior on opacity { NumberAnimation { duration: root.animDuration } }
                        }
                    }

                    Rectangle {
                        readonly property int wPadding: 15
                        readonly property int hPadding: 10

                        width: nameRow.width + wPadding
                        height: nameRow.height + hPadding
                        color: ActiveTheme.colors["BG"].replace("#", "#C0")   // fixed, no more speak-based blending
                        radius: height / 2
                        anchors.verticalCenter: parent.verticalCenter

                        layer.enabled: true
                        opacity: tile.speak ? 1.0 : root.noSpeakOpacity
                        Behavior on opacity { NumberAnimation { duration: root.animDuration } }

                        Row {
                            id: nameRow
                            anchors.centerIn: parent
                            spacing: 5

                            // Username
                            Text {
                                id: nameText
                                anchors.verticalCenter: parent.verticalCenter
                                text: tile.username
                                color: ActiveTheme.colors["FG"]   // full color, no more fade
                                font {
                                    bold: true
                                    pixelSize: 12
                                }
                            }

                            // Microphone muted OSD
                            Image {
                                id: microOffImage
                                anchors.verticalCenter: parent.verticalCenter
                                width: 14; height: 14
                                source: Quickshell.shellDir + "/assets/icons/microphone-sensitivity-muted.svg"
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                visible: status === Image.Ready && !tile.micro
                            }

                            // Audio deafen OSD
                            Image {
                                id: audioOffImage
                                anchors.verticalCenter: parent.verticalCenter
                                width: 14; height: 14
                                source: Quickshell.shellDir + "/assets/icons/audio-volume-muted_noalpha.svg"
                                fillMode: Image.PreserveAspectFit
                                smooth: true
                                visible: status === Image.Ready && !tile.audio
                            }
                        }

                        // Darken the whole pill (bg + text + icons) at once when not speaking
                        Rectangle {
                            anchors.fill: parent
                            radius: parent.radius
                            color: "black"
                            opacity: tile.speak ? 0.0 : root.noSpeakOpacity / 2
                            Behavior on opacity { NumberAnimation { duration: root.animDuration } }
                        }
                    }

                    Rectangle {
                        readonly property int wPadding: 9
                        readonly property int hPadding: 3

                        width: videoScreenText.width + wPadding
                        height: videoScreenText.height + hPadding
                        color: "#ff0000"
                        radius: height / 2
                        anchors.verticalCenter: parent.verticalCenter
                        visible: tile.video || tile.screen
                        
                        layer.enabled: true
                        opacity: tile.speak ? 1.0 : root.noSpeakOpacity
                        Behavior on opacity { NumberAnimation { duration: root.animDuration } }

                        Text {
                            id: videoScreenText
                            anchors.centerIn: parent
                            text: "LIVE"
                            color: ActiveTheme.colors["FG"]
                            font {
                                bold: true
                                pixelSize: 8
                            }
                        }

                        // Darken instead of fade when not speaking
                        Rectangle {
                            anchors.fill: parent
                            radius: parent.radius
                            color: "black"
                            opacity: tile.speak ? 0.0 : root.noSpeakOpacity / 2
                            Behavior on opacity { NumberAnimation { duration: root.animDuration } }
                        }
                    }
                }
            }
        }

        // Called on "joined": creates the tile if it doesn't exist yet, returns it either way
        function getOrCreateTile(channelId, userId, initialProps) {
            if (!root.tiles[channelId]) root.tiles[channelId] = {}

            var tile = root.tiles[channelId][userId]
            if (!tile) {
                var props = Object.assign({ channelId: channelId, userId: userId }, initialProps || {})
                tile = userTileComponent.createObject(userContainer, props)
                root.tiles[channelId][userId] = tile
            } else if (initialProps) {
                for (var key in initialProps) tile[key] = initialProps[key]
            }
            return tile
        }

        // Called on "left": destroys the tile and cleans up empty channel entries
        function removeTile(channelId, userId) {
            var channelTiles = root.tiles[channelId]
            if (!channelTiles) return

            var tile = channelTiles[userId]
            if (tile) {
                tile.destroy()
                delete channelTiles[userId]
            }
            if (Object.keys(channelTiles).length === 0) {
                delete root.tiles[channelId]
            }
        }

        // Called on micro/audio/video/screen/speak: finds the existing tile and flips one property
        function updateTileState(channelId, userId, key, value) {
            var channelTiles = root.tiles[channelId]
            var tile = channelTiles ? channelTiles[userId] : null
            if (tile) tile[key] = value
        }

        // Handle avatar download if not cached
        function processQueue() {
            if (downloading || downloadQueue.length === 0) return
            downloading = true
            var job = downloadQueue.shift()
            checkImgCached.currentJob = job
            checkImgCached.imgDst = job.imgDst
            checkImgCached.running = true
        }

        function markAvatarReady(userId) {
            for (var chId in root.tiles) {
                var t = root.tiles[chId][userId]
                if (t) t.avatarReady = true
            }
        }

        function downloadAvatar(avatarURL, avatarExt, userID, username) {
            var base = avatarURL.split("?")[0]
            var query = avatarURL.indexOf("?") !== -1 ? avatarURL.substring(avatarURL.indexOf("?")) : ""
            var rewrittenUrl = base.replace(/\.[a-zA-Z0-9]+$/, "." + avatarExt) + query

            var dst = root.imgCacheDir + "/" + userID + "-" + username + "." + avatarExt
            downloadQueue.push({ imgSrc: rewrittenUrl, imgDst: dst, userId: userID })
            processQueue()
        }

        function handleData(data) {
            var msg
            try {
                msg = JSON.parse(data)
            } catch (e) {
                console.error("Failed to parse data:", e)
                return
            }

            switch (msg.type) {
            case "joined": {
                var rawExt = msg.avatarUrl.split("?")[0].split(".").pop()
                var isAnimated = msg.avatarUrl.indexOf("/a_") !== -1
                var avatarExt = isAnimated ? "gif" : "png"

                var tile = getOrCreateTile(msg.channelId, msg.userId, {
                    username: msg.username,
                    avatarUrl: msg.avatarUrl,
                    avatarExt: avatarExt
                })
                downloadAvatar(msg.avatarUrl, avatarExt, msg.userId, msg.username)
                break
            }

            case "left":
                removeTile(msg.channelId, msg.userId)
                break

            case "micro":
            case "audio":
            case "video":
            case "screen":
            case "speak":
                updateTileState(msg.channelId, msg.userId, msg.type, msg.status)
                break

            default:
                console.warn("Unknown message type:", msg.type)
            }
        }

        Socket {
            id: sock
            path: "/tmp/callstatusbridge.sock"
            connected: false

            parser: SplitParser {
                splitMarker: "\n"
                onRead: data => { root.handleData(data) }
            }

            onConnectedChanged: {
                if (connected) {
                    console.log("CallOSD: connected to bridge socket")
                } else {
                    console.log("CallOSD: lost connection to bridge socket, waiting for it to reappear")
                    sockWaiter.running = true
                }
            }
            // qmllint disable signal-handler-parameters
            onError: (error) => { console.warn("CallOSD: socket error:", error) }
            // qmllint enable signal-handler-parameters
        }

        Process {
            id: sockWaiter
            running: true
            command: [
                "bash", "-c",
                "until [ -S '" + sock.path + "' ]; do " +
                "inotifywait -qq -e create,moved_to '" + sock.path.substring(0, sock.path.lastIndexOf('/')) + "'; " +
                "done"
            ]
            // qmllint disable signal-handler-parameters
            onExited: (exitCode, exitStatus) => {
                console.log("CallOSD: bridge socket file appeared, connecting")
                sock.connected = true
            }
            // qmllint enable signal-handler-parameters
        }

        Process {
            id: checkImgCached
            running: false
            property string imgDst: ""
            property var currentJob: null
            command: [ "test", "-f", imgDst ]
            // qmllint disable signal-handler-parameters
            onExited: (exitCode) => {
                if (exitCode === 0) {
                    console.log("Profile picture already cached!")
                    root.markAvatarReady(currentJob.userId)
                    root.downloading = false
                    root.processQueue()
                } else {
                    console.log("Downloading profile picture from " + currentJob.imgSrc + " to " + currentJob.imgDst + "...")
                    imgDownload.currentJob = currentJob
                    imgDownload.imgSrc = currentJob.imgSrc
                    imgDownload.imgDst = currentJob.imgDst
                    imgDownload.running = true
                }
            }
            // qmllint enable signal-handler-parameters
        }

        Process {
            id: imgDownload
            running: false
            property string imgSrc: ""
            property string imgDst: ""
            property var currentJob: null
            command: ["curl", "-fsSL", "-o", imgDst, imgSrc]
            // qmllint disable signal-handler-parameters
            onExited: (exitCode) => {
                if (exitCode === 0) {
                    root.markAvatarReady(currentJob.userId)
                } else {
                    console.warn("CallOSD: avatar download failed for " + currentJob.userId + " (exit " + exitCode + ")")
                }
                root.downloading = false
                root.processQueue()
            }
            // qmllint enable signal-handler-parameters
        }
    }
}
