#!/usr/bin/env bash
set -u

json_escape() {
    printf '%s' "$1" | sed \
        -e 's/\\/\\\\/g' \
        -e 's/"/\\"/g' \
        -e ':a;N;$!ba;s/\n/\\n/g'
}

active_player() {
    local player

    player=$(playerctl metadata --format '{{playerName}}' 2>/dev/null | head -n1)
    if [ -z "$player" ]; then
        player=$(playerctl -l 2>/dev/null | head -n1)
    fi

    printf '%s' "$player"
}

media_text() {
    local player=$1
    local artist title

    artist=$(playerctl --player="$player" metadata --format '{{artist}}' 2>/dev/null || true)
    title=$(playerctl --player="$player" metadata --format '{{title}}' 2>/dev/null || true)

    if [ -n "$artist" ] && [ -n "$title" ]; then
        printf '%s - %s' "$artist" "$title"
    elif [ -n "$title" ]; then
        printf '%s' "$title"
    elif [ -n "$artist" ]; then
        printf '%s' "$artist"
    else
        printf '%s' "Unknown track"
    fi
}

print_json() {
    local text=$1
    local class=$2
    local tooltip=$3

    printf '{"text":"%s","class":"%s","tooltip":"%s","alt":"%s"}\n' \
        "$(json_escape "$text")" \
        "$(json_escape "$class")" \
        "$(json_escape "$tooltip")" \
        "$(json_escape "$class")"
}

if ! command -v playerctl >/dev/null 2>&1; then
    print_json "󰝛 playerctl missing" "missing" "Install playerctl to show media status."
    exit 0
fi

player=$(active_player)

if [ -z "$player" ]; then
    print_json "󰎇 No media" "stopped" "No active MPRIS player"
    exit 0
fi

status=$(playerctl --player="$player" status 2>/dev/null || printf '%s' "Stopped")
track=$(media_text "$player")

case "$status" in
    Playing)
        icon=""
        class="playing"
        ;;
    Paused)
        icon=""
        class="paused"
        ;;
    *)
        icon="󰎇"
        class="stopped"
        ;;
esac

print_json \
    "$icon $track" \
    "$class" \
    "$(printf '%s\n%s' "$player" "$status")"
