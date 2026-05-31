-- monitors.lua — display configuration (was monitors.conf)

-- Internal display
hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = 1.25 })

-- Fallback for any other monitor: place to the left
hl.monitor({ output = "", mode = "preferred", position = "auto-left", scale = 1 })
