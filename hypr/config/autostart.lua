-- hypr/default/autostart.lua


----- AUTO START CONFIGURATION -----------------------------

hl.on("hyprland.start", function()
    -- Stuff for screensharing
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")

    -- Wallpaper daemon
    hl.exec_cmd("awww-daemon")

    -- Clipboard history daemon
    -- hl.exec_cmd("cliphist wipe")    -- Clear clipboard, as it persists across reboots
    hl.exec_cmd("wl-paste --type text  --watch cliphist -max-items 500 store")
    hl.exec_cmd("wl-paste --type image --watch cliphist -max-items 500 store")

    -- Shell
    hl.exec_cmd("quickshell -c shell")
end)
