# Hyprland 0.55 Lua Configuration — Syntax Reference

## Overview

Hyprland 0.55 replaces the old `hyprlang` `.conf` format with a full Lua-based config system.

- **Old config file:** `~/.config/hypr/hyprland.conf`
- **New config file:** `~/.config/hypr/hyprland.lua`

The config is auto-reloaded on save. Hyprland embeds a full Lua interpreter with all standard libraries available (`os`, `io`, `math`, `string`, `table`, `coroutine`, etc.). All configuration is done through the `hl` global table.

LSP stubs for autocompletion are installed at `/usr/share/hypr/stubs/`. Configure via `.luarc.json`:
```json
{ "workspace": { "library": ["/usr/share/hypr/stubs"] } }
```

---

## Primary API — the `hl` global table

| Function | Purpose |
|---|---|
| `hl.config({ ... })` | Set compositor variables (additive, multiple calls ok) |
| `hl.get_config("key.path")` | Read a config value at runtime |
| `hl.env(key, val)` | Set environment variables |
| `hl.monitor({ ... })` | Configure monitors |
| `hl.bind(keys, dispatcher, flags?)` | Define keybindings |
| `hl.unbind(keys)` | Remove a keybinding |
| `hl.dispatch(dispatcher)` | Execute a dispatcher immediately |
| `hl.window_rule({ match={...}, ... })` | Window rules |
| `hl.layer_rule({ match={...}, ... })` | Layer surface rules |
| `hl.workspace_rule({ ... })` | Workspace-specific settings |
| `hl.animation({ ... })` | Define animations |
| `hl.curve(name, { ... })` | Define bezier/spring curves |
| `hl.gesture({ ... })` | Touchpad/touchscreen gestures |
| `hl.on(event, fn)` | Event callbacks |
| `hl.exec_cmd(cmd)` | Run shell commands asynchronously |
| `hl.timer(fn, opts)` | Repeating/one-shot timers |
| `hl.define_submap(name, fn)` | Define a modal keybinding layer |

---

## `hl.config({ ... })` — Set compositor variables

Multiple calls are additive; each call only updates what you pass.

```lua
hl.config({
    general = {
        gaps_in = 4,
        gaps_out = 5,
        border_size = 1,
        col = {
            active_border = "rgba(0DB7D455)",
            inactive_border = "rgba(31313600)"
        },
        layout = "dwindle",
        allow_tearing = true,
        snap = { enabled = true, window_gap = 4, monitor_gap = 5 }
    },
    decoration = {
        rounding = 18,
        rounding_power = 2.5,
        blur = {
            enabled = true,
            size = 10,
            passes = 3,
            xray = true,
            brightness = 1,
            noise = 0.05,
            contrast = 0.89,
            vibrancy = 0.5,
            popups = false
        },
        shadow = {
            enabled = true,
            range = 20,
            offset = {0, 2},
            render_power = 10,
            color = "rgba(00000020)"
        },
        dim_inactive = true,
        dim_strength = 0.05
    },
    animations = { enabled = true },
    input = {
        kb_layout = "us",
        numlock_by_default = true,
        repeat_delay = 250,
        repeat_rate = 35,
        follow_mouse = 1,
        touchpad = {
            natural_scroll = true,
            disable_while_typing = true,
            clickfinger_behavior = true,
            scroll_factor = 0.7
        }
    },
    misc = {
        disable_hyprland_logo = true,
        disable_splash_rendering = true,
        vrr = 0,
        mouse_move_enables_dpms = true,
        key_press_enables_dpms = true,
        enable_swallow = false
    },
    cursor = {
        zoom_factor = 1,
        zoom_rigid = false
    },
    xwayland = { force_zero_scaling = true },
    binds = {
        scroll_event_delay = 0,
        hide_special_on_workspace_change = true
    }
})
```

### `hl.get_config("key.path")` — Read a config value

