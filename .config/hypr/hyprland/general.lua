-- general.lua — look & feel (was general.conf)

hl.config({
    general = {
        gaps_in = 4,
        gaps_out = 2,
        border_size = 2,
        col = {
            active_border = {
                colors = { "rgba(4A154Bff)", "rgba(D4A422ff)" },
                angle = 285,
            },
            inactive_border = {
                colors = { "rgba(ebdbb2ff)" },
            },
        },
        resize_on_border = true,
        allow_tearing = false,
        layout = "dwindle",
        snap = {
            enabled = true,
            window_gap = 24,
            monitor_gap = 2,
        },
    },
    decoration = {
        rounding = 0,
        rounding_power = 2,
        shadow = {
            enabled = true,
            range = 15,
            render_power = 3,
            offset = { 0, 3 },
            color = "rgba(0000001a)",
        },
        blur = {
            enabled = true,
            size = 3,
            passes = 2,
            vibrancy = 0.5696,
        },
    },
    animations = { enabled = true },
    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        close_special_on_empty = true,
        focus_on_activate = false,        -- confirmed: valid config key (hl.meta.lua:1197)
        mouse_move_enables_dpms = true,
        key_press_enables_dpms = true,
    },
    debug = {
        disable_logs = false,
    },

    xwayland = {
        force_zero_scaling = true,
    },
})




-- Bezier curves
hl.curve("emphasizedDecel", { type = "bezier", points = { {0.2, 0.7}, {0.1, 1.0} } } )
hl.curve("emphasizedAccel", { type = "bezier", points = { {0.3, 0.0},  {0.8, 0.15} } })
hl.curve("spring",          { type = "bezier", points = { {0.38, 1.21},{0.22, 1.0}  } })

-- Slow dramatic ease-in for layer fade-in; near-linear but lingering at the end
hl.curve("layerFadeIn",     { type = "bezier", points = { {0.0, 0.0},  {0.1, 1.0}  } })
-- Fast sharp ease-out for layer fade-out; punchy exit
hl.curve("layerFadeOut",    { type = "bezier", points = { {0.9, 0.0},  {1.0, 1.0}  } })

-- Animations

hl.animation({ leaf = "windowsIn",  enabled = true, speed = 2, bezier = "emphasizedDecel", style = "slide top" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 2, bezier = "emphasizedAccel", style = "slide top" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 4, bezier = "emphasizedDecel", style = "slide" })
hl.animation({ leaf = "windowsMove", tag = "joe", enabled = true, speed = 4, bezier = "emphasizedDecel", style = "slide" })
hl.animation({ leaf = "workspaces",  enabled = true, speed = 5, bezier = "emphasizedDecel", style = "fade" })
-- Layer open: pure fade, slow lingering reveal (speed=4 ≈ 400 ms)
hl.animation({ leaf = "layersIn",      enabled = true, speed = 4,  bezier = "layerFadeIn",  style = "fade" })
-- Layer close: fast opacity snap-out (speed=2 ≈ 200 ms)
hl.animation({ leaf = "layersOut",     enabled = true, speed = 100,  bezier = "layerFadeOut", style = "fade" })
-- Fade sub-leaves keep the same curves so opacity and geometry stay in sync
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 4,  bezier = "layerFadeIn"  })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 2,  bezier = "layerFadeOut" })
hl.animation({ leaf = "fadeIn",      enabled = true, speed = 3, bezier = "emphasizedDecel" })
hl.animation({ leaf = "fadeOut",     enabled = true, speed = 2, bezier = "emphasizedAccel" })
hl.animation({ leaf = "border",      enabled = true, speed = 8, bezier = "spring" })




hl.config({ ecosystem = { enforce_permissions = true } })
hl.permission({
    binary = "/usr/(bin|local/bin)/hyprpm",
    type   = "plugin",
    mode   = "allow",
})

--layouts
hl.config({
    master = {
        mfact = 0.50,
    }
})


