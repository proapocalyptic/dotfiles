-- plugin_window_rules.lua — plugin-dependent window rules
-- Loaded by hyprland.lua startup polling after plugins are available

-- ---- HYPRBARS: off by default, selectively enabled below ----

hl.window_rule({
    name = "hyprbar-whitelist",
    match = { initial_title = "^(.*)$" },
    ["hyprbars:no_bar"] = true,
})

hl.window_rule({
    name = "kde-connect",
    match = { class = "^(org.kde.kdeconnect.*)$" },
    ["hyprbars:no_bar"] = false,
    tag = "comms",
})

hl.window_rule({
    name = "mail",
    match = { class = "^(thunderbird)$" },
    ["hyprbars:no_bar"] = false,
    size = { "(window_w*0.7)", "(window_h*0.7)" },
    tag = "comms",
})

hl.window_rule({
    name = "comms-styles",
    match = { tag = "comms" },
    workspace = "7",
})

hl.window_rule({
    name = "kitty-home-settings",
    match = { initial_class = "kitty-home" },
    ["hyprbars:no_bar"] = true,
    border_size = 4,
})

hl.window_rule({
    name = "scratcher-stylin",
    match = { class = "kitty-scratcher" },
    ["hyprbars:no_bar"] = true,
})

hl.window_rule({
    name = "access-stylin",
    match = { class = "kitty-access-menu" },
    ["hyprbars:no_bar"] = true,
})

hl.window_rule({
    name = "loudness-control",
    match = { class = "org.pulseaudio.pavucontrol" },
    ["hyprbars:no_bar"] = false,
})


-- ---- HYPRBARS TAG ROUTING ----

hl.window_rule({ match = { tag = "hyprbarred" },     tag = "+bars-toggle-on" })
hl.window_rule({ match = { tag = "not-hyprbarred" }, tag = "-bars-toggle-on" })
hl.window_rule({ match = { tag = "not-hyprbarred" }, tag = "-hyprbarred"     })

hl.window_rule({ match = { tag = "not-hyprbarred" }, tag = "+bars-toggle-off" })
hl.window_rule({ match = { tag = "hyprbarred" },     tag = "-bars-toggle-off" })
hl.window_rule({ match = { tag = "hyprbarred" },     tag = "-not-hyprbarred"  })

hl.window_rule({
    name = "hyprbar-off",
    match = { tag = "bars-toggle-on" },
    ["hyprbars:no_bar"] = false,
})
hl.window_rule({
    name = "hyprbar-on",
    match = { tag = "bars-toggle-off" },
    ["hyprbars:no_bar"] = true,
})