```lua
local zoomvalue = hl.get_config("cursor:zoom_factor")
-- css_gaps returns { top, left, right, bottom }
```

---

## `hl.env(key, value)` — Set environment variables

```lua
hl.env("QT_QPA_PLATFORM", "wayland;xcb")
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
-- Reference existing env vars with os.getenv():
hl.env("SSH_AUTH_SOCK", os.getenv("XDG_RUNTIME_DIR") .. "/ssh-agent.socket")
```

---

## `hl.monitor({ ... })` — Configure monitors

```lua
hl.monitor({
    output = "DP-1",
    mode = "1920x1080@144",   -- or "preferred", "highres", "highrr", "maxwidth"
    position = "0x0",          -- or "auto", "auto-right", etc.
    scale = 1,                 -- or "auto"
    transform = 0,             -- 0-7 for rotation/flip
    disabled = false,
    bitdepth = 8,              -- or 10
    cm = "srgb",               -- color management preset
    vrr = 0,
    mirror = "DP-2",           -- mirror another monitor
    icc = "/path/to/profile.icm",
    reserved_area = { top = 10, bottom = 10, left = 0, right = 0 }
})
-- Fallback rule for unspecified monitors:
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })
```

---

## `hl.bind(keys, dispatcher, flags?)` — Define keybindings

```lua
-- Basic bind
hl.bind("SUPER + SHIFT + Q", hl.dsp.exec_cmd("firefox"))

-- No modifier
hl.bind("Print", hl.dsp.exec_cmd("grim"))

-- With Lua function as action
hl.bind("SUPER + SHIFT + X", function()
    hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
end)

-- With flags
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 2%+ -l 1.5"),
    { locked = true, repeating = true })

-- With description
hl.bind("SUPER + Q", hl.dsp.window.close(), { description = "Window: Close" })

-- Mouse bind
hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })

-- Keycode bind
hl.bind("SUPER + code:28", hl.dsp.exec_cmd("kitty"))

-- Per-device bind
hl.bind("SUPER + Q", hl.dsp.exec_cmd("kitty"),
    { devices = { inclusive = true, list = { "my-keyboard" } } })
```

### Bind flags

| Flag | Description |
|---|---|
| `locked` | Works on lockscreen |
| `release` | Trigger on key release |
| `click` | Trigger on release if cursor didn't move past drag_threshold |
| `drag` | Trigger on release if cursor moved past drag_threshold |
| `long_press` | Trigger on long hold |
| `repeating` | Repeats while held |
| `non_consuming` | Also passes event to active window |
| `auto_consuming` | Passes to window if dispatcher fails |
| `mouse` | For mouse movement binds |
| `transparent` | Cannot be shadowed by other binds |
| `ignore_mods` | Ignores modifiers |
| `submap_universal` | Active in all submaps |
| `description` | String description for hyprctl binds |
| `bypass` | Bypasses app's request to inhibit keybinds |
| `devices` | Per-device bind filter `{ inclusive, list }` |

---

## Dispatchers (`hl.dsp.*`)

Dispatchers are **descriptors** (not immediate actions) — they are passed to `hl.bind()` or `hl.dispatch()`.

### General dispatchers

```lua
hl.dsp.exec_cmd(cmd, rules?)    -- Execute shell command
hl.dsp.exec_raw(cmd)            -- Execute without sh -c
hl.dsp.focus({ direction? / monitor? / workspace? / window? / urgent_or_last? / last? })
hl.dsp.submap(name)             -- Switch to submap ("reset" for default)
hl.dsp.pass({ window? })        -- Pass keybind to a window
hl.dsp.send_shortcut({ mods, key, window? })
hl.dsp.global(string)           -- Activate DBus global shortcut
hl.dsp.layout(message)          -- Send layout message
hl.dsp.dpms({ action?, monitor? })
hl.dsp.exit()                   -- Quit Hyprland
hl.dsp.no_op()                  -- Does nothing
hl.dsp.force_idle(seconds)
```

