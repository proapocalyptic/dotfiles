
-- primary services
hl.on("hyprland.start", function()
    hl.exec_cmd("systemctl --user import-environment wayland_display xdg_current_desktop hyprland_instance_signature")
    hl.exec_cmd("dbus-update-activation-environment --systemd wayland_display xdg_current_desktop")
    hl.exec_cmd("clipse-linux-wayland-amd64 --listen")
    hl.exec_cmd("waybar")
    hl.exec_cmd("hyprpm reload -n")
    hl.exec_cmd("swayidle -w timeout 899 'swaylock -f --color 4A154B' before-sleep 'swaylock -f --color 4A154B'")
    hl.exec_cmd("mako")
end)


