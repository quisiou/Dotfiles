/* quickshell/modules/Services/Visualizer/VisualizerService.qml */


pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // --- tunables ---
    property int    bars: 20
    property int    frameRate: 60
    property real   noiseReduction: 0.77   // 0-1, higher = smoother/laggier
    property real   sensitivity: 100       // % gain, only used if autosens is off
    property bool   autosens: true
    property bool   stereo: false
    property int    lowerCutoffFreq: 50
    property int    higherCutoffFreq: 10000

    // --- output ---
    property list<int> values: []

    // run only when something is actually bound/visible, set from visualizer widget's visibility
    property bool active: false

    Process {
        id: proc
        running: root.active
        command: ["sh", "-c", root._buildCommand()]
        stdout: SplitParser {
            onRead: data => {
                const raw = data.slice(0, -1).split(";").filter(s => s.length);
                root.values = raw.map(v => parseInt(v, 10));
            }
        }
    }

    function _buildCommand() {
        const cfg = [
            "[general]",
            `framerate=${root.frameRate}`,
            `bars=${root.bars}`,
            `autosens=${root.autosens ? 1 : 0}`,
            `sensitivity=${root.sensitivity}`,
            `noise_reduction=${root.noiseReduction}`,
            `lower_cutoff_freq=${root.lowerCutoffFreq}`,
            `higher_cutoff_freq=${root.higherCutoffFreq}`,
            "[output]",
            `channels=${root.stereo ? "stereo" : "mono"}`,
            "method=raw",
            "raw_target=/dev/stdout",
            "data_format=ascii",
            "ascii_max_range=100",
        ].join("\n");

        return `printf '${cfg}' | cava -p /dev/stdin`;
    }
}