### Window dispatchers (`hl.dsp.window.*`)

```lua
hl.dsp.window.close(window?)
hl.dsp.window.kill(window?)
hl.dsp.window.float({ action?, window? })       -- action: "toggle", "set", "unset"
hl.dsp.window.fullscreen({ mode?, action?, window? })  -- mode: "maximized" or "fullscreen"
hl.dsp.window.fullscreen_state({ internal, client, action?, window? })
hl.dsp.window.pseudo({ action?, window? })
hl.dsp.window.move({ direction? / workspace? / monitor? / x,y? / into_group? / out_of_group? })
hl.dsp.window.swap({ direction? / target? / next? / prev? })
hl.dsp.window.resize({ x, y, relative?, window? })
hl.dsp.window.center({ window? })
hl.dsp.window.cycle_next({ next?, tiled?, floating?, window? })
hl.dsp.window.pin({ window? })
hl.dsp.window.tag({ tag, window? })   -- "+tag" add, "-tag" remove, "tag" toggle
hl.dsp.window.drag()
hl.dsp.window.bring_to_top()
hl.dsp.window.deny_from_group({ action? })
hl.dsp.window.set_prop({ prop, value, window? })
```

### Workspace dispatchers (`hl.dsp.workspace.*`)

```lua
hl.dsp.workspace.rename({ workspace, name? })
hl.dsp.workspace.move({ workspace?, monitor })
hl.dsp.workspace.toggle_special(name)
hl.dsp.workspace.swap_monitors({ monitor1, monitor2 })
```

### Group dispatchers (`hl.dsp.group.*`)

```lua
hl.dsp.group.toggle({ window? })
hl.dsp.group.next({ window? })
hl.dsp.group.prev({ window? })
hl.dsp.group.lock({ action?, window? })
hl.dsp.group.lock_active({ action? })
hl.dsp.group.active({ index, window? })
```

### Cursor dispatchers (`hl.dsp.cursor.*`)

```lua
hl.dsp.cursor.move_to_corner({ corner, window? })
hl.dsp.cursor.move({ x, y })
```

---

## `hl.window_rule({ ... })` — Window rules

```lua
-- Anonymous rule
hl.window_rule({ match = { class = "kitty" }, rounding = 10 })

-- Named rule (can be dynamically toggled)
local myRule = hl.window_rule({
    name = "my-rule",
    match = { class = "kitty", float = true },
    opacity = "0.8 override",
    border_color = "rgb(FF0000)"
})
myRule:set_enabled(false)
myRule:set_enabled(true)
myRule:is_enabled()
```

### Match properties

```lua
match = {
    class = "^kitty$",          -- regex
    title = ".*Firefox.*",      -- regex
    initial_class = "...",
    initial_title = "...",
    tag = "term",
    workspace = "2",
    xwayland = true,
    float = true,
    fullscreen = false,
    pin = false,
    focus = true,
    group = false,
    modal = false,
    content = "game",
    xdg_tag = "...",            -- regex
    fullscreen_state_client = 1,
    fullscreen_state_internal = 0,
}
```

### Static effects (applied once on open)

`float`, `tile`, `fullscreen`, `maximize`, `move`, `size`, `center`, `pseudo`, `monitor`, `workspace`, `no_initial_focus`, `pin`, `group`, `suppress_event`, `content`, `no_close_for`, `scrolling_width`, `fullscreen_state`

### Dynamic effects (re-evaluated on property changes)

`opacity`, `border_color`, `border_size`, `rounding`, `rounding_power`, `no_blur`, `no_shadow`, `no_anim`, `no_dim`, `no_focus`, `no_vrr`, `immediate`, `xray`, `idle_inhibit`, `animation`, `tag`, `min_size`, `max_size`, `keep_aspect_ratio`, `dim_around`, `opaque`, `render_unfocused`, `confine_pointer`, `persistent_size`, `stay_focused`, `decorate`

### Expression syntax for `move` and `size`

