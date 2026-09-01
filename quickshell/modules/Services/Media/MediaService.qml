/* quickshell/modules/Services/Media/MediaService.qml */


pragma Singleton

import Quickshell
import Quickshell.Services.Mpris
import QtQuick

Singleton {
    id: root

    // Player-related
    readonly property bool      hasPlayer:  _player !== null
    readonly property string    app:        hasPlayer ? _player.desktopEntry : ""
    readonly property bool      isPlaying:  hasPlayer && _player.isPlaying
    readonly property bool      canRaise:   hasPlayer && _player.canRaise
    readonly property bool      canQuit:    hasPlayer && _player.canQuit
    function                    open()      { if (canRaise) _player.raise() }
    function                    quit()      { if (canQuit) _player.quit() }

    // Per-track meta info
    readonly property string title:     hasPlayer ? _player.trackTitle  : ""
    readonly property string album:     hasPlayer ? _player.trackAlbum  : ""
    readonly property string artist:    hasPlayer ? _player.trackArtist : ""
    readonly property string artUrl:    hasPlayer ? _player.trackArtUrl : ""

    // Per-track controls
    readonly property bool  canToggle:  hasPlayer && _player.canTogglePlaying
    readonly property bool  canPrev:    hasPlayer && _player.canGoPrevious
    readonly property bool  canNext:    hasPlayer && _player.canGoNext
    function                toggle()    { if (canToggle) _player.togglePlaying() }
    function                prev()      { if (canPrev) _player.previous() }
    function                next()      { if (canNext) _player.next() }

    // Per-track playing info
    property real           duration:       0
    property real           position:       0
    readonly property bool  canSeek:        hasPlayer && _player.canSeek && _player.positionSupported
    function                seek(newPos)    { if (canSeek) _player.seek(Math.max(0, Math.min(newPos, duration)) - position) }

    on_PlayerChanged: _refreshPlayback()
    
    Component.onCompleted: _refreshPlayback()

    // Refresh on track change (reset immediately, then re-sync once
    // postTrackChanged fires in case length/art arrived late).
    Connections {
        target: root._player
        enabled: root.hasPlayer
        function onTrackChanged()       { root.duration = 0; root.position = 0 }
        function onPostTrackChanged()   { root._refreshPlayback() }
    }

    // Keep `position` reactive without relying on the player pushing updates.
    // Per MPRIS docs, position only emits on nonlinear jumps otherwise.
    Timer {
        running: root.hasPlayer && root._player.playbackState === MprisPlaybackState.Playing
        interval: 1000
        repeat: true
        onTriggered: root._refreshPlayback()
    }


    // Internal properties and functions, not accessible from outside this singleton
    readonly property MprisPlayer   _player: {
        const players = Mpris.players.values
        for (let p of players)
            if (p.isPlaying) return p
        return players.length > 0 ? players[0] : null
    }

    function _refreshPlayback() {
        duration = hasPlayer ? _player.length   : 0
        position = hasPlayer ? _player.position : 0
    }
}
