-- hypr/default/variables.lua


----- GENERAL HYPRLAND VARIABLES -----------------------------

-- See https://wiki.hypr.land/Configuring/ for more

local editor = os.getenv("EDITOR")
if editor == nil or editor == "" then
    editor = ""
end

Config = {
    mainMod     = "SUPER",
    terminal    = "kitty",
}
Config.editor           = Config.terminal .. " " .. editor
Config.fileManager      = Config.terminal .. " yazi"
Config.systemMonitor    = Config.terminal .. " btop"