Available variables: `monitor_w`, `monitor_h`, `window_x`, `window_y`, `window_w`, `window_h`, `cursor_x`, `cursor_y`

```lua
move = {"cursor_x-(window_w*0.5)", "cursor_y-(window_h*0.5)"}
size = {"(monitor_w*0.60)", "(monitor_h*0.65)"}
```

### Opacity syntax

```lua
opacity = "0.8"                          -- overall multiplier
opacity = "0.9 0.7"                      -- active / inactive
opacity = "1.0 0.8 0.9"                  -- active / inactive / fullscreen
opacity = "0.8 override 0.8 override"    -- absolute, not multiplied
```

---

## `hl.layer_rule({ ... })` — Layer surface rules

```lua
hl.layer_rule({ match = { namespace = "waybar" }, blur = true, ignore_alpha = 0.6 })
hl.layer_rule({ match = { namespace = "quickshell:.*" }, blur = true })
```

---

## `hl.workspace_rule({ ... })` — Workspace rules

```lua
hl.workspace_rule({ workspace = "special:special", gaps_out = 30 })
hl.workspace_rule({ workspace = "2", layout = "scrolling" })
hl.workspace_rule({ workspace = "name:Hello", monitor = "DP-1", default = true })

-- Smart gaps pattern:
hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
hl.workspace_rule({ workspace = "f[1]",   gaps_out = 0, gaps_in = 0 })
```

### Workspace selectors

| Selector | Meaning |
|---|---|
| `w[tv1]` | 1 tiled window |
| `f[1]` | 1 fullscreen window |
| `f[-1]` | no fullscreen window |
| `r[2-4]` | workspace IDs 2–4 |
| `s[false]` | non-special workspace |
| `m[DP-1]` | on monitor DP-1 |

---

## `hl.animation({ ... })` — Define animations

Speed is in deciseconds (1 = 100ms).

```lua
hl.animation({ leaf = "windowsIn", enabled = true, speed = 3, bezier = "emphasizedDecel", style = "popin 80%" })
hl.animation({ leaf = "fade", enabled = false })
```

### Animation tree

```
global
 windowsIn, windowsOut, windowsMove  (styles: slide, popin, gnomed)
 layersIn, layersOut                 (styles: slide, popin, fade)
 fade
   fadeIn, fadeOut, fadeSwitch, fadeShadow, fadeDim
   fadeLayers > fadeLayersIn, fadeLayersOut
   fadePopups > fadePopupsIn, fadePopupsOut
   fadeDpms
 border, borderangle                 (styles: once, loop)
 workspaces > workspacesIn, workspacesOut  (styles: slide, slidevert, fade, slidefade, slidefadevert)
 specialWorkspace > specialWorkspaceIn, specialWorkspaceOut
 zoomFactor, monitorAdded
```

---

## `hl.curve(name, { ... })` — Define bezier/spring curves

```lua
-- Bezier curve (two control points)
hl.curve("emphasizedDecel", {
    type = "bezier",
    points = {{0.05, 0.7}, {0.1, 1}}
})

-- Spring curve
hl.curve("rubber", {
    type = "spring",
    mass = 1,
    stiffness = 70,
    dampening = 10
})
```

---

## `hl.gesture({ ... })` — Gestures

The old config-based swipe gesture options (`workspace_swipe_*`) were removed in 0.55.

```lua
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = 4, direction = "up", action = function()
    hl.dispatch(hl.dsp.global("quickshell:overviewWorkspacesToggle"))
end })
hl.gesture({ fingers = 3, direction = "swipe", action = "move" })
hl.gesture({ fingers = 3, direction = "pinch", action = "fullscreen" })
```

**Directions:** `"horizontal"`, `"vertical"`, `"swipe"`, `"pinch"`, `"up"`, `"down"`, `"left"`, `"right"`

**Built-in actions:** `"workspace"`, `"move"`, `"fullscreen"` — or a Lua function

---

## `hl.on(event, callback)` — Event callbacks

