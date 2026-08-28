-- hypr/default/look_and_feel.lua


----- LOOK AND FEEL CONFIGURATION -----------------------------

-- See https://wiki.hypr.land/Configuring/Variables/#general for more
-- See https://wiki.hypr.land/Configuring/Variables/#decoration for more
-- See https://wiki.hypr.land/Configuring/Variables/#blur for more

-- See https://wiki.hypr.land/Configuring/Animations/
-- See https://wiki.hypr.land/Configuring/Animations/#curves

-- See https://wiki.hypr.land/Configuring/Dwindle-Layout/ for more
-- See https://wiki.hypr.land/Configuring/Master-Layout/ for more
-- See https://wiki.hypr.land/Configuring/Variables/#misc for more

-- See https://wiki.hypr.land/Configuring/Workspace-Rules/ for more

-- See https://wiki.hypr.land/Configuring/Advanced-and-Cool/Tearing/ for more


hl.config({
    general = {
        gaps_in  = 5,
        gaps_out = 10,
        border_size = 0,

        -- Set to true to enable resizing windows by clicking and dragging on borders and gaps
        resize_on_border = false,
        allow_tearing = false,
        layout = "dwindle",
    },

    decoration = {
        rounding       = 18,
        rounding_power = 3,

        -- Change transparency of focused and unfocused windows
        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        shadow = {
            enabled      = true,
            range        = 5,
            render_power = 3,
            color        = tonumber("aa" .. (theme.colors.BG_FOCUSED):sub(2), 16),
        },

        blur = {
            enabled            = true,
            size               = 8,
            passes             = 3,
            new_optimizations  = true,
            xray               = false, -- true = blur only wallpaper; false = blur whatever's behind
            vibrancy           = 0.2,
            vibrancy_darkness  = 0.5,
            contrast           = 1.0,
            brightness         = 0.9,
            noise              = 0.02,
            special            = false,
        },
    },

    animations = {
        enabled = true,
    }
})


-- Curves and animations
hl.curve("easeOutQuint",    { type = "bezier", points = { {0.23, 1},    {0.32, 1}    } })
hl.curve("easeInOutCubic",  { type = "bezier", points = { {0.65, 0.05}, {0.36, 1}    } })
hl.curve("linear",          { type = "bezier", points = { {0, 0},       {1, 1}       } })
hl.curve("almostLinear",    { type = "bezier", points = { {0.5, 0.5},   {0.75, 1}    } })
hl.curve("quick",           { type = "bezier", points = { {0.15, 0},    {0.1, 1}     } })

hl.curve("easy",            { type = "spring", mass = 1, stiffness = 200, dampening = 30 }) -- Default springs

hl.animation({ leaf = "global",                 enabled = true, speed = 10,     bezier = "default"                              })
hl.animation({ leaf = "border",                 enabled = true, speed = 5.39,   bezier = "easeOutQuint"                         })
hl.animation({ leaf = "windows",                enabled = true, speed = 4.79,   spring = "easy"                                 })
hl.animation({ leaf = "windowsIn",              enabled = true, speed = 4.1,    spring = "easy",            style = "popin 87%" })
hl.animation({ leaf = "windowsOut",             enabled = true, speed = 1.49,   bezier = "linear",          style = "popin 87%" })
hl.animation({ leaf = "fadeIn",                 enabled = true, speed = 1.73,   bezier = "almostLinear"                         })
hl.animation({ leaf = "fadeOut",                enabled = true, speed = 1.46,   bezier = "almostLinear"                         })
hl.animation({ leaf = "fade",                   enabled = true, speed = 3.03,   bezier = "quick"                                })
hl.animation({ leaf = "layers",                 enabled = true, speed = 3.81,   bezier = "easeOutQuint"                         })
hl.animation({ leaf = "layersIn",               enabled = true, speed = 4,      bezier = "easeOutQuint",    style = "fade"      })
hl.animation({ leaf = "layersOut",              enabled = true, speed = 1.5,    bezier = "linear",          style = "fade"      })
hl.animation({ leaf = "fadeLayersIn",           enabled = true, speed = 1.79,   bezier = "almostLinear"                         })
hl.animation({ leaf = "fadeLayersOut",          enabled = true, speed = 1.39,   bezier = "almostLinear"                         })
hl.animation({ leaf = "workspaces",             enabled = true, speed = 1.94,   bezier = "almostLinear",    style = "slide"     })
hl.animation({ leaf = "workspacesIn",           enabled = true, speed = 1.94,   bezier = "almostLinear",    style = "slide"     })
hl.animation({ leaf = "workspacesOut",          enabled = true, speed = 1.94,   bezier = "almostLinear",    style = "slide"     })
hl.animation({ leaf = "specialWorkspace",       enabled = true, speed = 1.94,   bezier = "almostLinear",    style = "fade"      })
hl.animation({ leaf = "specialWorkspaceIn",     enabled = true, speed = 1.94,   bezier = "almostLinear",    style = "fade"      })
hl.animation({ leaf = "specialWorkspaceOut",    enabled = true, speed = 1.94,   bezier = "almostLinear",    style = "fade"      })
hl.animation({ leaf = "zoomFactor",             enabled = true, speed = 7,      bezier = "quick"                                })


-- Dwindle
hl.config({
    dwindle = {
        -- pseudotile = true,   -- Master switch for pseudotiling. Enabling is bound to mainMod + P
        preserve_split = true   -- You probably want this
    }
})


-- Master
hl.config({
    master = {
        new_status = "master",
    },
})


-- Miscellaneous
hl.config({
    misc = {
        disable_splash_rendering = true,
        force_default_wallpaper = 0,    -- Set to 0 or 1 to disable the anime mascot wallpapers
        disable_hyprland_logo   = true, -- If true disables the random hyprland logo / anime girl background. :(
    },
})


-- "Smart gaps" / "No gaps when only"
-- uncomment all if you wish to use that.
-- hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
-- hl.workspace_rule({ workspace = "f[1]",   gaps_out = 0, gaps_in = 0 })
-- hl.window_rule({
--     name  = "no-gaps-wtv1",
--     match = { float = false, workspace = "w[tv1]" },
--     border_size = 0,
--     rounding    = 0,
-- })
-- hl.window_rule({
--     name  = "no-gaps-f1",
--     match = { float = false, workspace = "f[1]" },
--     border_size = 0,
--     rounding    = 0,
-- })
