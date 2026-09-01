/* quickshell/modules/Services/Volume/VolumeService.qml */


pragma Singleton

import Quickshell
import Quickshell.Services.Pipewire
import QtQuick

Singleton {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted:  sink?.audio?.muted  ?? false

    property bool _settled: false

    signal osdRequested()

    PwObjectTracker { objects: root.sink ? [root.sink] : [] }

    // Re-arm the guard whenever the sink itself changes (startup, device
    // swap) — Pipewire.ready only means "initial sync is done", the sink's
    // own node can still renegotiate volume/mute shortly after that.
    onSinkChanged: {
        root._settled = false
        settleTimer.restart()
    }

    Connections {
        target: Pipewire
        function onReadyChanged() {
            if (Pipewire.ready) {
                root._settled = false
                settleTimer.restart()
            }
        }
    }

    Timer {
        id: settleTimer
        interval: 250
        onTriggered: root._settled = true
    }

    Connections {
        target: root.sink?.audio ?? null

        function onVolumeChanged() {
            if (!Pipewire.ready || !root._settled) return
            root.osdRequested()
        }

        function onMutedChanged() {
            if (!Pipewire.ready || !root._settled) return
            root.osdRequested()
        }
    }

    function setVolume(v: real): void {
        if (sink?.audio) sink.audio.volume = v
    }

    function toggleMute(): void {
        if (sink?.audio) sink.audio.muted = !sink.audio.muted
    }
}
