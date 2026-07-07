-- plugins.lua — plugin configuration (was plugins.conf)
-- Loaded by hyprland.lua startup polling after plugins are available.

hl.config({
    plugin = {
        hyprbars = {
            bar_height = 20,
            on_double_click = "hyprctl dispatch fullscreen 1",
        },
    },
})

hl.plugin.hyprbars.add_button({
    bg_color = "rgb(741324)",
    fg_color = "rgb(ffffff)",
    size = 10,
    icon = "X",
    action = "hyprctl eval 'hl.dispatch(hl.dsp.window.kill())'",
})

hl.plugin.hyprbars.add_button({
    bg_color = "rgb(fea001)",
    fg_color = "rgb(000000)",
    size = 10,
    icon = "_",
    action = "hyprctl dispatch fullscreen 1",
})


if hl.plugin.hyprglass then
    local hg = hl.plugin.hyprglass

    hg.config({
        default_theme = "dark",
        default_preset = "clear",
        tint_color = 0x8899aa22,

        brightness = 0.9,
        dark = { brightness = 0.82 },
        light = { adaptive_boost = 0.5 },

        layers = { enabled = 1 },
    })

    -- Layer surfaces: each call whitelists the namespace and configures it
    hg.layer("waybar", { preset = "subtle", mask_threshold = 0.05 })
    hg.layer("swaync")
    hg.layer("quickshell:bezel", { preset = "ui", mask_threshold = 0.3 })
    hg.layer("debug-panel", { exclude = true })

    -- Presets
    hg.preset("clear", {
        glass_opacity = 0.8,
        blur_strength = 1.5,
        dark = { brightness = 0.7 },
        light = { brightness = 1.2 },
    })

    hg.preset("contrasted", {
        inherits = "high_contrast",
        contrast = 1.2,
        adaptive_dim = 1.5,
        dark = { tint_color = 0x02142aa9 },
    })
end
