#!/bin/bash

hyprctl dispatch 'hl.dsp.exec_cmd("thunar /home/")'
hyprctl dispatch 'hl.dsp.focus({ window = "class:kitty-ranger" })'
sleep 1
ranger
