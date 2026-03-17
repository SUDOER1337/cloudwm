#!/usr/bin/env bash
set -euo pipefail

ACTION="${1:-area}"
PICTURES_DIR="${XDG_PICTURES_DIR:-$HOME/Pictures}"
OUTPUT_DIR="${XDG_SCREENSHOTS_DIR:-$PICTURES_DIR/Screenshots}"
OUTPUT_FILE="$OUTPUT_DIR/$(date +%Y-%m-%d_%H-%M-%S).png"

notify_capture() {
    local message=$1

    if command -v notify-send >/dev/null 2>&1; then
        notify-send "Screenshot" "$message" >/dev/null 2>&1 || true
    fi
}

require_command() {
    local command_name=$1

    if ! command -v "$command_name" >/dev/null 2>&1; then
        printf 'Missing required command: %s\n' "$command_name" >&2
        exit 1
    fi
}

copy_capture() {
    if command -v wl-copy >/dev/null 2>&1; then
        wl-copy < "$OUTPUT_FILE"
    fi
}

edit_capture() {
    if command -v swappy >/dev/null 2>&1; then
        swappy -f "$OUTPUT_FILE" -o "$OUTPUT_FILE" >/dev/null 2>&1 || true
    fi
}

mkdir -p "$OUTPUT_DIR"
require_command grim

case "$ACTION" in
    full)
        grim "$OUTPUT_FILE"
        ;;
    area)
        require_command slurp
        GEOMETRY="$(slurp)" || exit 0
        grim -g "$GEOMETRY" "$OUTPUT_FILE"
        edit_capture
        ;;
    *)
        printf '%s\n' "Usage: wayland-screenshot.sh [full|area]" >&2
        exit 1
        ;;
esac

copy_capture
notify_capture "Saved $(basename "$OUTPUT_FILE")"
printf '%s\n' "$OUTPUT_FILE"
