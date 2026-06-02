# Hyprland window management functions
# Requires Hyprland 0.55+ (Lua config)

# ---------------------------------------------------------------------------
# Internal helper: parse window selector flag+value or bare positional
# Returns: selector string e.g. "class:kitty", "title:Firefox", "tag:mywork"
# ---------------------------------------------------------------------------
_hypr_window_selector() {
    local flag="$1" value="$2"
    case "$flag" in
        --class|-c)
            [[ -z "$value" ]] && { echo "hypr: --class requires a pattern" >&2; return 1; }
            echo "class:$value"
            ;;
        --title|-t)
            [[ -z "$value" ]] && { echo "hypr: --title requires a pattern" >&2; return 1; }
            echo "title:$value"
            ;;
        --match-tag)
            [[ -z "$value" ]] && { echo "hypr: --match-tag requires a name" >&2; return 1; }
            echo "tag:$value"
            ;;
        -*)
            echo "hypr: unknown flag '$flag'" >&2; return 1
            ;;
        *)
            [[ -z "$flag" ]] && { echo "hypr: no window selector provided" >&2; return 1; }
            echo "class:$flag"
            ;;
    esac
}

# ---------------------------------------------------------------------------
# hfocus: focus a window
# Usage: hfocus [--class|-c <pattern>] [--title|-t <pattern>] [--match-tag <name>]
# ---------------------------------------------------------------------------
hfocus() {
    local selector

    case "$1" in
        --class|-c|--title|-t|--match-tag)
            selector=$(_hypr_window_selector "$1" "$2") || return 1
            ;;
        *)
            selector=$(_hypr_window_selector "$1") || return 1
            ;;
    esac

    hyprctl dispatch "hl.dsp.focus({ window = [[$selector]] })"
}

# ---------------------------------------------------------------------------
# hmove: move a window to a workspace
# Usage: hmove [--class|-c <pattern>] [--title|-t <pattern>] [--match-tag <name>] <workspace>
#        hmove <workspace>   (moves active window)
# ---------------------------------------------------------------------------
hmove() {
    local selector workspace

    if [[ $# -eq 1 ]]; then
        workspace="$1"
        hyprctl dispatch "hl.dsp.window.move({ workspace = [[$workspace]] })"
        return
    fi

    while [[ $# -gt 1 ]]; do
        case "$1" in
            --class|-c|--title|-t|--match-tag)
                selector=$(_hypr_window_selector "$1" "$2") || return 1
                shift 2
                ;;
            *)
                selector=$(_hypr_window_selector "$1") || return 1
                shift
                ;;
        esac
    done

    workspace="$1"
    hyprctl dispatch "hl.dsp.window.move({ workspace = [[$workspace]], window = [[$selector]] })"
}

# ---------------------------------------------------------------------------
# htag-add: add a tag to a window
# Usage: htag-add [--class|-c <pattern>] [--title|-t <pattern>] [--match-tag <name>] <tag>
#        htag-add <tag>   (tags active window)
# ---------------------------------------------------------------------------
htag-add() {
    local selector tag

    if [[ $# -eq 1 ]]; then
        tag="$1"
        hyprctl dispatch "hl.dsp.window.tag({ tag = [[+$tag]] })"
        return
    fi

    while [[ $# -gt 1 ]]; do
        case "$1" in
            --class|-c|--title|-t|--match-tag)
                selector=$(_hypr_window_selector "$1" "$2") || return 1
                shift 2
                ;;
            *)
                selector=$(_hypr_window_selector "$1") || return 1
                shift
                ;;
        esac
    done

    tag="$1"
    hyprctl dispatch "hl.dsp.window.tag({ tag = [[+$tag]], window = [[$selector]] })"
}

# ---------------------------------------------------------------------------
# htag-remove: remove a tag from a window
# Usage: htag-remove [--class|-c <pattern>] [--title|-t <pattern>] [--match-tag <name>] <tag>
#        htag-remove <tag>   (untags active window)
# ---------------------------------------------------------------------------
htag-remove() {
    local selector tag

    if [[ $# -eq 1 ]]; then
        tag="$1"
        hyprctl dispatch "hl.dsp.window.tag({ tag = [[-$tag]] })"
        return
    fi

    while [[ $# -gt 1 ]]; do
        case "$1" in
            --class|-c|--title|-t|--match-tag)
                selector=$(_hypr_window_selector "$1" "$2") || return 1
                shift 2
                ;;
            *)
                selector=$(_hypr_window_selector "$1") || return 1
                shift
                ;;
        esac
    done

    tag="$1"
    hyprctl dispatch "hl.dsp.window.tag({ tag = [[-$tag]], window = [[$selector]] })"
}
