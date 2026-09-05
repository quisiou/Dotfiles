-- hypr/default/keybinds.lua


----- KEYBINDS CONFIGURATION -----------------------------

-- See https://wiki.hypr.land/Configuring/Binds/ for more


-- Essential for any Hyprland session (overridable)
hl.bind(Config.mainMod .. " + Q", hl.dsp.exec_cmd(Config.terminal .. " --hold fastfetch"))
hl.bind(Config.mainMod .. " + CTRL + ALT + E", hl.dsp.exec_cmd("hyprctl dispatch 'hl.dsp.exit()'"))
hl.bind(Config.mainMod .. " + E", hl.dsp.exec_cmd(Config.fileManager))

-- Useful app shortcuts
hl.bind(Config.mainMod .. " + F1", hl.dsp.exec_cmd(Config.systemMonitor))

-- Window management
hl.bind(Config.mainMod .. " + X", hl.dsp.window.close())
hl.bind(Config.mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(Config.mainMod .. " + P", hl.dsp.window.pseudo())
hl.bind(Config.mainMod .. " + Y", hl.dsp.layout("togglesplit"))    -- dwindle only
hl.bind(Config.mainMod .. " + F", hl.dsp.window.fullscreen())
hl.bind(Config.mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(Config.mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })



-- Switch focus between windows
hl.bind(Config.mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(Config.mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(Config.mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(Config.mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))


-- Workspace navigation and Move window to specific workspace
for i = 1, 9 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind(Config.mainMod .. " + " .. key,             hl.dsp.focus({ workspace = i}))
    hl.bind(Config.mainMod .. " + SHIFT + " .. key,     hl.dsp.window.move({ workspace = i }))
end


-- Special workspace (scratchpad)
hl.bind(Config.mainMod .. " + 0",         hl.dsp.workspace.toggle_special("magic"))
hl.bind(Config.mainMod .. " + SHIFT + 0", hl.dsp.window.move({ workspace = "special:magic" }))


-- Multimedia keys for volume and screen brightness (laptop)
hl.bind(
    "XF86AudioRaiseVolume",
    hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),
    { locked = true, repeating = true }
)
hl.bind(
    "XF86AudioLowerVolume",
    hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
    { locked = true, repeating = true }
)
hl.bind(
    "XF86AudioMute",
    hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
    { locked = true, repeating = true }
)
hl.bind(
    "XF86AudioMicMute",
    hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
    { locked = true, repeating = true }
)
hl.bind(
    "XF86MonBrightnessUp",
    hl.dsp.exec_cmd("brightnessctl -n2 set 5%+"),
    { locked = true, repeating = true }
)
hl.bind(
    "XF86MonBrightnessDown",
    hl.dsp.exec_cmd("brightnessctl -n2 set 5%-"),
    { locked = true, repeating = true }
)


-- Multimedia keys for media players (requires "playerctl" tool)
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   { locked = true })


-- Take screenshots
hl.bind("Print",                        hl.dsp.exec_cmd("hyprshot -m output"))
hl.bind(Config.mainMod .. " + Print",          hl.dsp.exec_cmd("hyprshot -m region"))  -- freeze
hl.bind(Config.mainMod .. " + SHIFT + Print",  hl.dsp.exec_cmd("hyprshot -m window"))


-- Eww topbar binds
hl.bind(Config.mainMod .. " + Space",      hl.dsp.exec_cmd("~/.config/eww/scripts/usrctl.sh"))
hl.bind(Config.mainMod .. " + mouse_up",   hl.dsp.exec_cmd("~/.config/eww/scripts/workspace_scroll.sh up"))
hl.bind(Config.mainMod .. " + mouse_down", hl.dsp.exec_cmd("~/.config/eww/scripts/workspace_scroll.sh down"))


-- Quickshell binds
hl.bind(
    Config.mainMod .. " + SUPER_L",
    hl.dsp.exec_cmd("qs -c shell ipc call controlMenu toggleLauncher"),
    { release = true }
)
hl.bind(
    Config.mainMod .. " + C",
    hl.dsp.exec_cmd("qs -c shell ipc call toggleSystemMenu handle")
)
hl.bind(
    "ALT + TAB",
    hl.dsp.exec_cmd("qs -c shell ipc call toggleTrayMenu handle")
)
hl.bind(
    Config.mainMod .. " + A",
    hl.dsp.exec_cmd("qs -c shell ipc call toggleQuickAppsMenu handle")
)
hl.bind(
    Config.mainMod .. " + Escape",
    hl.dsp.exec_cmd("qs -c shell ipc call controlMenu toggleSessionMenu")
)
hl.bind(
    Config.mainMod .. " + L",
    hl.dsp.exec_cmd("qs -c shell ipc call controlMenu lockSession")
)
hl.bind(
    Config.mainMod .. " + M",
    hl.dsp.exec_cmd("qs -c shell ipc call controlMenu openControlTab Media")
)
