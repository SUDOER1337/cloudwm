#!/usr/bin/env bash
# wallpaper-picker
# Feh + Rofi wallpaper picker
# Drop this in ~/.local/bin and chmod +x it.

set -euo pipefail

# CONFIG
WALLPAPERS_DIR="${WALLPAPERS_DIR:-$HOME/Pictures/Wallpapers}"   # change as needed
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/wallpaper-picker"
THUMB_DIR="$CACHE_DIR/thumbs"
THUMB_W=300   # thumbnail width (px)
ROFI_CMD="${ROFI_CMD:-rofi -dmenu -i -p 'Wallpaper' -theme ~/cloudwm/rofi/wallpaper/wallpaper.rasi}"
FEH_OPTS="${FEH_OPTS:---bg-fill}"   # feel free to change to --bg-scale/--bg-center

PREVIEW_CMD="${PREVIEW_CMD:-sxiv -q -t -1}" # if sxiv not available, leave empty

mkdir -p "$THUMB_DIR"

# find images (common types), ignore hidden dirs
mapfile -t files < <(find "$WALLPAPERS_DIR" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.bmp' \) -print)

if [ ${#files[@]} -eq 0 ]; then
  echo "No wallpapers found in $WALLPAPERS_DIR" >&2
  exit 1
fi

# generate a menu list: "basename ||| fullpath" so rofi shows readable names
menu=()
for fp in "${files[@]}"; do
  base="$(basename "$fp")"
  menu+=("$base|||$fp")
done

# rofi input: show basename but return full path
# Use "awk -F '|||' '{print $2}'" to get the path afterwards
choice="$(printf '%s\n' "${menu[@]}" | sed 's/|||/ \t /' | ${ROFI_CMD})" || exit 0

# If rofi returns the displayed text (base), try to resolve full path by matching base first
# Attempt to support both "base" and "base \t path" styles:
selected_path=""

# try exact match to "base \t path" style
selected_path="$(printf '%s\n' "${menu[@]}" | grep -F "$choice" | head -n1 | awk -F '|||' '{print $2}')"

# fallback: if choice is a basename, find the first file with that basename
if [ -z "$selected_path" ]; then
  for fp in "${files[@]}"; do
    if [ "$(basename "$fp")" = "$choice" ]; then
      selected_path="$fp"
      break
    fi
  done
fi

if [ -z "$selected_path" ]; then
  echo "No selection or couldn't resolve path." >&2
  exit 1
fi

# preview (optional): spawn sxiv detached for quick view, close after selection
if command -v sxiv >/dev/null 2>&1; then
  # kill any existing preview from earlier runs
  pkill -f "sxiv .*${selected_path##*/}" >/dev/null 2>&1 || true
  setsid sh -c "sxiv -q -t -1 \"$selected_path\" >/dev/null 2>&1" &
fi

# set wallpaper with feh
feh $FEH_OPTS "$selected_path"

# exit
exit 0

