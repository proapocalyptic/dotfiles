#!/usr/bin/env bash
set -euo pipefail

settings="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/settings.json"
config="${XDG_CONFIG_HOME:-$HOME/.config}/quickshell/pull-location-by-wifi-network-name.conf"

# Fallback config locations
if [ ! -f "$config" ] && [ -f "${XDG_CONFIG_HOME:-$HOME/.config}/pull-location-by-wifi-network-name.conf" ]; then
    config="${XDG_CONFIG_HOME:-$HOME/.config}/pull-location-by-wifi-network-name.conf"
elif [ ! -f "$config" ] && [ -f "$(dirname "$0")/pull-location-by-wifi-network-name.conf" ]; then
    config="$(dirname "$0")/pull-location-by-wifi-network-name.conf"
fi

if [ ! -f "$config" ]; then
    echo "Warning: Config file not found." >&2
    exit 0
fi

ssid=$(nmcli -t -f active,ssid dev wifi | grep '^yes' | cut -d: -f2 || true)
[ -z "$ssid" ] && exit 0

new_city=""
while IFS= read -r line || [ -n "$line" ]; do
    # Ignore comments and lines without '='
    [[ "$line" =~ ^[[:space:]]*# ]] && continue
    [[ "$line" != *"="* ]] && continue

    key="${line%%=*}"
    val="${line#*=}"

    # Trim whitespace
    key="${key#"${key%%[![:space:]]*}"}"
    key="${key%"${key##*[![:space:]]}"}"
    val="${val#"${val%%[![:space:]]*}"}"
    val="${val%"${val##*[![:space:]]}"}"

    if [ "$key" = "$ssid" ]; then
        new_city="$val"
        break
    fi
done < "$config"

[ -z "$new_city" ] && exit 0

current=$(jq -r '.settings.openWeatherMap.city // empty' "$settings")
if [ "$current" != "$new_city" ]; then
    jq --arg city "$new_city" '.settings.openWeatherMap.city = $city' "$settings" > "${settings}.tmp" && mv "${settings}.tmp" "$settings"
    qs kill >/dev/null 2>&1 || true
    qs -d
fi
