-- keybindings.lua — keybinds (was keybindings.conf)<D-Tab> map super+p paste_from_clipboar
local SUPER = "SUPER"

-- ---- essential binds ---
hl.bind(SUPER .. " + Z", hl.dsp.exec_cmd("kitty -1"))
hl.bind(SUPER .. " + CTRL + ALT + SHIFT + M",
    hl.dsp.exec_cmd("sh -c 'command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch exit'"))



-- ---- clipboard ----
hl.bind("CTRL + SHIFT + V", hl.dsp.exec_cmd("paste-primary.sh"))
-- ---- Window management ----
hl.bind(SUPER .. " + F", hl.dsp.window.fullscreen({}))
hl.bind(SUPER .. " + Q", hl.dsp.window.close())
hl.bind(SUPER .. " + CTRL + SHIFT + M",
    hl.dsp.exec_cmd("sh -c 'command -v hyprshutdown >/dev/null 2>&1 && hyprshutdown || hyprctl dispatch exit'"))
hl.bind(SUPER .. " + E", hl.dsp.exec_cmd("thunar"))
hl.bind(SUPER .. " + H", hl.dsp.window.float({ action = "toggle" }))
hl.bind(SUPER .. " + R", hl.dsp.exec_cmd("hyprlauncher"))

hl.bind(SUPER .. " + CTRL + SHIFT + P", hl.dsp.window.pseudo({ action = "toggle" }))
hl.bind(SUPER .. " + J", hl.dsp.layout("togglesplit"))

-- ---- Focus movement ----
hl.bind(SUPER .. " + a",     hl.dsp.focus({ direction = "l" }))
hl.bind(SUPER .. " + d",     hl.dsp.focus({ direction = "r" }))
hl.bind(SUPER .. " + w",     hl.dsp.focus({ direction = "u" }))
hl.bind(SUPER .. " + s",     hl.dsp.focus({ direction = "d" }))
-- ---- Workspaces 1-10 ----
for i = 1, 9 do
    hl.bind(SUPER .. " + " .. i, hl.dsp.focus({ workspace = tostring(i) }))
    hl.bind(SUPER .. " + SHIFT + " .. i, hl.dsp.window.move({ workspace = tostring(i) }))
end
hl.bind(SUPER .. " + 0",          hl.dsp.focus({ workspace = "10" }))
hl.bind(SUPER .. " + SHIFT + 0",  hl.dsp.window.move({ monitor = "+1" }))
hl.bind(SUPER .. " + SHIFT + O",  hl.dsp.workspace.move({ monitor = "+1" }))

-- Lock screen
hl.bind(SUPER .. " + L", hl.dsp.exec_cmd("swaylock -f --color 4A154B"))

-- Special workspace
hl.bind(SUPER .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:theZone" }))

-- Scroll between workspaces
hl.bind(SUPER .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(SUPER .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

-- Mouse drag — confirmed by wiki Binds page:
--   movewindow   -> hl.dsp.window.drag()
--   resizewindow -> hl.dsp.window.resize()  (no args = drag-resize mode)
hl.bind(SUPER .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(SUPER .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- Volume / brightness (locked + repeating)
local lr = { locked = true, repeating = true }
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+"),  lr)
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),       lr)
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),      lr)
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),    lr)
hl.bind("XF86MonBrightnessUp",  hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%+"),                   lr)
hl.bind("XF86MonBrightnessDown",hl.dsp.exec_cmd("brightnessctl -e4 -n2 set 5%-"),                   lr)

-- Media (locked)
local l = { locked = true }
hl.bind("XF86AudioNext",  hl.dsp.exec_cmd("playerctl next"),       l)
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), l)
hl.bind("XF86AudioPlay",  hl.dsp.exec_cmd("playerctl play-pause"), l)
hl.bind("XF86AudioPrev",  hl.dsp.exec_cmd("playerctl previous"),   l)

-- Emergency
hl.bind("SUPER + Return",   hl.dsp.exec_cmd("kitty"))
hl.bind("SUPER + SHIFT + E", hl.dsp.exit())

