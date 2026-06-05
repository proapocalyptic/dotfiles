#!/bin/bash

# Pick a workspace
WS_IDS=()
WS_DISPLAYS=()
while IFS='|' read -r id display; do
  WS_IDS+=("$id")
  WS_DISPLAYS+=("$display")
done < <(hyprctl workspaces -j | jq -r '.[] | select(.id > 0) | if .name == (.id | tostring) then "\(.id)|\(.id)" else "\(.id)|\(.name) (\(.id))" end')

chosen_ws=$(printf "%s\n" "${WS_DISPLAYS[@]}" | gum choose --header "Pick a workspace:")
[[ -z "$chosen_ws" ]] && exit

for i in "${!WS_DISPLAYS[@]}"; do
  if [[ "${WS_DISPLAYS[$i]}" == "$chosen_ws" ]]; then
    WS_ID="${WS_IDS[$i]}"
    break
  fi
done

# Pick a monitor
MON_NAMES=()
MON_DISPLAYS=()
while IFS='|' read -r name display; do
  MON_NAMES+=("$name")
  MON_DISPLAYS+=("$display")
done < <(hyprctl monitors -j | jq -r '.[] | "\(.name)|\(.name) — \(.width)x\(.height)"')

chosen_mon=$(printf "%s\n" "${MON_DISPLAYS[@]}" | gum choose --header "Pick a target monitor:")
[[ -z "$chosen_mon" ]] && exit

for i in "${!MON_DISPLAYS[@]}"; do
  if [[ "${MON_DISPLAYS[$i]}" == "$chosen_mon" ]]; then
    MON_NAME="${MON_NAMES[$i]}"
    break
  fi
done

hyprctl dispatch "hl.dsp.workspace.move({ workspace = \"$WS_ID\", monitor = \"$MON_NAME\" })"
hyprctl dispatch "hl.dsp.focus({ workspace = \"$WS_ID\" })"
echo -e "\nDone."
sleep 1