```lua
hl.on("hyprland.start", function()
    hl.exec_cmd("waybar")
    hl.exec_cmd("hyprpaper")
end)

hl.on("window.active", function(w)
    print("Focused: " .. w.title)
end)

hl.on("config.reloaded", function() end)
```

### Available events

`hyprland.start`, `hyprland.shutdown`, `config.reloaded`, `keybinds.submap`, `screenshare.state`,
`window.open`, `window.open_early`, `window.close`, `window.destroy`, `window.kill`, `window.active`,
`window.urgent`, `window.title`, `window.class`, `window.pin`, `window.fullscreen`,
`window.update_rules`, `window.move_to_workspace`,
`layer.opened`, `layer.closed`,
`monitor.added`, `monitor.removed`, `monitor.focused`, `monitor.layout_changed`,
`workspace.active`, `workspace.created`, `workspace.removed`, `workspace.move_to_monitor`

---

## `hl.timer(fn, opts)` — Timers

```lua
local timer = hl.timer(function()
    print("tick")
end, { timeout = 1000, type = "repeat" })  -- or "oneshot"

timer:set_enabled(false)
timer:set_enabled(not timer:is_enabled())
```

---

## Submaps — Modal keybinding layers

```lua
hl.bind("ALT + R", hl.dsp.submap("resize"))

hl.define_submap("resize", function()
    hl.bind("right",  hl.dsp.window.resize({ x = 10,  y = 0, relative = true }), { repeating = true })
    hl.bind("left",   hl.dsp.window.resize({ x = -10, y = 0, relative = true }), { repeating = true })
    hl.bind("escape", hl.dsp.submap("reset"))
end)

-- Universal bind (active in all submaps):
hl.bind("SUPER + K", hl.dsp.exec_cmd("kitty"), { submap_universal = true })

-- Catch-all in submap:
hl.bind("catchall", hl.dsp.submap("reset"))

-- Auto-close a submap on any dispatch (pass both names then function):
hl.define_submap("submapA", "submapB", function()
    hl.bind("a", hl.dsp.exec_cmd("something.sh"))
end)
```

---

## Multi-file configs with `require()`

```lua
-- In hyprland.lua:
require("hyprland/keybinds")    -- UNIX path separator
require("hyprland.keybinds")    -- cross-platform separator
require("custom.env")
```

Each `require()` runs in its own scope — errors in one file do not stop others.

---

## Query functions

```lua
hl.get_active_window()
hl.get_windows()
hl.get_window(selector)
hl.get_workspaces()
hl.get_workspace(selector)
hl.get_active_workspace()
hl.get_monitors()
hl.get_monitor(selector)
hl.get_active_monitor()
hl.get_monitor_at({ x = 100, y = 200 })
hl.get_monitor_at_cursor()
hl.get_cursor_pos()
hl.get_current_submap()
hl.get_last_window()
hl.get_last_workspace()
hl.get_layers()
hl.get_workspace_windows(selector)
hl.get_loaded_plugins()
hl.version()
```

---

## Data types

| Type | Description | Example |
|---|---|---|
| `int` | Integer | `gaps_in = 5` |
| `bool` | Boolean | `enabled = true` |
| `float` | Float | `rounding_power = 2.5` |
| `color` | Color string | `"#fafc21"`, `"rgba(b3ff1aee)"`, `"rgb(b3ff1a)"` |
| `vec2` | 2-float vector | `{ 20, 20 }` |
| `str` | String | `"dwindle"` |
| `gradient` | Color or gradient | `{ colors = {"rgba(...)", "rgba(...)"}, angle = 45 }` |
| `font_weight` | Integer 100–1000 or preset | `"bold"`, `"normal"`, `"light"`, `600` |
| `css_gaps` | Integer or table | `5` or `{ top=5, left=3, right=3, bottom=5 }` |

---

## Notifications

```lua
hl.notification.create({
    text = "Hello!",
    timeout = 5000,
    icon = "ok"
})
```

