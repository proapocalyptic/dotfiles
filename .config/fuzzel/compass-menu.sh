#!/bin/bash
source /home/alex/.config/hypr/hypr-shell-functions.sh

if pgrep -x fuzzel > /dev/null; then
    pkill -x fuzzel
    exit 0
fi

entries=(
    'Screenshot | grim -g "$(slurp)" - | satty --filename - --fullscreen --copy-command wl-copy'
    "Refresh Waybar | killall waybar && waybar"
    "Keyboard|hyprctl eval 'toggle_osk()'"
    "Make a window close!| eval 'hkill'"
    "Move a window somewhere!| /home/alex/.config/hypr/scripts/move-window-to-workspace.sh"
    "Logout|wlogout"
    

)

labels=$(printf '%s\n' "${entries[@]%%|*}")
choice=$(echo "$labels" | fuzzel --dmenu --prompt="" --lines="${#entries[@]}")

for entry in "${entries[@]}"; do
    label="${entry%%|*}"
    command="${entry#*|}"
    if [ "$choice" = "$label" ]; then
        eval "$command"
        break
    fi
done

