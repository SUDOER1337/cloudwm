#!/usr/bin/env bash
set -euo pipefail

SCRIPT_SOURCE=${BASH_SOURCE[0]:-$0}
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$SCRIPT_SOURCE")" && pwd)
# shellcheck source=common.sh
. "$SCRIPT_DIR/common.sh"

read_brightnessctl() {
    local current max

    current=$(brightnessctl g 2>/dev/null) || return 1
    max=$(brightnessctl m 2>/dev/null) || return 1
    [[ "$current" =~ ^[0-9]+$ && "$max" =~ ^[0-9]+$ ]] || return 1
    ((max > 0)) || return 1
    printf '%s\n' $(( current * 100 / max ))
}

read_ddcutil() {
    local output current max

    output=$(ddcutil getvcp 10 2>/dev/null) || return 1
    current=$(printf '%s\n' "$output" | sed -n 's/.*current value = *\([0-9][0-9]*\).*/\1/p' | head -n 1)
    max=$(printf '%s\n' "$output" | sed -n 's/.*max value = *\([0-9][0-9]*\).*/\1/p' | head -n 1)

    [[ "$current" =~ ^[0-9]+$ ]] || return 1
    if [[ "$max" =~ ^[0-9]+$ && "$max" -gt 0 && "$max" -ne 100 ]]; then
        current=$(( current * 100 / max ))
    fi

    clamp_percent "$current"
}

read_brightness() {
    if command -v brightnessctl >/dev/null 2>&1 && read_brightnessctl; then
        return 0
    fi

    if command -v ddcutil >/dev/null 2>&1 && read_ddcutil; then
        return 0
    fi

    printf '%s\n' "50"
}

brightness_icon() {
    local value=$1

    if ((value <= 0)); then
        printf '%s' "󰃞"
    elif ((value < 35)); then
        printf '%s' "󰃟"
    elif ((value < 75)); then
        printf '%s' "󰃠"
    else
        printf '%s' "󰃡"
    fi
}

set_brightness() {
    local value

    value=$(clamp_percent "${1:-0}")
    if command -v brightnessctl >/dev/null 2>&1 && brightnessctl set "${value}%" >/dev/null 2>&1; then
        return 0
    fi

    if command -v ddcutil >/dev/null 2>&1; then
        ddcutil setvcp 10 "$value" >/dev/null 2>&1 || true
    fi
}

case "${1:-label}" in
    label)
        value=$(read_brightness)
        printf '%s %s%%\n' "$(brightness_icon "$value")" "$value"
        ;;
    value)
        read_brightness
        ;;
    set)
        set_brightness "${2:-0}"
        ;;
    *)
        printf '%s\n' "Usage: brightness.sh [label|value|set VALUE]" >&2
        exit 1
        ;;
esac
