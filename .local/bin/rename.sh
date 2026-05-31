#!/usr/bin/env bash
# rename.sh — interactive batch file renamer
# Usage: rename.sh <source-dir> <names-file>
#
# Walks <source-dir> recursively, prompts you to assign a correct name to each
# file from a plain-text list, then renames and moves all assigned files to a
# new output folder. Supports skip/re-queue, permanent exclude, arbitrary undo,
# extension blacklisting, paginated name list, and crash recovery via a session log.
#
# Key layout:
#   Selection — right-hand keys (see SELECTION_LETTERS below)
#   Commands  — left-hand keys only:
#     q  quit        a  prev page    s  skip
#     z  undo        d  next page    x  exclude

set -o pipefail

# ── ANSI escape codes ─────────────────────────────────────────────────────────
BOLD=$'\033[1m'
DIM=$'\033[2m'
CYAN=$'\033[36m'
YELLOW=$'\033[33m'
GREEN=$'\033[32m'
RED=$'\033[31m'
RESET=$'\033[0m'

# ── Key bindings ──────────────────────────────────────────────────────────────
# Selection uses right-hand keys so the left hand stays on the command keys.
# PAGE_SIZE is derived from the letter count — edit SELECTION_LETTERS to
# change both at once. Reserved left-hand keys (q a s d z x) are excluded.
SELECTION_LETTERS="yuiophjklnm"   # 11 right-hand keys → 11 items per page
PAGE_SIZE=${#SELECTION_LETTERS}

# ── Global state ──────────────────────────────────────────────────────────────
# pending:          files not yet processed this pass
# skipped:          files deferred with [s]; re-queued after pending is exhausted
# excluded:         files permanently dropped with [x]; never re-queued
# assignments:      map of absolute_path -> new_basename (without extension)
# names:            the live pool of available names; shrinks as names are assigned
# blacklisted_exts: extensions (including leading dot) to ignore entirely
declare -a pending=()
declare -a skipped=()
declare -a excluded=()
declare -A assignments=()
declare -a names=()
declare -a blacklisted_exts=()

SOURCE_DIR=""
NAMES_FILE=""
TARGET_DIR=""
RECOVERY_LOG=""      # set to an absolute path at startup

# ── Utilities ─────────────────────────────────────────────────────────────────

die() {
    echo -e "${RED}Error:${RESET} $*" >&2
    exit 1
}

# Return the extension of a file including the leading dot, or empty string.
# Uses basename so that dots in parent directory names don't confuse the match.
get_ext() {
    local f
    f=$(basename "$1")
    if [[ "$f" == *.* ]]; then
        echo ".${f##*.}"
    else
        echo ""
    fi
}

# Return 0 if $1 is present anywhere in the remaining arguments.
in_array() {
    local needle="$1"; shift
    local item
    for item in "$@"; do
        [[ "$item" == "$needle" ]] && return 0
    done
    return 1
}

# Return the 0-based index of character $1 within string $2, or -1 if absent.
# Used to convert a selection letter into its position in SELECTION_LETTERS.
char_index() {
    local char="$1" str="$2"
    local prefix="${str%%"$char"*}"
    # If prefix equals the whole string, the character wasn't found
    if [[ "$prefix" == "$str" ]]; then
        echo -1
    else
        echo "${#prefix}"
    fi
}

# Remove the first occurrence of $1 from the global `names` array.
# Only removes one entry so duplicate names in the list survive correctly.
remove_from_pool() {
    local target="$1"
    local new_names=()
    local removed=false
    local n
    for n in "${names[@]+"${names[@]}"}"; do
        if [[ "$n" == "$target" && "$removed" == false ]]; then
            removed=true
        else
            new_names+=("$n")
        fi
    done
    names=("${new_names[@]+"${new_names[@]}"}")
}

# ── Extension blacklist ───────────────────────────────────────────────────────

# Scan SOURCE_DIR for all unique extensions, display them, and let the user
# select which to blacklist. Uses numeric input — this is a one-time setup
# step, not the main loop, so the letter/number distinction doesn't apply.
# Files with no extension are shown as "(none)" and stored internally as "".
select_blacklist() {
    local -a all_exts=()
    local ext f
    while IFS= read -r -d '' f; do
        ext=$(get_ext "$f")
        in_array "$ext" "${all_exts[@]+"${all_exts[@]}"}" || all_exts+=("$ext")
    done < <(find "$SOURCE_DIR" -type f -print0)

    # Skip the prompt if there's only one extension — nothing to filter
    if [[ ${#all_exts[@]} -le 1 ]]; then
        return
    fi

    echo
    echo -e "  ${BOLD}Extensions found in source directory:${RESET}"
    echo
    local i
    for i in "${!all_exts[@]}"; do
        local label="${all_exts[$i]}"
        [[ -z "$label" ]] && label="(none)"
        printf "  ${DIM}%3d)${RESET}  %s\n" "$((i + 1))" "$label"
    done
    echo
    echo -e "  ${DIM}Enter numbers to blacklist (space-separated), or press enter to skip:${RESET}"
    echo

    local input
    read -rp "  > " input
    [[ -z "$input" ]] && return

    # Parse space-separated tokens; silently ignore anything out of range
    local token
    for token in $input; do
        if [[ "$token" =~ ^[0-9]+$ ]] \
           && (( token >= 1 )) \
           && (( token <= ${#all_exts[@]} )); then
            blacklisted_exts+=("${all_exts[$((token - 1))]}")
        fi
    done

    if [[ ${#blacklisted_exts[@]} -gt 0 ]]; then
        echo
        echo -n -e "  ${YELLOW}Blacklisted:${RESET} "
        local e label
        for e in "${blacklisted_exts[@]}"; do
            label="$e"; [[ -z "$label" ]] && label="(none)"
            echo -n "${label}  "
        done
        echo
    fi
}

# ── File & name loading ───────────────────────────────────────────────────────

# Walk SOURCE_DIR recursively and populate `pending` with absolute paths.
# Excludes: the recovery log, any pre-existing TARGET_DIR, blacklisted extensions.
load_files() {
    while IFS= read -r -d '' f; do
        local abs ext
        abs=$(realpath "$f")

        # Never include the recovery log as a file to be renamed
        [[ "$abs" == "$RECOVERY_LOG" ]] && continue

        # Skip files inside the output folder if it pre-exists from a prior run
        [[ "$abs" == "$TARGET_DIR"/* ]] && continue

        # Skip blacklisted extensions
        ext=$(get_ext "$abs")
        in_array "$ext" "${blacklisted_exts[@]+"${blacklisted_exts[@]}"}" && continue

        pending+=("$abs")
    done < <(find "$SOURCE_DIR" -type f -print0 | sort -z)
}

# Read the names file into the `names` pool. Strips Windows-style CR so the
# script works cleanly on lists edited on either platform.
load_names() {
    while IFS= read -r line; do
        line="${line%$'\r'}"
        [[ -n "$line" ]] && names+=("$line")
    done < "$1"
}

# ── Session recovery ──────────────────────────────────────────────────────────

# Write current assignments and exclusions to the recovery log after every
# state change. If the script is interrupted, this log is replayed on the
# next run to restore progress without losing work.
save_recovery() {
    {
        local path
        for path in "${!assignments[@]}"; do
            printf 'ASSIGNMENT\t%s\t%s\n' "$path" "${assignments[$path]}"
        done
        local ex
        for ex in "${excluded[@]+"${excluded[@]}"}"; do
            printf 'EXCLUDED\t%s\n' "$ex"
        done
    } > "$RECOVERY_LOG"
}

# Read an existing recovery log and restore state into `assignments`, `excluded`,
# and `names`. Rebuilds `pending` by removing already-handled files.
load_recovery() {
    [[ ! -f "$RECOVERY_LOG" ]] && return 1

    local -a assigned_paths=()
    while IFS=$'\t' read -r type arg1 arg2; do
        case "$type" in
            ASSIGNMENT)
                assignments["$arg1"]="${arg2:-}"
                assigned_paths+=("$arg1")
                # Keep the pool consistent with what was assigned last session
                remove_from_pool "${arg2:-}"
                ;;
            EXCLUDED)
                excluded+=("$arg1")
                ;;
        esac
    done < "$RECOVERY_LOG"

    # Drop already-handled files from pending so they aren't re-prompted
    local new_pending=()
    local f
    for f in "${pending[@]+"${pending[@]}"}"; do
        if in_array "$f" "${assigned_paths[@]+"${assigned_paths[@]}"}" \
           || in_array "$f" "${excluded[@]+"${excluded[@]}"}"; then
            continue
        fi
        new_pending+=("$f")
    done
    pending=("${new_pending[@]+"${new_pending[@]}"}")

    return 0
}

# ── Display helpers ───────────────────────────────────────────────────────────

# One-line status bar at the top of every prompt screen.
print_header() {
    printf "${BOLD}rename${RESET}  ${DIM}│  %d pending · %d skipped · %d assigned${RESET}\n" \
        "${#pending[@]}" "${#skipped[@]}" "${#assignments[@]}"
    echo -e "${DIM}────────────────────────────────────────────────────────────${RESET}"
}

# Print one page of the names list, labelled with selection letters.
# $1 = 0-based page index. Shows a page indicator when there is more than one page.
print_names() {
    local page="$1"
    local total=${#names[@]}

    if [[ $total -eq 0 ]]; then
        echo -e "  ${DIM}(name list exhausted)${RESET}"
        return
    fi

    local total_pages=$(( (total + PAGE_SIZE - 1) / PAGE_SIZE ))
    local start=$(( page * PAGE_SIZE ))
    local end=$(( start + PAGE_SIZE - 1 ))
    (( end >= total )) && end=$(( total - 1 ))

    # Page indicator — only shown when the list spans more than one page
    if [[ $total_pages -gt 1 ]]; then
        printf "  ${DIM}page %d / %d   [a] prev  [d] next${RESET}\n\n" \
            "$((page + 1))" "$total_pages"
    fi

    local i letter_idx=0
    for (( i = start; i <= end; i++ )); do
        local letter="${SELECTION_LETTERS:$letter_idx:1}"
        printf "  ${DIM}%s)${RESET}  %s\n" "$letter" "${names[$i]}"
        (( letter_idx++ ))
    done
}

# Print the current filename prominently. Shows parent directory in dim text
# when the file is in a subdirectory — visually distinct from the filename itself.
print_file() {
    local filepath="$1"
    local base parent source_base
    base=$(basename "$filepath")
    parent=$(basename "$(dirname "$filepath")")
    source_base=$(basename "$SOURCE_DIR")

    echo
    if [[ "$parent" == "$source_base" ]]; then
        echo -e "  ${BOLD}${CYAN}${base}${RESET}"
    else
        echo -e "  ${BOLD}${CYAN}${base}${RESET}  ${DIM}(${parent})${RESET}"
    fi
    echo
}

# Command reference line printed just before the input prompt.
print_hint() {
    echo -e "  ${DIM}[letter] assign  [s] skip  [x] exclude  [z] undo  [q] quit${RESET}"
    echo
}

# ── Undo ──────────────────────────────────────────────────────────────────────

# Show all current assignments as a numbered list and let the user pick one to
# reverse. Uses numbers rather than letters — the undo list has no page
# navigation and is typically short. The freed name returns to the pool; the
# file is re-queued at the front of pending so it comes up immediately next.
do_undo() {
    local -a assigned_files=()
    local path
    for path in "${!assignments[@]}"; do
        assigned_files+=("$path")
    done

    if [[ ${#assigned_files[@]} -eq 0 ]]; then
        echo -e "\n  ${DIM}Nothing to undo.${RESET}\n"
        read -rsp "  [press any key]" -n1
        echo
        return
    fi

    echo
    echo -e "  ${BOLD}Undo which assignment?${RESET}"
    echo
    local i
    for i in "${!assigned_files[@]}"; do
        local p="${assigned_files[$i]}"
        printf "  ${DIM}%3d)${RESET}  %s ${DIM}→${RESET} %s\n" \
            "$((i + 1))" "$(basename "$p")" "${assignments[$p]}"
    done
    echo
    echo -e "  ${DIM}[enter] cancel${RESET}"
    echo

    local choice
    read -rp "  > " choice
    [[ -z "$choice" ]] && return

    if ! [[ "$choice" =~ ^[0-9]+$ ]] \
       || (( choice < 1 )) \
       || (( choice > ${#assigned_files[@]} )); then
        echo -e "\n  ${RED}Invalid selection.${RESET}"
        read -rsp "  [press any key]" -n1
        echo
        return
    fi

    local target="${assigned_files[$((choice - 1))]}"
    local freed="${assignments[$target]}"

    unset "assignments[$target]"
    names+=("$freed")
    pending=("$target" "${pending[@]+"${pending[@]}"}")

    save_recovery
    echo -e "\n  ${GREEN}Undone:${RESET} ${freed} freed, $(basename "$target") re-queued."
    read -rsp "  [press any key]" -n1
    echo
}

# ── Per-file prompt ───────────────────────────────────────────────────────────

# Main interactive loop for a single file. Tracks the current page as a local
# variable that persists across redraws. Clamps the page index each iteration
# in case names were removed from the pool (reducing total page count).
# Returns only when the file is assigned, skipped, or excluded.
prompt_file() {
    local filepath="$1"
    local current_page=0

    while true; do
        # Clamp page in case pool shrank since last redraw
        local total_pages=$(( (${#names[@]} + PAGE_SIZE - 1) / PAGE_SIZE ))
        [[ $total_pages -eq 0 ]] && total_pages=1
        (( current_page >= total_pages )) && current_page=$(( total_pages - 1 ))

        clear
        print_header
        echo
        print_names "$current_page"
        print_file "$filepath"
        print_hint

        local input
        read -rp "  > " input
        # Normalise to lowercase for command matching
        local input_lower="${input,,}"

        case "$input_lower" in
            a)
                # Previous page — clamp at 0
                (( current_page > 0 )) && (( current_page-- ))
                ;;
            d)
                # Next page — clamp at last page
                (( current_page < total_pages - 1 )) && (( current_page++ ))
                ;;
            s)
                # Temporarily defer; re-enters queue after pending clears
                skipped+=("$filepath")
                save_recovery
                return
                ;;
            x)
                # Permanently drop; not re-queued and not committed
                excluded+=("$filepath")
                save_recovery
                return
                ;;
            z)
                do_undo
                # Fall through to redraw and re-prompt for the same file
                ;;
            q)
                echo
                echo -e "  ${YELLOW}Session saved to recovery log. Exiting.${RESET}"
                save_recovery
                exit 0
                ;;
            '')
                # Empty input — just redraw
                ;;
            ?)
                # Single character: check if it's a valid selection letter
                local letter_idx
                letter_idx=$(char_index "$input_lower" "$SELECTION_LETTERS")
                if (( letter_idx >= 0 )); then
                    local name_idx=$(( current_page * PAGE_SIZE + letter_idx ))
                    if (( name_idx < ${#names[@]} )); then
                        local chosen="${names[$name_idx]}"
                        assignments["$filepath"]="$chosen"
                        remove_from_pool "$chosen"
                        save_recovery
                        return
                    fi
                fi
                # Letter not in selection set or out of range — redraw silently
                ;;
            *)
                # Multi-character input — redraw silently
                ;;
        esac
    done
}

# ── Commit ────────────────────────────────────────────────────────────────────

# Show a full summary of planned renames, ask for confirmation, then execute.
# On success: renames and moves files to TARGET_DIR, writes remaining unused
# names back to NAMES_FILE, and removes the recovery log.
confirm_and_commit() {
    if [[ ${#assignments[@]} -eq 0 ]]; then
        echo -e "\n  ${YELLOW}No assignments to commit.${RESET}\n"
        return
    fi

    clear
    echo -e "${BOLD}Summary${RESET}"
    echo -e "${DIM}────────────────────────────────────────────────────────────${RESET}"
    echo

    local path
    for path in "${!assignments[@]}"; do
        local ext base newname
        ext=$(get_ext "$path")
        base=$(basename "$path")
        newname="${assignments[$path]}${ext}"
        printf "  %s ${DIM}→${RESET} %s\n" "$base" "$newname"
    done

    echo
    echo -e "  ${DIM}Output folder:${RESET} ${BOLD}${TARGET_DIR}${RESET}"
    echo
    read -rp "  Commit? [y/N] " confirm

    if [[ "${confirm,,}" != "y" ]]; then
        echo -e "\n  ${YELLOW}Aborted.${RESET}\n"
        return
    fi

    mkdir -p "$TARGET_DIR"

    echo
    for path in "${!assignments[@]}"; do
        local ext newname dest
        ext=$(get_ext "$path")
        newname="${assignments[$path]}${ext}"
        dest="${TARGET_DIR}/${newname}"

        if mv -- "$path" "$dest"; then
            echo -e "  ${GREEN}✓${RESET}  ${newname}"
        else
            echo -e "  ${RED}✗${RESET}  failed: $(basename "$path")"
        fi
    done

    # Write unused names back to the names file.
    # The original is preserved at NAMES_FILE.bak so this is safe.
    {
        local n
        for n in "${names[@]+"${names[@]}"}"; do
            echo "$n"
        done
    } > "$NAMES_FILE"

    [[ -f "$RECOVERY_LOG" ]] && rm "$RECOVERY_LOG"

    echo
    echo -e "  ${GREEN}Done.${RESET} Names list updated; backup preserved at ${NAMES_FILE}.bak"
}

# ── Main ──────────────────────────────────────────────────────────────────────

main() {
    [[ $# -lt 2 ]] && die "Usage: $(basename "$0") <source-dir> <names-file>"

    SOURCE_DIR=$(realpath "$1")
    NAMES_FILE=$(realpath "$2")
    # Recovery log in CWD so it never appears in the file list when CWD == SOURCE_DIR
    RECOVERY_LOG="$(pwd)/.rename_session.log"

    [[ ! -d "$SOURCE_DIR" ]] && die "Source directory not found: $SOURCE_DIR"
    [[ ! -f "$NAMES_FILE" ]] && die "Names file not found: $NAMES_FILE"

    # Back up names file once; don't clobber an existing backup
    local backup="${NAMES_FILE}.bak"
    if [[ ! -f "$backup" ]]; then
        cp "$NAMES_FILE" "$backup"
    fi

    # Prompt for output folder; created inside SOURCE_DIR at commit time
    echo
    read -rp "  Output folder name: " folder_name
    [[ -z "$folder_name" ]] && die "Output folder name cannot be empty."
    TARGET_DIR="${SOURCE_DIR}/${folder_name}"

    # Extension blacklist runs before load_files so the filter is ready
    select_blacklist

    load_files "$SOURCE_DIR"
    load_names "$NAMES_FILE"

    # Offer to resume an interrupted session if a recovery log exists
    if [[ -f "$RECOVERY_LOG" ]]; then
        echo
        echo -e "  ${YELLOW}Recovery log found.${RESET} Resume previous session? [y/N]"
        read -rp "  > " resume
        if [[ "${resume,,}" == "y" ]]; then
            load_recovery
            echo -e "  ${GREEN}Resumed.${RESET} ${#assignments[@]} assignment(s) restored."
            read -rsp "  [press any key]" -n1
            echo
        else
            rm "$RECOVERY_LOG"
        fi
    fi

    # Main loop: drain pending first, then cycle through skipped indefinitely.
    # A file stays in rotation until it is assigned or excluded.
    while [[ ${#pending[@]} -gt 0 || ${#skipped[@]} -gt 0 ]]; do
        local current
        if [[ ${#pending[@]} -gt 0 ]]; then
            current="${pending[0]}"
            pending=("${pending[@]:1}")
        else
            current="${skipped[0]}"
            skipped=("${skipped[@]:1}")
        fi
        prompt_file "$current"
    done

    confirm_and_commit
}

main "$@"
