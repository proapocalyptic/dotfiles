. "$HOME/.cargo/env"
export SUDO_EDITOR=nvim
export EDITOR=~/.local/bin/nvim-open
export VISUAL=~/.local/bin/nvim-open
export QT_LOGGING_RULES="qt.bluetooth.bluez.warning=false"

: "${XDG_CONFIG_HOME:=$HOME/.config}"
: "${XDG_DATA_HOME:=$HOME/.local/share}"
: "${XDG_STATE_HOME:=$HOME/.local/state}"
: "${XDG_CACHE_HOME:=$HOME/.cache}"
export XDG_CONFIG_HOME XDG_DATA_HOME XDG_STATE_HOME XDG_CACHE_HOME
export TASKRC=~/.config/task/.taskrc 
export TASKDATA="$XDG_DATA_HOME/task"

export VIT_DIR=/home/alex/.config/vit

