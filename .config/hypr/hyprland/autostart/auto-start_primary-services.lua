
-- primary services
hl.on("hyprland.start", function()
    hl.exec_cmd("systemctl --user import-environment wayland_display xdg_current_desktop hyprland_instance_signature")
    hl.exec_cmd("dbus-update-activation-environment --systemd wayland_display xdg_current_desktop")
    hl.exec_cmd("systemctl --user start hyprpolkitagent")
    hl.exec_cmd("clipse-linux-wayland-amd64 --listen")
    hl.exec_cmd("waybar")
    hl.exec_cmd("hyprpm reload -n")
    hl.exec_cmd("swayidle -w timeout 899 'swaylock -f --color 4A154B' timeout 1079 'hyprctl dispatch hl.dsp.dpms({ action = \"off\" })' timeout 1800 '/home/alex/.config/hypr/scripts/suspend-if-on-battery.sh' resume 'hyprctl dispatch hl.dsp.dpms({ action = \"on\" })' before-sleep 'swaylock -f --color 4A154B'")
    hl.exec_cmd("mako")
end)


