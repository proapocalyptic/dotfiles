-- plugins.lua — plugin configuration (was plugins.conf)
-- Loaded by hyprland.lua startup polling after plugins are available.

--
-- hl.plugin.hyprbars.add_button(
-- bg_color = "rgb(741324)",
--     fg_color = "rgb(ffffff)",
--     size = 10,
    -- icon = "X",
    -- action = "hyprctl eval 'hl.dispatch(hl.dsp.window.kill())'",
-- })

-- hl.plugin.hyprbars.add_button({
--    bg_color = "rgb(fea001)",
--     fg_color = "rgb(000000)",
--     size = 10,
--     icon = "_",
--     action = "hyprctl dispatch fullscreen 1",
-- })


-- if hl.plugin.hyprtasking ~= nil then
--   hl.config({
--   plugin = {
--     hyprtasking = {
--       layout = "grid",
--
--       gap_size = 4,
--       bg_color = 0x990000ff,
--       border_size = 2,
--       exit_on_hovered = false,
--       warp_on_move_window = 1,
--       close_overview_on_reload = false,
--
--       -- for other mouse buttons see <linux/input-event-codes.h>
--       drag_button = 0x111,   -- left mouse button
--       select_button = 0x110, -- right mouse button
--
--       jump = {
--         enabled = false,
--         label_color = 0xffffffff,
--         label_background = 0x000000cc,
--         label_size = 32,
--       },
--
--       gestures = {
--         enabled = false,
--         move_fingers = 3,
--         move_distance = 300,
--         open_fingers = 4,
--         open_distance = 300,
--         open_positive = true,
--       },
--
--       grid = {
--         rows = 1,
--         cols = 4,
--         loop = false,
--         layers = 3,
--         loop_layers = true,
--         gaps_use_aspect_ratio = true,
--       },
--
--       linear = {
--         top = true,
--         height = 400,
--         scroll_speed = 1.0,
--         blur = false,
--       }
--     }
--   },
-- })
-- end
--





if hl.hyprglass ~= nil then
local hg = hl.plugin.hyprglass

hg.config({
    default_theme = "dark",
    default_preset = "glass",
    tint_color = 0x8899aa22,
    adaptive_dim = 0,

  brightness = 0.9,
  dark = { brightness = 0.82 },
  light = { adaptive_boost = 0.5 },

    layers = { enabled = 1 },
})

-- Layer surfaces: each call whitelists the namespace and configures it
 hg.layer("waybar", { preset = "subtle", mask_threshold = 0.05 })
 hg.layer("swaync")
 hg.layer("quickshell:bezel", { preset = "ui", mask_threshold = 0.3 })
hg.layer("debug-panel", { exclude = true }
hg.layer("hyprtasking", {exlude = true}))

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
    dark = { tint_color = 0x02142aa8 },
})
end


