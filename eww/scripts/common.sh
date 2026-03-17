#!/usr/bin/env bash
set -euo pipefail

SCRIPT_SOURCE=${BASH_SOURCE[0]:-$0}
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$SCRIPT_SOURCE")" && pwd)
EWW_DIR=$(CDPATH= cd -- "$SCRIPT_DIR/.." && pwd)
FJORDWM_ROOT=$(CDPATH= cd -- "$EWW_DIR/.." && pwd)
STATE_ROOT="${XDG_RUNTIME_DIR:-/tmp}"
STATE_DIR="$STATE_ROOT/fjordwm-eww"
ROFI_SCRIPT_DIR="$FJORDWM_ROOT/rofi/runner"

# shellcheck source=../../rofi/scripts/rofi-common.sh
. "$FJORDWM_ROOT/rofi/scripts/rofi-common.sh"

if ! mkdir -p "$STATE_DIR" 2>/dev/null; then
    STATE_DIR="/tmp/fjordwm-eww-${UID}"
    mkdir -p "$STATE_DIR"
fi

eww_cmd() {
    command eww -c "$EWW_DIR" "$@"
}

notify() {
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "$1" "$2" >/dev/null 2>&1 || true
    fi
}

state_file() {
    printf '%s/%s\n' "$STATE_DIR" "$1"
}

write_state() {
    local name=$1
    local value=$2
    local file tmp

    file=$(state_file "$name")
    tmp="${file}.$$"
    printf '%s\n' "$value" > "$tmp"
    mv "$tmp" "$file"
}

read_state() {
    local name=$1
    local fallback=${2:-}
    local file

    file=$(state_file "$name")
    if [[ -f "$file" ]]; then
        cat "$file"
    else
        printf '%s' "$fallback"
    fi
}

sanitize_id() {
    printf '%s' "$1" | tr -c '[:alnum:]_.-' '-'
}

clamp_percent() {
    local value=${1%%.*}

    if [[ -z "$value" || ! "$value" =~ ^-?[0-9]+$ ]]; then
        value=0
    fi

    if ((value < 0)); then
        value=0
    elif ((value > 100)); then
        value=100
    fi

    printf '%s\n' "$value"
}

truncate_text() {
    local text=$1
    local max=${2:-48}

    if ((${#text} <= max)); then
        printf '%s' "$text"
    else
        printf '%s…' "${text:0:$((max - 1))}"
    fi
}
