
hl.on("hyprland.start", function()
 hl.exec_cmd("kitty -1 --class kitty-ranger --override confirm_os_window_close=0 -e ranger")
 hl.exec_cmd("thunar /home/")
-- hl.exec_cmd("~/.config/hypr/scripts/ranger-and-thunar.lua") **probably not needed, but is supposed to ensure ranger is focused**
end)

