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

marquee_text() {
    local text=$1
    local width=${2:-70}
    local gap="   •   "
    local len now_ms step loop_src loop_len doubled segment

    len=${#text}
    if [ "$len" -le "$width" ]; then
        printf '%s' "$text"
        return 0
    fi

    loop_src="${text}${gap}"
    loop_len=${#loop_src}

    if now_ms=$(date +%s%3N 2>/dev/null); then
        :
    else
        now_ms=$(( $(date +%s) * 1000 ))
    fi

    # One character step every 200ms gives smooth but readable movement.
    step=$(( (now_ms / 200) % loop_len ))
    doubled="${loop_src}${loop_src}"
    segment="${doubled:$step:$width}"

    printf '%s' "$segment"
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
display_track=$(marquee_text "$track" 70)

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
    "$icon $display_track" \
    "$class" \
    "$(printf '%s\n%s\n%s' "$player" "$status" "$track")"
