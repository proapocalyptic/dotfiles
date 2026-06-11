#!/bin/bash
rm -f /tmp/nvim.sock
    kitty -1 --instance-group nvim --class kitty-nvim --detach -e nvim --listen /tmp/nvim.sock
    while [ ! -S /tmp/nvim.sock ]; do
        sleep 0.1
    done