---

## Patterns and recipes

### Smart gaps
```lua
hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
hl.workspace_rule({ workspace = "f[1]",   gaps_out = 0, gaps_in = 0 })
hl.window_rule({ match = { float = false, workspace = "w[tv1]" }, border_size = 0 })
hl.window_rule({ match = { float = false, workspace = "w[tv1]" }, rounding = 0 })
```

### Screen zoom toggle
```lua
local function zoomfunction(value)
    local z = hl.get_config("cursor:zoom_factor")
    hl.config({ cursor = { zoom_factor = math.max(1.0, math.min(3.0, z + value)) } })
end
hl.bind("SUPER + Equal", function() zoomfunction(0.3) end,  { repeating = true })
hl.bind("SUPER + Minus", function() zoomfunction(-0.3) end, { repeating = true })
```

### Dynamic config toggling
```lua
hl.bind("SUPER + SHIFT + G", function()
    local gaps = hl.get_config("general.gaps_in")
    hl.config({ general = { gaps_in = gaps.top == 3 and 0 or 3 } })
end)
```

### Global keybind pass-through to app
```lua
hl.bind("SUPER + F10", hl.dsp.pass({ window = "class:^(com\\.obsproject\\.Studio)$" }))
```

### Autostart
```lua
hl.on("hyprland.start", function()
    hl.exec_cmd("waybar")
    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("hypridle")
end)
```

---

## Migration reference: hyprlang → Lua

| Old hyprlang (0.54) | New Lua (0.55+) |
|---|---|
| `general { gaps_in = 5 }` | `hl.config({ general = { gaps_in = 5 } })` |
| `monitor = DP-1, 1920x1080@144, 0x0, 1` | `hl.monitor({ output="DP-1", mode="1920x1080@144", position="0x0", scale=1 })` |
| `bind = SUPER, Q, exec, kitty` | `hl.bind("SUPER + Q", hl.dsp.exec_cmd("kitty"))` |
| `binde = ...` (repeating) | `hl.bind(..., { repeating = true })` |
| `bindr = ...` (release) | `hl.bind(..., { release = true })` |
| `bindl = ...` (locked) | `hl.bind(..., { locked = true })` |
| `bindm = ...` (mouse) | `hl.bind(..., { mouse = true })` |
| `exec-once = waybar` | `hl.on("hyprland.start", function() hl.exec_cmd("waybar") end)` |
| `exec = ...` (on reload) | `hl.on("config.reloaded", function() ... end)` |
| `env = GTK_THEME, Nord` | `hl.env("GTK_THEME", "Nord")` |
| `windowrulev2 = float, class:kitty` | `hl.window_rule({ match = { class = "kitty" }, float = true })` |
| `layerrule = blur, waybar` | `hl.layer_rule({ match = { namespace = "waybar" }, blur = true })` |
| `workspace = 1, monitor:DP-1` | `hl.workspace_rule({ workspace = "1", monitor = "DP-1" })` |
| `bezier = name, p1x, p1y, p2x, p2y` | `hl.curve("name", { type="bezier", points={{p1x,p1y},{p2x,p2y}} })` |
| `animation = windows, 1, 8, default, slide` | `hl.animation({ leaf="windows", enabled=true, speed=8, bezier="default", style="slide" })` |
| `submap = name` / `submap = reset` | `hl.dsp.submap("name")` / `hl.define_submap(...)` |
| `source = ./other.conf` | `require("other")` |

---

## Error behavior

| Situation | Behavior |
|---|---|
| Lua syntax error | Refuses to reload, shows error popup |
| Runtime Lua error (e.g. calling nil) | Aborts that file's execution |
| Hyprland type error (e.g. string to float param) | Continues execution |
| Error in keybind function | Shows notification only |

**Emergency keybinds** (always available if config fails): `SUPER+Q` (terminal), `SUPER+R` (run), `SUPER+M` (exit)
