#!/bin/bash
rm -f /tmp/nvim.sock
    kitty --detach --class kitty-nvim -e nvim --listen /tmp/nvim.sock
    while [ ! -S /tmp/nvim.sock ]; do
        sleep 0.1
    done

