/* quickshell/modules/Services/Visualizer/VisualizerService.qml */


pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // --- tunables ---
    property int    bars: 40
    property int    frameRate: 60
    property real   noiseReduction: 65   // 0-100, higher = smoother/laggier
    property real   sensitivity: 100       // % gain, only used if autosens is off
    property bool   autosens: true
    property bool   stereo: false
    property int    lowerCutoffFreq: 50
    property int    higherCutoffFreq: 10000
    property bool   monstercat: true

    // --- output ---
    property list<int> values: []

    // run only when something is actually bound/visible, set from visualizer widget's visibility
    property bool active: false
    onActiveChanged: root._restartProcess()

    readonly property string _cavaConfigFile: Quickshell.env("HOME") + "/.config/cava/config"

    function _buildCommand() {
        const cfg = [
            "[general]",
            `bars = ${root.bars}`,
            `framerate = ${root.frameRate}`,
            `autosens = ${root.autosens ? 1 : 0}`,
            `sensitivity = ${root.sensitivity}`,
            `lower_cutoff_freq = ${root.lowerCutoffFreq}`,
            `higher_cutoff_freq = ${root.higherCutoffFreq}`,
            `channels = ${root.stereo ? "stereo" : "mono"}`,
            "",
            "[input]",
            "method = pipewire",
            "source = auto",
            "",
            "[smoothing]",
            `monstercat = ${root.monstercat ? 1 : 0}`,
            `noise_reduction = ${root.noiseReduction}`,
            "",
            "[output]",
            "method = raw",
            "raw_target = /dev/stdout",
            "data_format = ascii",
            "ascii_max_range = 100"
        ].join("\n");
        return `printf '%s' '${cfg}' | cava -p /dev/stdin`;
    }
    
    function _restartProcess() {
        proc.running = false
        if (root.active) {
            proc.running = true
        }
    }

    FileView {
        path: root._cavaConfigFile
        watchChanges: true

        onFileChanged: reload()
        onTextChanged: root._restartProcess()
    }

    Process {
        id: proc
        command: ["sh", "-c", root._buildCommand()]
        stdout: SplitParser {
            onRead: data => {
                const raw = data.slice(0, -1).split(";").filter(s => s.length);
                root.values = raw.map(v => parseInt(v, 10));
            }
        }
        stderr: SplitParser {
            onRead: data => console.log("[Visualizer][stderr]", data)
        }
    }
}
