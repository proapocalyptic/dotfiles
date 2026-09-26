export XDG_CONFIG_HOME=/home/alex/.config
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.config/hypr/scripts:$PATH"
export PATH="$PATH:/home/alex/.cargo/bin"
export PATH="$HOME/.config/kitty/scripts:$PATH"
export PATH=~/.npm-global/bin:$PATH
export TERMCMD="kitty"
export MAKEFLAGS="-j$(nproc)"
export TASKRC="/home/alex/.config/task/.taskrc"
fpath=(/usr/share/zsh/site-functions $fpath)

setopt EXTENDED_GLOB 

source '/home/alex/.zshcompletions'
 


setopt hist_ignore_dups

# Completion for kitty
command kitty + complete setup zsh | source /dev/stdin

#alex's source
source ~/.custom-shell-functions
source ~/.custom-aliases
source ~/.personal-shell-variables

#syntax zsh-syntax-highlighting
source /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets regexp)
typeset -A ZSH_HIGHLIGHT_REGEXP
ZSH_HIGHLIGHT_REGEXP+=('^[^ ]+\.(jpg|jpeg|png|gif|webp|avif|bmp|tiff|svg|ico) ?$' 'fg=cyan,bold')

#plugins
source /home/alex/.local/share/zsh-plugins/zsh-vi-mode/zsh-vi-mode.plugin.zsh

#prompt
PROMPT='%F{blue}%~%f%(?..[%F{red}%?%f] )$ '
RPROMPT='%F{8}⏱ %t%f$(fsmap_pending)'

# Filesystem-map annotation queue. Shows one dot per unreviewed note so they
# surface passively instead of interrupting you mid-task; `fsmap-notes review`
# clears them. Two deliberate choices:
#   - sqlite3 directly, not `fsmap-notes count`: RPROMPT is redrawn on every
#     keystroke-ish boundary, and a Python interpreter start (~25ms) to fetch
#     one integer is a latency tax you would feel.
#   - nothing at all when the count is zero, so a clean queue costs no width.
fsmap_pending() {
  local db="${XDG_DATA_HOME:-$HOME/.local/share}/opencode/fsmap/index.db"
  [[ -r $db ]] || return 0
  local n
  n=$(sqlite3 "$db" 'SELECT COUNT(*) FROM notes_pending' 2>/dev/null) || return 0
  (( n > 0 )) || return 0
  # Cap the dots at 8; past that the count stops being glanceable anyway.
  (( n > 8 )) && n=8
  print -Pn "%F{3}%{$n%}●%f"
}
# Required for $(...) inside PROMPT/RPROMPT to be evaluated rather than shown
# verbatim. Without it the function above would print as literal text.
setopt prompt_subst


eval "$(fzf --zsh)"
eval "$(zoxide init zsh)"
eval "$(navi widget zsh)"
eval $(thefuck --alias fuck)
eval $(dircolors -b)
alias grep='grep --color=auto'


#prevents big command sign from printing in small windows, removed the test for interactive shell because $COLUMNS shouldn't be defined in a non-interactive shell.
#
#

if [[ -z $ZSH_NO_HEADER ]]; then
    if [[ $COLUMNS -gt 85 ]]; then
        command-list.sh
    fi
    if [[ $COLUMNS -lt 85 ]]; then
        small-terminal-header.sh
    fi
fi

if [[ "$ZSH_NO_HEADER" == "2" ]]; then
  unsetopt histverify
  wtype "
  "
  echo "Dear Computer,"
 
PROMPT=$'%{\e[38;2;'${PROMPT_COLOR:-184;168;127}$'m%}%~ %# %{\e[0m%}'

  RPROMPT=$'%{\e[38;2;'${PROMPT_COLOR:-235;221;178}$'m%}%{\e[0m%}'
  setopt histverify
fi

# opencode
export PATH=/home/alex/.opencode/bin:$PATH


# in .zshrc, before sourcing zsh-autosuggestions
_zsh_autosuggest_strategy_min_chars() {
    (( ${#1} >= 3 )) && _zsh_autosuggest_strategy_history "$@"
}
ZSH_AUTOSUGGEST_STRATEGY=(min_chars)

source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh

#add filename completion to nvim shortcut
compdef _files n

tailscale up


# Added by Antigravity CLI installer
export PATH="/home/alex/.local/opt/Antigravity:$PATH"
