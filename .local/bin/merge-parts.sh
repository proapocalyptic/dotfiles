#!/bin/bash
set -euo pipefail

shopt -s nullglob

merged_count=0
mkdir -p parts

for f in *.{mkv,mp4}; do
  [[ -f "$f" ]] || continue

  if [[ "$f" == S??E??pt1* ]]; then
    tag="pt1"; tag2="pt2"
  elif [[ "$f" == S??E??p1* ]]; then
    tag="p1"; tag2="p2"
  else
    continue
  fi

  epcode="${f:0:6}"

  counterpart="${f/$tag/$tag2}"
  [[ -f "$counterpart" ]] || counterpart=""

  if [[ -z "$counterpart" ]]; then
    ext="${f##*.}"
    for cand in *."$ext"; do
      [[ -f "$cand" ]] || continue
      if [[ "$cand" == "${epcode}${tag2}"* ]]; then
        counterpart="$cand"
        break
      fi
    done
  fi

  if [[ -z "$counterpart" ]]; then
    echo "Warning: No matching $tag2 file found for $f"
    continue
  fi

  ext="${f##*.}"
  output="${f/$tag/}"
  while [[ "$output" == *".${ext}.${ext}" ]]; do
    output="${output%.${ext}.${ext}}.${ext}"
  done

  if [[ -s "$output" ]]; then
    echo "Skipping $f: $output already exists"
    continue
  elif [[ -f "$output" ]]; then
    rm "$output"
  fi

  echo "Merging: $f + $counterpart -> $output"

  concat_list=$(mktemp /tmp/merge_concat.XXXXXX)
  esc1="${f//\'/\'\\\'\'}"
  esc2="${counterpart//\'/\'\\\'\'}"
  printf "file '%s/%s'\nfile '%s/%s'\n" "$PWD" "$esc1" "$PWD" "$esc2" > "$concat_list"

  if ffmpeg -n -f concat -safe 0 -i "$concat_list" -c copy "$output"; then
    mv "$f" "$counterpart" parts/
    ((merged_count++))
  else
    echo "Error merging $f and $counterpart"
  fi
  rm -f "$concat_list"
done

echo "Done. Merged $merged_count file(s)."
