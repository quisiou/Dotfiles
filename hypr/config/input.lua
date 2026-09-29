-- hypr/default/input.lua


----- INPUT CONFIGURATION --------------------------- #

-- See https://wiki.hypr.land/Configuring/Variables/#input for more
-- See https://wiki.hypr.land/Configuring/Keywords/#per-device-input-configs for more
-- See https://wiki.hypr.land/Configuring/Gestures for more


-- Keyboard and mouse
hl.config({
    input = {
        kb_layout  = "es",
        kb_variant = "",
        kb_model   = "",
        kb_options = "",
        kb_rules   = "",

        follow_mouse = 1,

        sensitivity = 0, -- -1.0 - 1.0, 0 means no modification.

        touchpad = {
            natural_scroll = true,
        },

        numlock_by_default = true,

        repeat_delay = 400,
        repeat_rate = 30
    },
})


-- Touchpad gestures
hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace"
})
