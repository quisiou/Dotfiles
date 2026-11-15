-- hypr/default/keybinds.lua


----- KEYBINDS CONFIGURATION -----------------------------

-- See https://wiki.hypr.land/Configuring/Binds/ for more


-- Wrapper function for binding (auto-description)
function BIND(keys, action, flags)
    flags = flags or {}
    if not flags.description then
        flags.description = "[UNDOCUMENTED] " .. keys
    end
    return hl.bind(keys, action, flags)
end


-- Essential for any Hyprland session (overridable)
BIND(
    Config.mainMod .. " + Q",
    hl.dsp.exec_cmd(Config.terminal .. " --hold fastfetch"),
    { description = "[Apps] Open terminal" }
)
BIND(
    Config.mainMod .. " + CTRL + ALT + E",
    hl.dsp.exec_cmd("hyprctl dispatch 'hl.dsp.exit()'"),
    { description = "[Session] Exit Session" }
)
BIND(
    Config.mainMod .. " + E",
    hl.dsp.exec_cmd(Config.fileManager),
    { description = "[Apps] Open file manager" }
)

-- Useful app shortcuts
BIND(
    Config.mainMod .. " + F1",
    hl.dsp.exec_cmd(Config.systemMonitor),
    { description = "[Apps] Open system monitor" }
)
BIND(
    Config.mainMod .. " + F2",
    hl.dsp.exec_cmd(Config.editor .. " " .. os.getenv("HOME")),
    { description = "[Apps] Open editor in home directory" }
)

-- Window management
BIND(
    Config.mainMod .. " + X",
    hl.dsp.window.close(),
    { description = "[Window] Close focused window" }
)
BIND(
    Config.mainMod .. " + V",
    hl.dsp.window.float({ action = "toggle" }),
    { description = "[Window] Toggle floating" }
)
BIND(
    Config.mainMod .. " + Y",
    hl.dsp.window.pseudo(),
    { description = "[Window] Toggle pseudotile" }
)
BIND(   -- dwindle only
    Config.mainMod .. " + T",
    hl.dsp.layout("togglesplit"),
    { description = "[Window] Toggle split direction" }
)
BIND(
    Config.mainMod .. " + F",
    hl.dsp.window.fullscreen(),
    { description = "[Window] Toggle fullscreen" }
)
BIND(
    Config.mainMod .. " + mouse:272",
    hl.dsp.window.drag(),
    { mouse = true, description = "[Window] Move window (drag)" }
)
BIND(
    Config.mainMod .. " + mouse:273",
    hl.dsp.window.resize(),
    { mouse = true, description = "[Window] Resize window (drag)" }
)



-- Switch focus between windows
BIND(
    Config.mainMod .. " + SHIFT + H",
    hl.dsp.focus({ direction = "left" }),
    { description = "[Window] Focus left" }
)
BIND(
    Config.mainMod .. " + SHIFT + J",
    hl.dsp.focus({ direction = "down" }),
    { description = "[Window] Focus down" }
)
BIND(
    Config.mainMod .. " + SHIFT + K",
    hl.dsp.focus({ direction = "up" }),
    { description = "[Window] Focus up" }
)
BIND(
    Config.mainMod .. " + SHIFT + L",
    hl.dsp.focus({ direction = "right" }),
    { description = "[Window] Focus right" }
)


-- Workspace navigation
local function scroll_workspace(direction)
    return function()
        local current = hl.get_active_workspace()
        if not current then return end

        -- find max workspace id, minimum 5
        local max_ws = 5
        for _, ws in ipairs(hl.get_workspaces()) do
            if ws.id > max_ws then max_ws = ws.id end
        end

        if direction == "up" and current.id < max_ws then
            hl.dispatch(hl.dsp.focus({ workspace = tostring(current.id + 1) }))
        elseif direction == "down" and current.id > 1 then
            hl.dispatch(hl.dsp.focus({ workspace = tostring(current.id - 1) }))
        end
    end
end

BIND(
    Config.mainMod .. " + mouse_up",
    scroll_workspace("up"),
    { description = "[Workspace] Next workspace (scroll)" }
)
BIND(
    Config.mainMod .. " + mouse_down",
    scroll_workspace("down"),
    { description = "[Workspace] Previous workspace (scroll)" }
)

for i = 1, 9 do
    BIND(
        Config.mainMod .. " + " .. i,
        hl.dsp.focus({ workspace = i}),
        { description = "[Workspace] Go to workspace " .. i }
    )
    BIND(
        Config.mainMod .. " + SHIFT + " .. i,
        hl.dsp.window.move({ workspace = i }),
        { description = "[Workspace] Move window to workspace " .. i }
    )
end


