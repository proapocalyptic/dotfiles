-- hyprland.lua — Lua entry point (Hyprland 0.55+)

-- ---establish emergency binds, built-in fallbacks are inconsistent---
hl.bind("SUPER + CTRL + ALT + SHIFT + M",
    hl.dsp.exec_cmd("sh -c 'command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch exit'"))



require("hyprland.env")
require("hyprland.monitors")
require("hyprland.input")
require("hyprland.general")
require("hyprland.autostart.auto-start_primary-services")

hl.layer_rule({
    match = { namespace = "waybar" },
    blur = true,
})

require("hyprland.autostart")
require("hyprland.keybindings")
require("hyprland.workspaces")
require("hyprland.window_rules")

-- Hide hyprbars early — best-effort (silently skipped on fresh boot before plugins load)
pcall(hl.window_rule, {
    name = "hyprbar-whitelist",
    match = { initial_title = "^(.*)$" },
    ["hyprbars:no_bar"] = true,
})

-- Load plugin-dependent configs after plugins are available
hl.timer(function()
    local hypr_dir = os.getenv("HOME") .. "/.config/hypr/hyprland"
    pcall(dofile, hypr_dir .. "/plugins.lua")
    pcall(dofile, hypr_dir .. "/plugin_window_rules.lua")
end, { timeout = 1500, type = "oneshot" })


