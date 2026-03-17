#!/usr/bin/env bash
set -euo pipefail

SCRIPT_SOURCE=${BASH_SOURCE[0]:-$0}
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$SCRIPT_SOURCE")" && pwd)
# shellcheck source=common.sh
. "$SCRIPT_DIR/common.sh"

read_wpctl_state() {
    local output volume muted

    output=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null) || return 1
    volume=$(printf '%s\n' "$output" | awk '
        {
            for (i = 1; i <= NF; i++) {
                if ($i ~ /^[0-9]+(\.[0-9]+)?$/) {
                    printf "%d\n", ($i * 100) + 0.5
                    exit
                }
            }
        }
    ')
    [[ -n "$volume" ]] || return 1

    muted=0
    if [[ "$output" == *"[MUTED]"* ]]; then
        muted=1
    fi

    printf '%s %s\n' "$volume" "$muted"
}

read_pactl_state() {
    local volume muted

    volume=$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null |
        awk 'match($0, /([0-9]+)%/, m) { print m[1]; exit }') || return 1
    muted=$(pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null |
        awk '{print ($2 == "yes") ? 1 : 0}') || muted=0
    printf '%s %s\n' "$volume" "$muted"
}

read_audio_state() {
    if command -v wpctl >/dev/null 2>&1 && read_wpctl_state; then
        return 0
    fi

    if command -v pactl >/dev/null 2>&1 && read_pactl_state; then
        return 0
    fi

    printf '%s %s\n' "0" "0"
}

audio_icon() {
    local volume=$1
    local muted=$2

    if ((muted == 1)); then
        printf '%s' "󰝟"
    elif ((volume < 35)); then
        printf '%s' ""
    elif ((volume < 70)); then
        printf '%s' ""
    else
        printf '%s' ""
    fi
}

set_volume() {
    local value

    value=$(clamp_percent "${1:-0}")
    if command -v wpctl >/dev/null 2>&1; then
        wpctl set-volume @DEFAULT_AUDIO_SINK@ "${value}%" >/dev/null 2>&1 || true
    elif command -v pactl >/dev/null 2>&1; then
        pactl set-sink-volume @DEFAULT_SINK@ "${value}%" >/dev/null 2>&1 || true
    fi
}

toggle_mute() {
    if command -v wpctl >/dev/null 2>&1; then
        wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle >/dev/null 2>&1 || true
    elif command -v pactl >/dev/null 2>&1; then
        pactl set-sink-mute @DEFAULT_SINK@ toggle >/dev/null 2>&1 || true
    fi
}

open_mixer() {
    if command -v pavucontrol >/dev/null 2>&1; then
        pavucontrol >/dev/null 2>&1 &
        disown
    else
        notify "Audio" "pavucontrol is not installed."
    fi
}

case "${1:-label}" in
    label)
        read -r volume muted <<<"$(read_audio_state)"
        printf '%s %s%%\n' "$(audio_icon "$volume" "$muted")" "$volume"
        ;;
    value)
        read -r volume _ <<<"$(read_audio_state)"
        printf '%s\n' "$volume"
        ;;
    toggle)
        toggle_mute
        ;;
    set)
        set_volume "${2:-0}"
        ;;
    open)
        open_mixer
        ;;
    *)
        printf '%s\n' "Usage: audio.sh [label|value|toggle|set VALUE|open]" >&2
        exit 1
        ;;
esac
