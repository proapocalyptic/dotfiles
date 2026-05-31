-- input.lua — input devices (was input.conf)

hl.config({
    input = {
        kb_layout = "us",
        kb_options = "caps:escape",

        follow_mouse = 1,
        sensitivity = 0,

        repeat_delay = 750,
        repeat_rate = 30,

        touchpad = {
            natural_scroll = false,
            tap_to_click = true,           -- NOTE: was `tap-to-click` in hyprlang
            clickfinger_behavior = true,
            disable_while_typing = false,
            drag_lock = false,
            scroll_factor = 1.0,
        },
    },
})
