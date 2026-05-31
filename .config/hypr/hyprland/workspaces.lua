-- workspaces.lua — workspace definitions, layouts, routing (was workspaces.conf)

-- ---- Global scrolling layout settings ----
hl.config({ scrolling = { column_width = 0.8 } })

-- ---- Workspace definitions ----
hl.workspace_rule({ workspace = "1",  default_name = "TERMINAL", persistent = true, default = true,  gaps_out = 0, gaps_in = 4 })
hl.workspace_rule({ workspace = "2",  default_name = "RNGR",     persistent = true,
		    layout = "scrolling", layout_opts = { direction = "down" }} )

hl.workspace_rule({ workspace = "3",  default_name = "VLDI",     persistent = true, gaps_out = 0, gaps_in = 0,
		    layout = "monacle"})
hl.workspace_rule({ workspace = "4",  default_name = "FRFX",     persistent = true })
hl.workspace_rule({ workspace = "5",  default_name = "NVIM",     persistent = true })
hl.workspace_rule({ workspace = "6",  default_name = "OBSDN",    persistent = true })
hl.workspace_rule({ workspace = "7",  default_name = "MAIL",     persistent = true })
hl.workspace_rule({ workspace = "8",  default_name = "ADMIN",	 persistent = true,
	  	    layout = "scrolling", layout_opts = { direction = "down" }})


hl.workspace_rule({ workspace = "11", default_name = "STEAM",    persistent = false })
hl.workspace_rule({ workspace = "12", default_name = "ITCH",     persistent = false })
hl.workspace_rule({ workspace = "13", default_name = "VLC",      persistent = false })

-- ---- Smart gaps: no gaps on single-tiled or fullscreen ----
hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
hl.workspace_rule({ workspace = "f[1]",   gaps_out = 0, gaps_in = 0 })
hl.window_rule({ match = { float = false, workspace = "w[tv1]" }, border_size = 0 })
hl.window_rule({ match = { float = false, workspace = "w[tv1]" }, rounding = 0 })
hl.window_rule({ match = { float = false, workspace = "f[1]"   }, border_size = 0 })
hl.window_rule({ match = { float = false, workspace = "f[1]"   }, rounding = 0 })

-- ---- workspace-specific styles ----

hl.workspace_rule({ workspace = "8", gaps_in = 0, gaps_out=0 })

-- ---- Window → workspace routing ----
local function route(class, ws)
    hl.window_rule({ match = { class = class }, workspace = ws .. " silent" })
end
route("kitty-home",      "1")
route("kitty-scratcher", "1")
route("kitty-ranger",    "2")
route("vivaldi-stable",  "3")
route("firefox",         "4")
route("kitty-nvim",      "5")
route("obsidian",        "6")
route("thunderbird",     "7")
route("org.kde.kdeconnect.*", "7")
route("sysmon",          "8")
route("steam",           "11")
route("itch",            "12")
route("vlc",             "13")
route("special-terminal","special:theZone")

-- Workspace Layouts --
hl.workspace_rule({ workspace = "1", layout_opts = { mfact = 0.75 } })
