#!/bin/bash
kitty -1 --class kitty-access-menu  --title access-menu --config ~/.config/kitty/access-menu.conf --override confirm_os_window_close=0 -e "/home/alex/.local/bin/access-menu" &
sleep .25
kitty -1 --class kitty-scratcher --override confirm_os_window_close=0 -e micro "Scratcher.md" &
zsh
