-- window_rules.lua — window & layer rules (was window-forms.conf)

-- ---- LAYER RULES ----
hl.layer_rule({ match = { namespace = "waybar" }, blur = true })


-- ---- GLOBAL DEFAULTS ----

hl.window_rule({
    name = "suppress-maximize-events",
    match = { class = ".*" },
    suppress_event = "maximize",
})

hl.window_rule({
    name = "fix-xwayland-drags",
    match = { class = "^$", title = "^$", xwayland = true, float = true, fullscreen = false, pin = false },
    no_focus = true,
})


-- ---- PINNED OVERLAYS ----

hl.window_rule({
    name = "firefox-pip",
    match = { title = "^(Picture-in-Picture)$", class = "^(firefox)$" },
    float = true, pin = true,
    size = { "480", "270" }, move = { "2", "156" },
    animation = "slidedown",
})

hl.window_rule({
    name = "vivaldi-pip",
    match = { title = "Picture in picture" },
    float = true, pin = true,
    size = { "480", "270" }, move = { "7", "121" },
    animation = "slidedown",
})

hl.window_rule({
    name = "clipse",
    match = { class = "^(clipse)$" },
    float = true,
    size = { "622", "652" }, move = { "908", "155" },
    animation = "slidedown",
})

hl.window_rule({
    name = "loudness-control",
    match = { class = "org.pulseaudio.pavucontrol" },
    float = true, border_size = 1, xray = true, pin = true,
    size = { "548", "300" }, max_size = { 548, 300 },
    opacity = "0.73", move = { "958", "585" }, animation = "slideup",
})

hl.window_rule({
    name = "tooth-control",
    match = { class = "blueman-manager" },
    float = true, border_size = 1, pin = true,
    size = { "548", "300" }, max_size = { 548, 300 },
    move = { "958", "585" }, animation = "slideup",
})


-- ---- FLOATING & SIZING ----

hl.window_rule({
    name = "hyprland-run",
    match = { class = "hyprland-run" },
    float = true,
    move = { "20", "monitor_h-120" },
})

hl.window_rule({
	name = "unique-note-obsidian",
	match = {class = "obsidian", tag = 'quicknote' },
	float = true,
	size = { "60%", "25%" },
	opacity = ".75",
	pin = true,
})

hl.window_rule({
    name = "zone-decoration",
    match = { class = "special-terminal" },
    opacity = "0.55", float = true, xray = true,
    move = { "836", "3" }, size = { "699", "613" },
    animation = "slide",
})

hl.window_rule({
    name = "easyeffects",
    match = { class = "com.github.wwmm.easyeffects" },
    float = true,
})

hl.window_rule({
    name = "steam-friends",
    match = { title = "^(Friends List)$", class = "^(steam)$" },
    float = true,
})

hl.window_rule({
    name = "steam-settings-dialog",
    match = { title = "^(Steam Settings)$", class = "^(steam)$" },
    float = true,
})


-- ---- DIALOGS & TRANSIENTS ----

hl.window_rule({
    name = "file-picker",
    match = { class = "xdg-desktop-portal-gtk", title = "^(open file)$" },
    float = true,
})

hl.window_rule({
    name = "thunar-float",
    match = { class = "^(thunar)$" },
    float = true,
})

hl.window_rule({
    name = "workspace2-thunar",
    match = { initial_title = "^home - Thunar$" },
    workspace = "RNGR silent",
    tag = "workspace2-thunar",
    float = false,
})

hl.window_rule({
    name = "thunar-rename",
    match = { class = "^(thunar)$", title = "^Rename" },
    float = true,
})

hl.window_rule({
    name = "nethogs-specific",
    match = { initial_title = "nethogs" },
    size = { "807", "285" },
})


-- ---- PER-APP APPEARANCE ----

-- kitty slideup
hl.window_rule({ match = { class = "^kitty" }, animation = "slide bottom" })

hl.window_rule({
    name = "sysmon-opacity",
    match = { class = "sysmon" },
    opaque  = true,  
})

hl.window_rule({ name = "firefox-opaque",  match = { class = "firefox" },        opaque = true })
hl.window_rule({ name = "vivaldi-opaque",  match = { class = "vivaldi-stable" }, opaque = true })
hl.window_rule({ name = "vlc-opaque",      match = { class = "vlc" },            opaque = true })


