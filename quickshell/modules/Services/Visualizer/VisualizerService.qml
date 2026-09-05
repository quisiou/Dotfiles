/* quickshell/modules/Services/Visualizer/VisualizerService.qml */


pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // --- tunables ---
    property int    bars: 60
    property int    frameRate: 60
    property real   noiseReduction: 30   // lower than before — let our own envelope do the smoothing
    property real   sensitivity: 100
    property bool   autosens: true
    property bool   stereo: false
    property int    lowerCutoffFreq: 50
    property int    higherCutoffFreq: 10000
    property bool   monstercat: true

    // --- response shaping ---
    property real   curveGamma: 1.0     // >1 suppresses mid/quiet, keeps peaks punchy. try 2-3.5
    property real   attackSpeed: 1.0    // 0-1, 1.0 = instant reaction to a rising value
    property real   releaseSpeed: 0.18  // 0-1, lower = longer trailing decay after a hit

    // --- output ---
    property list<int>  values: []          // raw cava output, unchanged
    property list<real> envelope: []        // internal attack/release smoothed
    property list<real> displayValues: []   // final shaped output — bind visualizers to THIS

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
                const raw = data.slice(0, -1).split(";").filter(s => s.length).map(v => parseInt(v, 10))
                root.values = raw

                if (root.envelope.length !== raw.length) {
                    root.envelope = raw.slice()
                }

                const env = root.envelope.slice()
                for (let i = 0; i < raw.length; i++) {
                    const target = raw[i]
                    const rate = target > env[i] ? root.attackSpeed : root.releaseSpeed
                    env[i] = env[i] + (target - env[i]) * rate
                }
                root.envelope = env

                root.displayValues = env.map(v => {
                    const norm = Math.max(0, Math.min(1, v / 100))
                    return Math.pow(norm, root.curveGamma) * 100
                })
            }
        }
        stderr: SplitParser {
            onRead: data => console.log("[Visualizer][stderr]", data)
        }
    }
}
