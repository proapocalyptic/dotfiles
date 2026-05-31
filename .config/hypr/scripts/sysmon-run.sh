#!/bin/bash

#this shell script is to relaunch the sysmon utilities, should be bound to the run property of the ADMIN workspace in keybindings.lua 

 hyprctl dispatch "hl.dsp.exec_cmd([[kitty -1  --class sysmon --override confirm_os_window_close=0 -e btop]])"
 hyprctl dispatch "hl.dsp.exec_cmd([[kitty -1 --class sysmon --override confirm_os_window_close=0 -e sh -c 'journalctl -f | lnav']])"
