-- hypr/default/env.lua


----- ENVIRONMENT VARIABLES -------------------------------------------

hl.env("MOZ_ENABLE_WAYLAND", 1)
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("XCURSOR_THEME", "Adwaita")
hl.env("XCURSOR_SIZE", 24)
hl.env("HYPRCURSOR_SIZE", 24)
hl.env("HYPRSHOT_DIR", os.getenv("HOME") .. "/Pictures/Screenshots")

hl.env("STARSHIP_CONFIG", os.getenv("HOME") .. "/.config/starship/starship.toml")
hl.env("QML_IMPORT_PATH", os.getenv("HOME") .. "/.config/quickshell/.build/qml")
