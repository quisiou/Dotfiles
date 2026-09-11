-- hypr/default/variables.lua


----- GENERAL HYPRLAND VARIABLES -----------------------------

-- See https://wiki.hypr.land/Configuring/ for more

Config = {
    mainMod     = "SUPER",
    terminal    = "kitty",
}
Config.editor           = Config.terminal .. " " .. os.getenv("EDITOR")
Config.fileManager      = Config.terminal .. " yazi"
Config.systemMonitor    = Config.terminal .. " btop"
