#!/usr/bin/env bash
set -euo pipefail

SCRIPT_SOURCE=${BASH_SOURCE[0]:-$0}
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$SCRIPT_SOURCE")" && pwd)
# shellcheck source=common.sh
. "$SCRIPT_DIR/common.sh"

active_player() {
    local player

    player=$(playerctl metadata --format '{{playerName}}' 2>/dev/null | head -n 1 || true)
    if [[ -z "$player" ]]; then
        player=$(playerctl -l 2>/dev/null | head -n 1 || true)
    fi

    printf '%s' "$player"
}

media_text() {
    local player=$1
    local artist title

    artist=$(playerctl --player="$player" metadata --format '{{artist}}' 2>/dev/null || true)
    title=$(playerctl --player="$player" metadata --format '{{title}}' 2>/dev/null || true)

    if [[ -n "$artist" && -n "$title" ]]; then
        printf '%s - %s' "$artist" "$title"
    elif [[ -n "$title" ]]; then
        printf '%s' "$title"
    elif [[ -n "$artist" ]]; then
        printf '%s' "$artist"
    else
        printf '%s' "Unknown track"
    fi
}

print_label() {
    local player status track icon

    if ! command -v playerctl >/dev/null 2>&1; then
        printf '%s\n' "󰝛 playerctl missing"
        return 0
    fi

    player=$(active_player)
    if [[ -z "$player" ]]; then
        printf '%s\n' "󰎇 No media"
        return 0
    fi

    status=$(playerctl --player="$player" status 2>/dev/null || printf '%s' "Stopped")
    track=$(truncate_text "$(media_text "$player")" 42)

    case "$status" in
        Playing) icon="" ;;
        Paused) icon="" ;;
        *) icon="󰎇" ;;
    esac

    printf '%s %s\n' "$icon" "$track"
}

case "${1:-label}" in
    label)
        print_label
        ;;
    toggle)
        playerctl play-pause >/dev/null 2>&1 || true
        ;;
    next)
        playerctl next >/dev/null 2>&1 || true
        ;;
    previous)
        playerctl previous >/dev/null 2>&1 || true
        ;;
    menu)
        "$FJORDWM_ROOT/rofi/media/media.sh" >/dev/null 2>&1 &
        disown
        ;;
    *)
        printf '%s\n' "Usage: media.sh [label|toggle|next|previous|menu]" >&2
        exit 1
        ;;
esac
