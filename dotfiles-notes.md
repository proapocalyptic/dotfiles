# Dotfiles

## Add new files

    dotfiles add <path>
    dotfiles commit -m "message"
    dotfiles push

## Common commands

| Command | What it does |
|---|---|
| `dotfiles status` | Check what's changed |
| `dotfiles diff` | See unstaged changes |
| `dotfiles pull` | Pull latest from GitHub |
| `dotfiles log --oneline` | View commit history |

## What's tracked

- `.config/hypr/` — Hyprland config (Lua)
- `.config/waybar/`, `.config/mako/`, `.config/wlogout/`, `.config/swaylock/` — ecosystem
- `.config/kitty/` — terminal
- `.config/ranger/` — file manager
- `.config/nvim/` — editor
- `.local/bin/` — scripts (root files only, no subdirs)