-- Special workspace (scratchpad)
BIND(
    Config.mainMod .. " + 0",
    hl.dsp.workspace.toggle_special("magic"),
    { description = "[Workspace] Toggle scratchpad" }
)
BIND(
    Config.mainMod .. " + SHIFT + 0",
    hl.dsp.window.move({ workspace = "special:magic" }),
    { description = "[Workspace] Move window to scratchpad" }
)


-- Multimedia keys for volume and screen brightness (laptop)
BIND(
    "XF86AudioRaiseVolume",
    hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),
    { locked = true, repeating = true, description = "[Audio] Volume up" }
)
BIND(
    "XF86AudioLowerVolume",
    hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),
    { locked = true, repeating = true, description = "[Audio] Volume down" }
)
BIND(
    "XF86AudioMute",
    hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),
    { locked = true, repeating = false, description = "[Audio] Mute audio" }
)
BIND(
    "XF86AudioMicMute",
    hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),
    { locked = true, repeating = false, description = "[Audio] Mute microphone" }
)
BIND(
    "XF86MonBrightnessUp",
    hl.dsp.exec_cmd("brightnessctl -n2 set 5%+"),
    { locked = true, repeating = true, description = "[Display] Brightness up" }
)
BIND(
    "XF86MonBrightnessDown",
    hl.dsp.exec_cmd("brightnessctl -n2 set 5%-"),
    { locked = true, repeating = true, description = "[Display] Brightness down" }
)


-- Multimedia keys for media players (requires "playerctl" tool)
BIND(
    "XF86AudioNext",
    hl.dsp.exec_cmd("playerctl next"),
    { locked = true, description = "[Media] Next track" }
)
BIND(
    "XF86AudioPause",
    hl.dsp.exec_cmd("playerctl play-pause"),
    { locked = true, description = "[Media] Play/pause" }
)
BIND(
    "XF86AudioPlay",
    hl.dsp.exec_cmd("playerctl play-pause"),
    { locked = true, description = "[Media] Play/pause" }
)
BIND(
    "XF86AudioPrev",
    hl.dsp.exec_cmd("playerctl previous"),
    { locked = true, description = "[Media] Previous track" }
)


-- Take screenshots
BIND(
    "Print",
    hl.dsp.exec_cmd("hyprshot -m output"),
    { description = "[Screenshot] Full screen" }
)
BIND(   -- freeze
    Config.mainMod .. " + Print",
    hl.dsp.exec_cmd("hyprshot -m region"),
    { description = "[Screenshot] Select region" }
)
BIND(
    Config.mainMod .. " + SHIFT + Print",
    hl.dsp.exec_cmd("hyprshot -m window"),
    { description = "[Screenshot] Select window" }
)


-- Quickshell binds
BIND(
    Config.mainMod .. " + SUPER_L",
    hl.dsp.exec_cmd("qs -c shell ipc call controlMenu toggleLauncher"),
    { release = true, description = "[Shell] Toggle app launcher" }
)
BIND(
    Config.mainMod .. " + C",
    hl.dsp.exec_cmd("qs -c shell ipc call toggleSystemMenu handle"),
    { description = "[Shell] Toggle system menu" }
)
BIND(
    "ALT + TAB",
    hl.dsp.exec_cmd("qs -c shell ipc call toggleTrayMenu handle"),
    { description = "[Shell] Toggle tray menu" }
)
BIND(
    Config.mainMod .. " + A",
    hl.dsp.exec_cmd("qs -c shell ipc call toggleQuickAppsMenu handle"),
    { description = "[Shell] Toggle quick apps menu" }
)
BIND(
    Config.mainMod .. " + Escape",
    hl.dsp.exec_cmd("qs -c shell ipc call controlMenu toggleSessionMenu"),
    { description = "[Shell] Toggle session menu" }
)
BIND(
    Config.mainMod .. " + L",
    hl.dsp.exec_cmd("qs -c shell ipc call controlMenu lockSession"),
    { description = "[Session] Lock screen" }
)
BIND(
    Config.mainMod .. " + D",
    hl.dsp.exec_cmd("qs -c shell ipc call controlMenu openControlTab Dashboard"),
    { description = "[Shell] Show dashboard (control center)" }
)
BIND(
    Config.mainMod .. " + M",
    hl.dsp.exec_cmd("qs -c shell ipc call controlMenu openControlTab Media"),
    { description = "[Shell] Show media (control center)" }
)
BIND(
    Config.mainMod .. " + P",
    hl.dsp.exec_cmd("qs -c shell ipc call controlMenu openControlTab Performance"),
    { description = "[Shell] Show performance (control center)" }
)
BIND(
    Config.mainMod .. " + S",
    hl.dsp.exec_cmd("qs -c shell ipc call controlMenu openControlTab System"),
    { description = "[Shell] Show system (control center)" }
)
