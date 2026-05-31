# Hyprlang → Lua Conversion Notes

Hyprland version: **0.55.1** (confirmed via `hyprctl version`).
LSP stubs: `/usr/share/hypr/stubs/hl.meta.lua`.

This document was last refreshed AFTER cross-checking the official wiki PDFs
shipped in this folder and the hyprbars plugin README. **Most of the original
uncertainties are now resolved.**

## Status

Scaffolding files are generated under `~/.config/hypr/hyprland/`. The current
`.conf` configuration is **untouched and still active** — the new Lua files
are inert until you swap `hyprland.conf` for `hyprland.lua` (rename
`hyprland.lua.scaffold` → `hyprland.lua` once verified).

## Backups

- `~/.config/hypr/hypr.bak (pre-rewrite)/` — your existing backup
- `/tmp/opencode/hypr-backup-20260518-154616/` — fresh full snapshot

## Layout

```
~/.config/hypr/
├── hyprland.conf              # still active
├── hyprland.lua.scaffold      # rename to hyprland.lua to activate Lua
├── .luarc.json                # LSP / lua-language-server config
├── CONVERSION-NOTES.md        # this file
└── hyprland/
    ├── env.lua
    ├── monitors.lua
    ├── input.lua
    ├── general.lua
    ├── autostart.lua
    ├── keybindings.lua
    ├── workspaces.lua
    ├── plugins.lua
    ├── window_rules.lua
    └── permissions.lua
```

## Resolved by PDF / README cross-check

| Original uncertainty | Resolution | Source |
|---|---|---|
| Plugin config shape | `hl.config({ plugin = { <name> = { ... } } })` | Using-Plugins wiki PDF, hyprbars README |
| `hyprbars-button` shape | Use `hl.plugin.hyprbars.add_button({ bg_color, fg_color, size, icon, action })` — NOT a config key | hyprbars README |
| Plugin guard pattern | Wrap config blocks that touch `hl.plugin.X` in `if hl.plugin.X ~= nil then` | Using-Plugins wiki PDF |
| `hyprbars:no_bar` window-rule property | Use string key form: `["hyprbars:no_bar"] = true` (and same for `hyprbars:bar_color`, `hyprbars:title_color`) | hyprbars README |
| `mouse:272 movewindow` vs `mouse:273 resizewindow` | `hl.dsp.window.drag()` vs `hl.dsp.window.resize()` (no args) | Binds wiki PDF, lines 297–349 |
| `moveintogroup, r` | `hl.dsp.window.move({ into_group = "r" })` | Dispatchers wiki PDF, line 256 |
| `togglegroup` | `hl.dsp.group.toggle()` | Dispatchers wiki PDF |
| `workspace, e+1`/`e-1` | `hl.dsp.focus({ workspace = "e+1" })` | Dispatchers wiki PDF, line 483 |
| `misc.focus_on_activate` | Valid; documented as bool variable | Variables wiki PDF, line 2455 |
| Animation leaf names | `windowsIn`, `windowsOut`, `windowsMove`, `workspaces`, `layersIn`, `layersOut`, `fadeIn`, `fadeOut`, `border` — all confirmed | lua syntax reference |
| Workspace 2 layout (master orientation + scrolling) | Two separate `hl.workspace_rule()` calls (additive) | Master Layout + Scrolling Layout PDFs |
| `permission = ...` line in hyprland.conf | `hl.permission({ binary, type, mode })`. Requires `ecosystem.enforce_permissions = true` to actually take effect; NOT live-reloaded | Permissions wiki PDF |

## Remaining genuine unknowns (small)

These items are flagged with comments in the relevant `.lua` files:

1. **`bindp` flag.** Used once in the original (`keybindings.conf:111` for the
   SUPER+B tag bind). It is NOT among the documented hyprlang flag suffixes
   (`l`/`e`/`m`/`r`/`n`/`i`/`t`/`d`/`o`), and the wiki Binds page does not list
   any `p` flag. The most likely interpretations are:
   - typo for plain `bind` (treated as such in our Lua port), or
   - a legacy/private alias.

   The Lua port treats it as a plain `hl.bind`. If you remember intending
   something else (e.g. `non_consuming` = `n`), edit `keybindings.lua` to add
   the flag.

2. **`workspace = "1 silent"` window-rule string.** The hyprlang form
   `windowrule = workspace 1 silent` is now passed as a single string value
   `workspace = "1 silent"` because `WindowRuleSpec` in the stubs accepts
   arbitrary keys (only `match`/`name`/`enabled` are typed). The Binds wiki
   PDF only documents `movetoworkspace[silent]` for *dispatchers*, not for
   window-rule strings. This is the most likely correct port, but if windows
   stop routing silently after activation, try splitting into
   `workspace = "1", no_initial_focus = true`.

3. **`misc.focus_on_activate`** is documented as a valid variable but is not
   in the LSP stub enum. It should work; LSP may show a yellow warning.

4. **Original config bugs reproduced or fixed.** The original had two
   self-overriding `SUPER+B` and `SUPER+SHIFT+B` definitions. Hyprlang
   silently kept only the last one in each case. The Lua port:
   - **SUPER+B**: keeps `tagwindow hyprbarred` (the later one). The earlier
     `hyprbars disable` exec is commented out with a note.
   - **SUPER+SHIFT+B**: combines both `tagwindow -hyprbarred` AND
     `tagwindow +not-hyprbarred` (which were intended as a pair) into a
     single Lua function — fixes a likely original-config bug.
   - **SUPER+G**: the apparent "collision" between `moveintogroup, r` and
     `moveintogroup, l` was **intentional** (user clarification): fire both
     directions so the active window joins whichever group is adjacent. The
     Lua port preserves this with a Lua function dispatching both, which
     also fixes the silent-clobber that hyprlang would have caused.
   - **`opacity = 1.8`** on `sysmon-opacity` was an out-of-range value in the
     original; replaced with `"1.0 override"`.

## Verification done

- All 10 `.lua` scaffold files pass `luac -p` syntax check.
- All field names cross-checked against `/usr/share/hypr/stubs/hl.meta.lua`
  and the wiki PDFs shipped in this directory (`Binds`, `Dispatchers`,
  `Variables`, `Workspace Rules`, `Animations`, `Master Layout`,
  `Scrolling Layout`, `Using plugins`, `Permissions`).
- Plugin patterns cross-checked against the hyprbars README in this folder.

## How to activate Lua config

1. Make sure your plugins are installed and `hyprpm reload` works on the
   current `.conf` setup.
2. Rename:
   ```sh
   mv ~/.config/hypr/hyprland.conf ~/.config/hypr/hyprland.conf.disabled
   mv ~/.config/hypr/hyprland.lua.scaffold ~/.config/hypr/hyprland.lua
   ```
3. Hyprland auto-reloads on save. If parsing fails, you get the error popup
   plus emergency keybinds (SUPER+Q terminal, SUPER+R run, SUPER+M exit).
4. Verify the four flagged items above. If a `VERIFY:` comment in any `.lua`
   file ends up breaking, swap to the alternative noted there.
5. Once stable, the legacy `.conf` files can be moved aside.

## Not migrated

- `hyprpaper.conf` — separate program, untouched.
- `scripts/` — left as-is.
