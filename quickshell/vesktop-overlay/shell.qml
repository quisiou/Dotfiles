/* quickshell/shell/vesktop-overlay/shell.qml */


//@ pragma ShellId vesktop-overlay

import QtQuick
import Quickshell

ShellRoot {
    id: root

    Loader { source: "widgets/CallOSD.qml"; anchors.fill: parent }
}
