-- autostart.lua — services & startup apps (was autostart.conf)




require("hyprland.autostart.auto-start_minor-services") --bluetooth, wallpaper, etc 
require("hyprland.autostart.auto-start_ranger-and-thunar") --ranger and thunar for workspace RNGR
require("hyprland.autostart.auto-start_normal-desktop")    -- all simple desktop applications with single-word launch commands
require("hyprland.autostart.auto-start_sysmon") 	   --cli system managers for workspace ADMIN



hl.on("hyprland.start", function()
    -- environment export
    hl.exec_cmd("systemctl --user import-environment wayland_display xdg_current_desktop hyprland_instance_signature")
    hl.exec_cmd("dbus-update-activation-environment --systemd wayland_display xdg_current_desktop")

 -- nvim-server pre-launch: starts local nvim server headless in its own instance group to speed up first open. Own instance group is to preserve unsaved work if the kitty instance crashes. 
 hl.exec_cmd("kitty -1 --instance-group nvim --class kitty-nvim --start-as=hidden")
 hl.exec_cmd("kitty -1 --class special-terminal")

end)


