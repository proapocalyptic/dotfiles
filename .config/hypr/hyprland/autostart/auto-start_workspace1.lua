workspace_1_launch=[[kitty -1 --override confirm_os_window_close=0 --class kitty-home --session ~/.config/kitty/workspace1.conf]]




hl.on("hyprland.start",	function()
	hl.exec_cmd(workspace_1_launch)
end)



