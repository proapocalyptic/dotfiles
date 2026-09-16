#!/usr/bin/env bash
# CODED BY CLAUDE THE ROBOT
# print a random message in a random toilet font
# Font and phrase lists are sourced from ~/.config/command-list/
# Lines beginning with # are treated as comments and ignored.
# If toilet fails for a font, that font is automatically commented out.
# Events are logged to $XDG_STATE_HOME/randmsg/randmsg.log

CMD=toilet
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/command-list"
FONT_FILE="$CONFIG_DIR/small-terminal-fonts-list"
PHRASE_FILE="$CONFIG_DIR/small-terminal-phrase-list"
LOG_DIR="${XDG_STATE_HOME:-$HOME/.local/state}/randmsg"
LOG_FILE="$LOG_DIR/randmsg.log"
MAX_LOG_LINES=10000

log() {
    local level="$1"; shift
    printf '[%s] [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$level" "$*" >> "$LOG_FILE"
}

trim_log() {
    [[ ! -f "$LOG_FILE" ]] && return
    local tmp
    tmp=$(mktemp "${LOG_DIR}/randmsg.log.XXXXXX")
    tail -n "$MAX_LOG_LINES" "$LOG_FILE" > "$tmp" 2>/dev/null
    mv "$tmp" "$LOG_FILE"
}

trap trim_log EXIT

if ! mkdir -p "$LOG_DIR"; then
    printf 'error: could not create log directory: %s\n' "$LOG_DIR" >&2
    exit 1
fi

for f in "$FONT_FILE" "$PHRASE_FILE"; do
    if [[ ! -f "$f" ]]; then
        printf 'error: list file not found: %s\n' "$f" >&2
        log ERROR "list file not found: $f"
        exit 1
    fi
done

if ! command -v "$CMD" &>/dev/null; then
    printf 'error: %s not found\n' "$CMD" >&2
    log ERROR "$CMD not found"
    exit 1
fi

mapfile -t font_lines < <(grep -v '^\s*#' "$FONT_FILE" | grep -v '^\s*$')
fonts=()
for f in "${font_lines[@]}"; do
    f="${f#\'}"; f="${f%\'}"
    f="${f#\"}"; f="${f%\"}"
    fonts+=("$f")
done
mapfile -t phrases < <(grep -v '^\s*#' "$PHRASE_FILE" | grep -v '^\s*$')

if (( ${#fonts[@]} == 0 )); then
    printf 'error: font list is empty: %s\n' "$FONT_FILE" >&2
    log ERROR "font list is empty: $FONT_FILE"
    exit 1
fi
if (( ${#phrases[@]} == 0 )); then
    printf 'error: phrase list is empty: %s\n' "$PHRASE_FILE" >&2
    log ERROR "phrase list is empty: $PHRASE_FILE"
    exit 1
fi

idx=$((RANDOM % ${#fonts[@]}))
font=${fonts[$idx]}
font_line=${font_lines[$idx]}
phrase=${phrases[$RANDOM % ${#phrases[@]}]}

"$CMD" -f "$font" "$phrase"
toilet_exit=$?

if (( toilet_exit != 0 )); then
    printf 'note: toilet failed on font "%s" — commenting it out in %s\n' "$font" "$FONT_FILE" >&2
    awk -v f="$font_line" '{if ($0 == f) print "# " $0; else print}' "$FONT_FILE" > "${FONT_FILE}.tmp" && mv "${FONT_FILE}.tmp" "$FONT_FILE"
    log ERROR "toilet failed on font \"$font\" with phrase \"$phrase\" — font commented out"
    exit "$toilet_exit"
fi

printf '\e[30m%s\e[0m\n' "$font"
log INFO "font=\"$font\" phrase=\"$phrase\""
