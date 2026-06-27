local SUPER = "SUPER"

-- ---- Emergency ----
hl.bind(SUPER .. " + CTRL + SHIFT + M",
    hl.dsp.exec_cmd("sh -c 'command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch exit'"))
hl.bind("SUPER + Return",   hl.dsp.exec_cmd("kitty"))
hl.bind("SUPER + SHIFT + E", hl.dsp.exit())


-- ---- Essential ----
hl.bind(SUPER .. " + Z", hl.dsp.exec_cmd("kitty -1"))
hl.bind(SUPER .. " + CTRL + ALT + SHIFT + M",
    hl.dsp.exec_cmd("sh -c 'command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch exit'"))

-- ---- Focus Movement ----
hl.bind(SUPER .. " + a",     hl.dsp.focus({ direction = "l" }))
hl.bind(SUPER .. " + d",     hl.dsp.layout("cyclenext")) 
hl.bind(SUPER .. " + d",     hl.dsp.focus({ direction = "r" }))
hl.bind(SUPER .. " + w",     hl.dsp.focus({ direction = "u" }))
hl.bind(SUPER .. " + s",     hl.dsp.focus({ direction = "d" }))

-- ---- Window Management ----
hl.bind(SUPER .. " + F", hl.dsp.window.fullscreen({}))
hl.bind(SUPER .. " + SHIFT + Q", hl.dsp.window.close())
hl.bind(SUPER .. " + H", hl.dsp.window.float({ action = "toggle" }))
hl.bind(SUPER .. " + CTRL + SHIFT + P", hl.dsp.window.pseudo({ action = "toggle" }))
hl.bind(SUPER .. " + left",  hl.dsp.window.swap({ direction = "l" }))
hl.bind(SUPER .. " + right", hl.dsp.window.swap({ direction = "r" }))
hl.bind(SUPER .. " + up",   hl.dsp.window.swap({ direction = "u" }))
hl.bind(SUPER .. " + down", hl.dsp.window.swap({ direction = "d" }))
hl.bind(SUPER .. " + SHIFT + G", hl.dsp.group.toggle())
-- SUPER+G: add the active window to an existing group regardless of which
-- side it's on. User uses one group at a time, so fires both directions —
-- whichever finds a neighboring group wins; the other becomes a no-op.
hl.bind(SUPER .. " + G", function()
    hl.dispatch(hl.dsp.window.move({ into_group = "r" }))
    hl.dispatch(hl.dsp.window.move({ into_group = "l" }))
end)
hl.bind(SUPER .. " + ALT + a", function() 
local x = not hl.get_config("animations.enabled")
hl.config({ animations = { enabled = x }})
end)
hl.bind(SUPER .. " + Tab", hl.dsp.window.cycle_next())
-- Mouse drag — confirmed by wiki Binds page:
--   movewindow   -> hl.dsp.window.drag()
--   resizewindow -> hl.dsp.window.resize()  (no args = drag-resize mode)
hl.bind(SUPER .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(SUPER .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- ---- Workspaces ----
-- Workspaces 1-10
for i = 1, 9 do
    hl.bind(SUPER .. " + " .. i, function()
        local cur = hl.get_active_workspace()
        if cur and cur.id == i then
            hl.dispatch(hl.dsp.focus({ workspace = "previous" }))
        else
            hl.dispatch(hl.dsp.focus({ workspace = tostring(i) }))
        end
    end)
    hl.bind(SUPER .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = tostring(i) }))
end
hl.bind(SUPER .. " + 0", function()
    local cur = hl.get_active_workspace()
    if cur and cur.id == 10 then
        hl.dispatch(hl.dsp.focus({ workspace = "previous" }))
    else
        hl.dispatch(hl.dsp.focus({ workspace = "10" }))
    end
end)

 hl.bind(SUPER .. " + SHIFT + 0", hl.dsp.window.move({ workspace = 10 }))



