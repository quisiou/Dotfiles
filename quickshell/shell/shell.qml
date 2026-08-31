/* quickshell/shell/shell.qml */


import QtQuick
import Quickshell
import Quickshell.Io
import "widgets" as Widgets

ShellRoot {
    id: root

    // ── Typed proxies for loaded menu items ─────────────────────────────
    readonly property Widgets.SystemMenu    systemMenu:     systemMenuLoader.item       as Widgets.SystemMenu
    readonly property Widgets.TrayMenu      trayMenu:       trayMenuLoader.item         as Widgets.TrayMenu
    readonly property Widgets.QuickAppsMenu quickAppsMenu:  quickAppsMenuLoader.item    as Widgets.QuickAppsMenu
    readonly property Widgets.ControlMenu   controlMenu:    controlMenuLoader.item      as Widgets.ControlMenu

    Loader {
        source: "widgets/ThemeLoader.qml"
    }

    Loader {
        id: systemMenuLoader
        active: false
        source: "widgets/SystemMenu.qml"
        visible: false

        onItemChanged: {
            let menu = item as Widgets.SystemMenu
            if (menu) {
                menu.menuClosed.connect(() => systemMenuLoader.active = false)
                menu.lockRequested.connect(() => root.controlMenu.lockSession())
            }
        }
    }

    Loader {
        id: trayMenuLoader
        active: false
        source: "widgets/TrayMenu.qml"
        visible: false

        onItemChanged: {
            let menu = item as Widgets.TrayMenu
            if (menu) menu.menuClosed.connect(() => trayMenuLoader.active = false)
        }
    }

    Loader {
        id: quickAppsMenuLoader
        active: false
        source: "widgets/QuickAppsMenu.qml"
        visible: false

        onItemChanged: {
            let menu = item as Widgets.QuickAppsMenu
            if (menu) menu.menuClosed.connect(() => quickAppsMenuLoader.active = false)
        }
    }

    Loader {
        active: true
        source: "widgets/NotificationDisplay.qml"
    }

    Loader {
        id: controlMenuLoader
        active: true
        source: "widgets/ControlMenu.qml"
    }


    function closeOtherMenus(exceptLoader) {
        if (exceptLoader !== controlMenuLoader)
            root.controlMenu.reset()
        if (exceptLoader !== systemMenuLoader && root.systemMenu?.visible)
            root.systemMenu.closeMenu()
        if (exceptLoader !== trayMenuLoader && root.trayMenu?.visible)
            root.trayMenu.closeMenu()
        if (exceptLoader !== quickAppsMenuLoader && root.quickAppsMenu?.visible)
            root.quickAppsMenu.closeMenu()
    }

    IpcHandler {
        target: "toggleSystemMenu"
        function handle(): void {
            if (!systemMenuLoader.active)
                systemMenuLoader.active = true
            if (!root.systemMenu) return
            if (!root.systemMenu.visible) {
                root.closeOtherMenus(systemMenuLoader)
                root.systemMenu.openMenu()
            }
            else {
                root.systemMenu.closeMenu()
            }
        }
    }

    IpcHandler {
        target: "toggleTrayMenu"
        function handle(): void {
            if (!trayMenuLoader.active)
                trayMenuLoader.active = true
            if (!root.trayMenu) return
            if (!root.trayMenu.visible) {
                root.closeOtherMenus(trayMenuLoader)
                root.trayMenu.openMenu()
            }
            else {
                root.trayMenu.closeMenu()
            }
        }
    }

    IpcHandler {
        target: "toggleQuickAppsMenu"
        function handle(): void {
            if (!quickAppsMenuLoader.active)
                quickAppsMenuLoader.active = true
            if (!root.quickAppsMenu) return
            if (!root.quickAppsMenu.visible) {
                root.closeOtherMenus(quickAppsMenuLoader)
                root.quickAppsMenu.openMenu()
            }
            else {
                root.quickAppsMenu.closeMenu()
            }
        }
    }

    IpcHandler {
        target: "controlMenu"
        function toggleLauncher(): void {
            root.closeOtherMenus(controlMenuLoader)
            root.controlMenu.toggleLauncher()
        }
        function toggleSessionMenu(): void {
            root.closeOtherMenus(controlMenuLoader)
            root.controlMenu.toggleSessionMenu()
        }
        function lockSession(): void {
            root.closeOtherMenus(controlMenuLoader)
            root.controlMenu.lockSession()
        }
        function reset(): void {
            root.closeOtherMenus(controlMenuLoader)
            root.controlMenu.reset()
        }
        function askPass(prompt: string, pipe: string): void {
            root.closeOtherMenus(controlMenuLoader)
            root.controlMenu.askPass(prompt, pipe)
        }
    }
}
