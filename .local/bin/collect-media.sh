#!/usr/bin/env bash
# collect-media.sh
# Recursively finds all video and audio files in the current directory
# and moves them into a named destination folder.
#
# Usage:
#   collect-media.sh [OPTIONS] <folder-name>
#
# Options:
#   -r, --root <path>   Root directory to search (default: current directory)
#   -c, --copy          Copy files instead of moving them
#   -d, --dry-run       Show what would happen without making any changes
#   -h, --help          Show this help message

set -euo pipefail

# ---------------------------------------------------------------------------
# Defaults
# ---------------------------------------------------------------------------
ROOT_DIR="$(pwd)"
ACTION="move"       # move | copy
DRY_RUN=false
DEST_NAME=""

# ---------------------------------------------------------------------------
# Supported extensions
# ---------------------------------------------------------------------------
VIDEO_EXTS=("mp4" "mkv" "avi" "mov" "wmv" "flv" "webm" "m4v" "mpg" "mpeg"
            "3gp" "3g2" "ogv" "ts" "mts" "m2ts" "vob" "rm" "rmvb" "divx"
            "xvid" "h264" "h265" "hevc")

AUDIO_EXTS=("mp3" "flac" "wav" "aac" "ogg" "wma" "m4a" "opus" "aiff" "aif"
            "ape" "wv" "mka" "mid" "midi" "ra" "amr" "au" "caf" "dts"
            "ac3" "alac" "dsf" "dff")

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------
usage() {
    sed -n '/^# Usage:/,/^[^#]/p' "$0" | sed 's/^# \{0,1\}//' | head -n -1
    exit 0
}

info()    { printf '\033[0;34m[INFO]\033[0m  %s\n' "$*"; }
success() { printf '\033[0;32m[OK]\033[0m    %s\n' "$*"; }
warn()    { printf '\033[0;33m[WARN]\033[0m  %s\n' "$*"; }
error()   { printf '\033[0;31m[ERROR]\033[0m %s\n' "$*" >&2; }
die()     { error "$*"; exit 1; }

# Appends find -iname tokens for a list of extensions into a named array.
# Each extension produces: -o -iname "*.ext"
# The caller must strip the leading -o before passing to find.
append_find_inames() {
    local target_array=$1
    shift
    local exts=("$@")
    for ext in "${exts[@]}"; do
        eval "${target_array}+=(-o -iname \"*.\${ext}\")"
    done
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------
while [[ $# -gt 0 ]]; do
    case "$1" in
        -r|--root)
            [[ -z "${2:-}" ]] && die "--root requires a path argument"
            ROOT_DIR="$2"; shift 2 ;;
        -c|--copy)
            ACTION="copy"; shift ;;
        -d|--dry-run)
            DRY_RUN=true; shift ;;
        -h|--help)
            usage ;;
        -*)
            die "Unknown option: $1" ;;
        *)
            [[ -n "$DEST_NAME" ]] && die "Unexpected argument: $1"
            DEST_NAME="$1"; shift ;;
    esac
done

[[ -z "$DEST_NAME" ]] && die "No destination folder name provided.\nUsage: $0 [OPTIONS] <folder-name>"
[[ -d "$ROOT_DIR" ]]  || die "Root directory does not exist: $ROOT_DIR"

DEST_DIR="${ROOT_DIR}/${DEST_NAME}"

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
info "Root    : $ROOT_DIR"
info "Target  : $DEST_DIR"
info "Action  : $ACTION"
$DRY_RUN && warn "Dry-run mode — no files will be changed."
echo

# ---------------------------------------------------------------------------
# Build find expression
# ---------------------------------------------------------------------------
# Build one flat array of (-iname "*.ext" -o ...) terms, then strip the
# leading -o so the whole thing sits cleanly inside a \( ... \) group.
MEDIA_EXPR=()
append_find_inames MEDIA_EXPR "${VIDEO_EXTS[@]}"
append_find_inames MEDIA_EXPR "${AUDIO_EXTS[@]}"
# Drop the leading -o (first element)
MEDIA_EXPR=("${MEDIA_EXPR[@]:1}")

mapfile -t FOUND_FILES < <(
    find "$ROOT_DIR" \
        -not -path "${DEST_DIR}/*" \
        -type f \( "${MEDIA_EXPR[@]}" \) \
        | sort
)

# ---------------------------------------------------------------------------
# Nothing found?
# ---------------------------------------------------------------------------
if [[ ${#FOUND_FILES[@]} -eq 0 ]]; then
    warn "No video or audio files found under: $ROOT_DIR"
    exit 0
fi

info "Found ${#FOUND_FILES[@]} file(s)."
echo

# ---------------------------------------------------------------------------
# Create destination folder
# ---------------------------------------------------------------------------
if ! $DRY_RUN; then
    mkdir -p "$DEST_DIR"
fi

# ---------------------------------------------------------------------------
# Move / copy files
# ---------------------------------------------------------------------------
moved=0
skipped=0
errors=0
# Note: (( var++ )) returns exit code 1 when the result is 0, which trips
# set -e. Using += avoids that pitfall entirely.

for src in "${FOUND_FILES[@]}"; do
    filename="$(basename "$src")"
    dest="${DEST_DIR}/${filename}"

    # Handle filename collisions by appending a counter
    if [[ -e "$dest" ]]; then
        base="${filename%.*}"
        ext="${filename##*.}"
        counter=1
        while [[ -e "${DEST_DIR}/${base}_${counter}.${ext}" ]]; do
            (( counter++ ))
        done
        dest="${DEST_DIR}/${base}_${counter}.${ext}"
        warn "Collision — renaming to: $(basename "$dest")"
    fi

    rel_src="${src#$ROOT_DIR/}"

    if $DRY_RUN; then
        printf '  [dry-run] %s  ->  %s\n' "$rel_src" "$(basename "$dest")"
        moved=$(( moved + 1 ))
        continue
    fi

    if [[ "$ACTION" == "move" ]]; then
        if mv -- "$src" "$dest" 2>/dev/null; then
            success "Moved  : $rel_src"
            moved=$(( moved + 1 ))
        else
            error "Failed : $rel_src"
            errors=$(( errors + 1 ))
        fi
    else
        if cp -- "$src" "$dest" 2>/dev/null; then
            success "Copied : $rel_src"
            moved=$(( moved + 1 ))
        else
            error "Failed : $rel_src"
            errors=$(( errors + 1 ))
        fi
    fi
done

# ---------------------------------------------------------------------------
# Final report
# ---------------------------------------------------------------------------
echo
verb=$( [[ "$ACTION" == "move" ]] && echo "Moved" || echo "Copied" )
$DRY_RUN && verb="Would move"
info "Done — ${verb}: ${moved}  |  Errors: ${errors}"