hl.bind(SUPER .. " + CTRL + 0",  hl.dsp.window.move({ monitor = "+1" }))
hl.bind(SUPER .. " + CTRL + O",  hl.dsp.workspace.move({ monitor = "+1" }))
-- Scroll between workspaces
hl.bind(SUPER .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(SUPER .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- ---- Workspace Submaps ----
-- Three leaders, each followed by a bare mnemonic key:
--   SUPER + Space         → focus workspace
--   SUPER + SHIFT + Space → move active window there (and follow)
--   SUPER + ALT   + Space → focus workspace, launching if empty
--                           (only available for single-app workspaces)

--local workspaces = {
--    { key = "Z", id = 1,  run = "kitty & sleep 1 & ~/.config/hypr/scripts/workspace-1-secondaries.sh"                },  -- TERMINAL
--    { key = "R", id = 2                       },  -- RNGR
--    { key = "V", id = 3,  run = "vivaldi"  },  -- VLDI
--    { key = "F", id = 4,  run = "firefox"  },  -- FRFX
--    { key = "N", id = 5                       },  -- NVIM
--    { key = "O", id = 6,  run = "obsidian" },  -- OBSDN
--    { key = "M", id = 7                       },  -- MAIL
--    { key = "A", id = 8                       },  -- ADMIN
--    { key = "S", id = 11, run = "steam"    },  -- STEAM
--    { key = "I", id = 12, run = "itch"     },  -- ITCH
--    { key = "L", id = 13, run = "vlc"      },  -- VLC
--}
--
-- -e ranger & thunar /home/"

local workspaces = {
    { key = "A", id = 1,  run = "kitty -1  --class kitty-home --override confirm_os_window_close=0 --session ~/.config/kitty/workspace1.conf" },  -- TERMINAL
    { key = "2", id = 2,  run = "kitty -1 --class kitty-ranger --override confirm_os_window_close=0 -e ranger & thunar /home/"               },  -- RNGR
    { key = "V", id = 3,  run = "vivaldi"  },  -- VLDI
    { key = "F", id = 4,  run = "firefox"  },  -- FRFX
    { key = "W", id = 4,  run = "librewolf"  },  -- LBRW
    { key = "N", id = 5,  run = "nvim-open ~/.config/"},  -- NVIM
    { key = "O", id = 6,  run = "obsidian" },  -- OBSDN
    { key = "C", id = 7,  run = "thunderbird-go"},  -- MAIL
    { key = "semicolon", id = 8, run = "sysmon-run.sh"},  -- ADMIN
    { key = "S", id = 11, run = "steam"    },  -- STEAM
    { key = "I", id = 12, run = "itch"     },  -- ITCH
    { key = "L", id = 13, run = "vlc"      },  -- VLCh
       { key = "T", id = 9, run = "TaskZone.sh"    }
}


hl.bind("SUPER + SHIFT + M", hl.dsp.submap("ws-run"))

hl.bind("SUPER + SHIFT + F23", hl.dsp.submap("ws-focus"))

local transitioning = false

hl.define_submap("ws-focus", function()
    hl.bind("M", function()
        transitioning = true
        hl.dispatch(hl.dsp.submap("ws-move"))
    end)
    hl.bind("R", function()
        transitioning = true
        hl.dispatch(hl.dsp.submap("ws-run"))
    end)
    for _, ws in ipairs(workspaces) do
        hl.bind(ws.key, function()
            if type(ws.id) == "string" and ws.id:find("^special:") then
                hl.dispatch(hl.dsp.workspace.toggle_special(ws.id:match("^special:(.+)$")))
            else
                local cur = hl.get_active_workspace()
                if cur and cur.id == ws.id then
                    hl.dispatch(hl.dsp.focus({ workspace = "previous" }))
                else
                    hl.dispatch(hl.dsp.focus({ workspace = ws.id }))
                end
            end
            hl.dispatch(hl.dsp.submap("reset"))
        end)
    end
    hl.bind("catchall", function()
        if not transitioning then
            hl.dispatch(hl.dsp.submap("reset"))
        end
        transitioning = false
    end)
end)


hl.define_submap("ws-move", "reset", function()
    for _, ws in ipairs(workspaces) do
        hl.bind(ws.key, function()
            hl.dispatch(hl.dsp.window.move({ workspace = ws.id, follow = true }))
        end)
    end
    hl.bind("catchall", hl.dsp.submap("reset"))
end)

hl.define_submap("ws-run", "reset", function()
    for _, ws in ipairs(workspaces) do
        if ws.run then
            hl.bind(ws.key, function()
                local w = hl.get_workspace(ws.id)
                if w == nil or w.windows == 0 then
                    hl.dispatch(hl.dsp.exec_cmd(ws.run))
                end
                hl.dispatch(hl.dsp.focus({ workspace = ws.id }))
            end)
        end
    end
    hl.bind("catchall", hl.dsp.submap("reset"))
end)

-- ---- Application Launchers ----
hl.bind(SUPER .. " + R", hl.dsp.exec_cmd("hyprlauncher"))
hl.bind(SUPER .. " + E", hl.dsp.exec_cmd("thunar"))
hl.bind(SUPER .. " + M", hl.dsp.exec_cmd("~/.config/waybar/scripts/compass-menu.sh"))
hl.bind(SUPER .. " + K", hl.dsp.exec_cmd("ZSH_NO_HEADER=2 kitten quick-access-terminal "))
hl.bind("SUPER + code:61", function()
    local wins = hl.get_windows({ class = "kitty-rightslide" })
    if #wins > 0 then
        hl.dispatch(hl.dsp.window.close({ window = wins[1] }))
    else
        hl.dispatch(hl.dsp.exec_cmd("kitty -1 --class kitty-rightslide -e micro /home/alex/Scratcher.md"))
    end
end)

hl.bind("SUPER + code:48", function()
    local cur_ws = hl.get_active_workspace()
    if not cur_ws then return end
    local cur_id = cur_ws.id

    local cur_wins = hl.get_windows({ class = "kitty-topslide", workspace = cur_ws })
    if #cur_wins > 0 then
        hl.dispatch(hl.dsp.window.move({ workspace = "special:joe", window = cur_wins[1], follow = false }))
        return
    end

    local joe_wins = hl.get_windows({ class = "kitty-topslide", workspace = "special:joe" })
    if #joe_wins > 0 then
        hl.dispatch(hl.dsp.window.move({ workspace = tostring(cur_id), window = joe_wins[1], follow = true }))
        return
    end

    hl.dispatch(hl.dsp.exec_cmd("kitty -1 --class kitty-topslide"))
end)


-- ---- Clipboard ----
hl.bind("CTRL + SHIFT + V", hl.dsp.exec_cmd("paste-primary.sh"))
hl.bind(SUPER .. " + V", function()
    local wins = hl.get_windows({ class = "kitty-clipse" })
    if #wins > 0 then
        hl.dispatch(hl.dsp.window.close({ window = wins[1] }))
    else
        hl.dispatch(hl.dsp.exec_cmd("kitty -1 --class kitty-clipse --config /home/alex/config/kitty/kitty-clipse.conf --override confirm_os_window_close=0 -e clipse-linux-wayland-amd64"))
    end
end)

-- ---- Lock Screen ----
hl.bind(SUPER .. " + L", hl.dsp.exec_cmd("swaylock -f --color 4A154B"))

-- ---- Media & Volume ----
local lr = { locked = true, repeating = true }
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),  lr)
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),       lr)
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),      lr)
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),    lr)
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                   lr)
hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                   lr)

local l = { locked = true }
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       l)
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), l)
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), l)
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   l)

-- ---- Toggle On-screen Keyboard ----
hl.bind("SUPER + ALT + K", toggle_osk)

-- ---- Special Workspace (commented) ----
--hl.bind("SUPER + code:49",         hl.dsp.workspace.toggle_special("theZone"))
--hl.bind("SUPER + SHIFT + code:49", hl.dsp.window.move({ workspace = "theZone" }))
