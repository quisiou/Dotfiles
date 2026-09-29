-- hypr/default/autostart.lua


----- AUTO START CONFIGURATION -----------------------------

hl.on("hyprland.start", function()
    -- Stuff for screensharing
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")

    -- Wallpaper daemon
    hl.exec_cmd("awww-daemon")

    -- Shell
    hl.exec_cmd("quickshell -c shell")
end)
