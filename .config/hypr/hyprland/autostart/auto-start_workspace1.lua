function home_launch()
	hl.exec_cmd([[kitty -1 --class kitty-home --session ~/.config/kitty/workspace1.conf]])
end

hl.on("hyprland.start", function()
	home_launch()
end)

-- One-shot focus fix: force focus to kitty-home after it opens at startup.
local home_focused = false
hl.on("window.open", function(win)
	if not home_focused and win.class == "kitty-home" then
		home_focused = true
		hl.exec_cmd("hyprctl dispatch focuswindow class:kitty-home")
	end
end)

-- Old version that uses individual hyprland windows instead of kitty splits. It works totally fine if you ever run into a problem with the kitty version. I just like the way the splits behave a little more.
--function home_launch()
--	hl.exec_cmd([[kitty -1  --class kitty-home --override confirm_os_window_close=0 -e "/home/alex/.config/hypr/scripts/workspace-1-secondaries.sh"]])
--end


--hl.on("hyprland.start", function()
--	home_launch()
--end)