-- Special workspace toggle via keycode 49 (`/~ key)
hl.bind("SUPER + code:49",         hl.dsp.workspace.toggle_special("theZone"))
hl.bind("SUPER + SHIFT + code:49", hl.dsp.window.move({ workspace = "theZone" }))

-- Swap windows left/right
hl.bind(SUPER .. " + left",  hl.dsp.window.swap({ direction = "l" }))
hl.bind(SUPER .. " + right", hl.dsp.window.swap({ direction = "r" }))
hl.bind(SUPER .. " + up",   hl.dsp.window.swap({ direction = "u" }))
hl.bind(SUPER .. " + down", hl.dsp.window.swap({ direction = "d" }))

-- Groups
hl.bind(SUPER .. " + SHIFT + G", hl.dsp.group.toggle())
-- SUPER+G: add the active window to an existing group regardless of which
-- side it's on. User uses one group at a time, so fire both directions —
-- whichever finds a neighboring group wins; the other becomes a no-op.
-- (This was intentional in the original config, not a bug.)
hl.bind(SUPER .. " + G", function()
    hl.dispatch(hl.dsp.window.move({ into_group = "r" }))
    hl.dispatch(hl.dsp.window.move({ into_group = "l" }))
end)

-- Clipboard manager
hl.bind(SUPER .. " + SHIFT + V",
    hl.dsp.exec_cmd("kitty --class clipse --override confirm_os_window_close=0 -e clipse-linux-wayland-amd64"))

hl.bind(SUPER .. " + ALT + a", function() 
local x = not hl.get_config("animations.enabled")
hl.config({ animations = { enabled = x }})
end)

-- quick access terminal
hl.bind(SUPER .. " + K", hl.dsp.exec_cmd("kitten quick-access-terminal"))


-- Workspace switchback 
hl.bind(SUPER .. " + Tab", hl.dsp.window.cycle_next())

-- ---- Workspace submaps ----
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
--#region

local workspaces = {
    { key = "A", id = 1,  run = "kitty -1 --class kitty-home --override confirm_os_window_close=0 -e /home/alex/.config/hypr/scripts/workspace-1-secondaries.sh" },  -- TERMINAL
    { key = "S", id = 2,   run = "kitty -1 --class kitty-ranger -e ranger & thunar /home/"               },  -- RNGR
    { key = "D", id = 3,  run = "vivaldi"  },  -- VLDI
    { key = "F", id = 4,  run = "firefox"  },  -- FRFX
    { key = "J", id = 5,  run = "nvim-open ~/.config/"},  -- NVIM
    { key = "K", id = 6,  run = "obsidian" },  -- OBSDN
    { key = "L", id = 7,  run = "thunderbird-go"},  -- MAIL
    { key = "semicolon", id = 8, run = "sysmon-run.sh"},  -- ADMIN
    { key = "S", id = 11, run = "steam"    },  -- STEAM
    { key = "I", id = 12, run = "itch"     },  -- ITCH
    { key = "L", id = 13, run = "vlc"      },  -- VLCh
}

hl.bind("SUPER + SHIFT + F23", hl.dsp.submap("ws-focus"), { bypass = true })

hl.define_submap("ws-focus", function()
    hl.bind("M", hl.dsp.submap("ws-move"))
    hl.bind("R", hl.dsp.submap("ws-run"))
    for _, ws in ipairs(workspaces) do
        hl.bind(ws.key, function()
            hl.dispatch(hl.dsp.focus({ workspace = ws.id }))
            hl.dispatch(hl.dsp.submap("reset"))
        end)
    end
    hl.bind("catchall", hl.dsp.submap("reset"))
end)


hl.define_submap("ws-move", function()
    for _, ws in ipairs(workspaces) do
        hl.bind(ws.key, function()
            hl.dispatch(hl.dsp.window.move({ workspace = ws.id, follow = true }))
            hl.dispatch(hl.dsp.submap("reset"))
        end)
    end
    hl.bind("catchall", hl.dsp.submap("reset"))
end)

hl.define_submap("ws-run", function()
    for _, ws in ipairs(workspaces) do
        if ws.run then
            hl.bind(ws.key, function()
                local w = hl.get_workspace(ws.id)
                if w == nil or w.windows == 0 then
                    hl.dispatch(hl.dsp.exec_cmd(ws.run))
                end
                hl.dispatch(hl.dsp.focus({ workspace = ws.id }))
                hl.dispatch(hl.dsp.submap("reset"))
            end)
        end
    end
    hl.bind("catchall", hl.dsp.submap("reset"))
end)

