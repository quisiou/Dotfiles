-- hypr/default/monitors.lua


----- MONITORS CONFIGURATION -----------------------------

-- See https://wiki.hypr.land/Configuring/Monitors/ for more


-- Monitor resolution, refresh rate and scaling
hl.monitor({
    output   = "",
    mode     = "preferred",
    position = "auto",
    scale    = 1.6,
})


-- unscale XWayland
hl.config({
    xwayland = {
        force_zero_scaling = true
    }
})
