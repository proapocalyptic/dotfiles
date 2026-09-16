#!/bin/bash
set -euo pipefail

CONF="/home/alex/.config/hypr/hyprpaper.conf"
DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
LIST_DIR="${DATA_HOME}/wallpaper"
LIST="${LIST_DIR}/wallpaper-list"
WALLPAPER_DIR="$HOME/Pictures/wallpapers"

mkdir -p "$WALLPAPER_DIR"

read -rep "Wallpaper path: " -i "$PWD/" wallpaper

if [[ -z "$wallpaper" ]]; then
    echo "No path entered. Aborting." >&2
    exit 1
fi

if [[ ! -f "$wallpaper" ]]; then
    echo "'$wallpaper' does not exist as a file. Aborting." >&2
    exit 1
fi

base="$(basename "$wallpaper")"
input_hash="$(sha256sum "$wallpaper" | cut -d' ' -f1)"

# Recursively look for an existing name+hash match inside WALLPAPER_DIR.
match=""
while IFS= read -r -d '' candidate; do
    if [[ "$(sha256sum "$candidate" | cut -d' ' -f1)" == "$input_hash" ]]; then
        match="$candidate"
        break
    fi
done < <(find "$WALLPAPER_DIR" -type f -name "$base" -print0)

if [[ -n "$match" ]]; then
    wallpaper="$match"
else
    dest="$WALLPAPER_DIR/$base"
    if [[ -e "$dest" ]]; then
        # Name collision with different content: don't clobber, disambiguate instead.
        stamp="$(date +%Y%m%d%H%M%S)"
        dest="$WALLPAPER_DIR/${base%.*}-${stamp}.${base##*.}"
        echo "'$base' already exists in $WALLPAPER_DIR with different content; saving as $(basename "$dest") instead." >&2
    fi
    cp "$wallpaper" "$dest"
    wallpaper="$dest"
fi

match_count=$(grep -c '^\s*path = ' "$CONF")

if [[ "$match_count" -eq 0 ]]; then
    echo "No line starting with 'path = ' found in $CONF. Aborting." >&2
    exit 1
elif [[ "$match_count" -gt 1 ]]; then
    echo "Found $match_count lines starting with 'path = ' in $CONF." >&2
    echo "This looks like a multi-monitor config, and blindly replacing all of them would be wrong. Aborting." >&2
    echo "Edit $CONF manually, or extend this script to target a specific wallpaper { } block." >&2
    exit 1
fi

original=$(grep '^\s*path = ' "$CONF" | sed 's/^\s*path = //')

prefix=$(grep '^\s*path = ' "$CONF" | sed 's/\(^\s*\)path = .*/\1/')
sed -i "s|^\s*path = .*|${prefix}path = ${wallpaper}|" "$CONF"

echo "Updated $CONF:"
grep '^\s*path = ' "$CONF"

mkdir -p "$LIST_DIR"
touch "$LIST"

for entry in "$original" "$wallpaper"; do
    [[ -z "$entry" ]] && continue
    grep -vFx "$entry" "$LIST" > "${LIST}.tmp" || true
    mv "${LIST}.tmp" "$LIST"
    echo "$entry" >> "$LIST"
done
