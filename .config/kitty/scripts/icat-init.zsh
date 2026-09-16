#!/bin/zsh
echo "$KITTY_WINDOW_ID" >| "${XDG_CACHE_HOME:-$HOME/.cache}/icat_win_id"
exec zsh -i
