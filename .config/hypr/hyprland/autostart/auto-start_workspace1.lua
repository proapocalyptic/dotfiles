function home_launch()
	hl.exec_cmd([[kitty -1  --class kitty-home --override confirm_os_window_close=0 -e "/home/alex/.config/hypr/scripts/workspace-1-secondaries.sh"]])
end


hl.on("hyprland.start", function()
	home_launch()
end)

