-- autostart.lua — services & startup apps (was autostart.conf)




pcall(require, "hyprland.plugin_dynamic_cursors")

require("hyprland.autostart.auto-start_minor-services") --bluetooth, wallpaper,
require("hyprland.autostart.auto-start_workspace1")
require("hyprland.autostart.auto-start_ranger-and-thunar") --ranger and thunar for workspace RNGR
require("hyprland/autostart/auto-start_normal-desktop")    -- all simple desktop applications with single-word launch commands
require("hyprland.autostart.auto-start_sysmon") 	   --cli system managers for workspace ADMIN


hl.on("hyprland.start", function()
    -- environment export
    hl.exec_cmd("systemctl --user import-environment wayland_display xdg_current_desktop hyprland_instance_signature")
    hl.exec_cmd("dbus-update-activation-environment --systemd wayland_display xdg_current_desktop")

 -- nvim-server pre-launch: starts local nvim server headless in its own instance group to speed up first open. Own instance group is to preserve unsaved work if the global kitty instance crashes. 
 hl.exec_cmd([[kitty -1 --instance-group nvim --class kitty-nvim --confirm_os_window_close=1 --start-as=hidden --config="/home/alex/.config/kitty/kitty.conf"
 --config="/home/alex/.config/kitty/kitty-nvim.conf"]])
 hl.exec_cmd("TaskZone.sh")


 end)
