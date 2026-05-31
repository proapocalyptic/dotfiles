local function sysmon_launch() -- function pre-defined in case I need to globalize it later. Right now this works the same as the exec_cmd's would if they were just in the hl.on block.
hl.exec_cmd("kitty -1  --class sysmon --override confirm_os_window_close=0 -e btop")
hl.exec_cmd("kitty -1 --class sysmon --override confirm_os_window_close=0 -e sh -c 'journalctl -f | lnav'")
end

hl.on("hyprland.start", function()
  sysmon_launch()
  end)


