#!/bin/bash
set -euo pipefail

SRC_DIR="${1:-$HOME/Downloads/font-tbi}"
DEST_DIR="$HOME/.fonts"

STYLE_RE="-(BoldItalic|ExtraBoldItalic|SemiBoldItalic|LightItalic|MediumItalic|BlackItalic|ThinItalic|ExtraLightItalic|HairlineItalic|Bold|Italic|Light|Medium|SemiBold|ExtraBold|Black|Thin|ExtraLight|Hairline|Regular|Roman|Oblique|Book|Demi|Heavy)$"
VARIABLE_RE="-(Variable|VF)|\[wght\]|\[wdth\]|\[opsz\]|\[slnt\]|\[ital\]|[-_ ]?V$"
VARIABLE_STRIP_RE="[-_ ]?[Vv]([Ff])?[-_ ]?[0-9.]*$|[-_ ]?VariableFont[-_ ]?[a-zA-Z,]*$|[-_ ]?Variable(Italic)?$"

tmpfile=$(mktemp)
selected_file=$(mktemp)
trap 'rm -f "$tmpfile" "$selected_file"' EXIT

find "$SRC_DIR" -type f \( -name '*.ttf' -o -name '*.otf' -o -name '*.otc' -o -name '*.ttc' \) \
    ! -path '*/__MACOSX/*' ! -path '*/.DS_Store' -print0 | while IFS= read -r -d '' f; do
    basename="${f##*/}"
    stem="${basename%.*}"
    ext="${basename##*.}"

    is_var=0
    echo "$stem" | grep -qiE "$VARIABLE_RE" && is_var=1

    family="$stem"
    if [ "$is_var" -eq 1 ]; then
        family=$(echo "$family" | sed -E "s/$VARIABLE_STRIP_RE//")
    fi
    while : ; do
        stripped=$(echo "$family" | sed -E "s/$STYLE_RE//")
        [ "$stripped" = "$family" ] && break
        family="$stripped"
    done

    [ -z "$family" ] && family="$stem"

    echo "$family|$is_var|$ext|$f"
done > "$tmpfile"

mkdir -p "$DEST_DIR"

awk -F'|' '!seen[$1]++ {print $1}' "$tmpfile" | while IFS= read -r family; do
    [ -z "$family" ] && continue

    records=$(awk -F'|' -v f="$family" '$1 == f' "$tmpfile")
    has_var=$(echo "$records" | awk -F'|' '$2 == 1' | wc -l)

    if [ "$has_var" -gt 0 ]; then
        echo "$records" | awk -F'|' '$2 == 1 {print $4}'
    else
        echo "$records" | awk -F'|' '{
            split($4, parts, "/")
            fn = parts[length(parts)]
            sub(/\.[^.]+$/, "", fn)
            priority = ($3 == "otf") ? 0 : ($3 == "ttf") ? 1 : ($3 == "otc") ? 2 : 3
            if (!(fn in best) || priority < best_prio[fn]) {
                best[fn] = $4
                best_prio[fn] = priority
            }
        } END { for (f in best) print best[f] }'
    fi
done >> "$selected_file"

count=0
sort -u "$selected_file" | while IFS= read -r path; do
    [ -z "$path" ] && continue
    cp -n "$path" "$DEST_DIR/"
    echo "${path##*/}"
    count=$((count + 1))
done

echo "---"
echo "Installed $count fonts. Updating cache..."
fc-cache -fv "$DEST_DIR" 2>/dev/null
echo "Done."
You can create it with:
cat > ~/.local/bin/install-fonts << 'SCRIPT'
...paste above...
SCRIPT
chmod +x ~/.local/bin/install-fonts
Then run install-fonts to install from the default dir, or install-fonts /some/other/path for a different source.
