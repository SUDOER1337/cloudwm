#!/usr/bin/env bash
set -euo pipefail

SCRIPT_SOURCE=${BASH_SOURCE[0]:-$0}
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$SCRIPT_SOURCE")" && pwd)
# shellcheck source=common.sh
. "$SCRIPT_DIR/common.sh"

print_label() {
    local status_output wifi ethernet

    if ! command -v nmcli >/dev/null 2>&1; then
        printf '%s\n' "󰖪 offline"
        return 0
    fi

    status_output=$(nmcli -t -f DEVICE,TYPE,STATE,CONNECTION device status 2>/dev/null || true)
    if [[ -z "$status_output" ]]; then
        printf '%s\n' "󰖪 offline"
        return 0
    fi

    wifi=$(printf '%s\n' "$status_output" |
        awk -F: '$1 == "wifi" && $2 == "connected" {print $3; exit}')
    if [[ -n "$wifi" ]]; then
        printf '󰖩 %s\n' "$(truncate_text "$wifi" 18)"
        return 0
    fi

    ethernet=$(printf '%s\n' "$status_output" |
        awk -F: '$2 == "ethernet" && $3 == "connected" {print $1; exit}')
    if [[ -n "$ethernet" ]]; then
        printf '󰈀 %s\n' "$ethernet"
        return 0
    fi

    printf '%s\n' "󰖪 offline"
}

case "${1:-label}" in
    label)
        print_label
        ;;
    open)
        if command -v nm-connection-editor >/dev/null 2>&1; then
            nm-connection-editor >/dev/null 2>&1 &
            disown
        else
            notify "Network" "nm-connection-editor is not installed."
        fi
        ;;
    *)
        printf '%s\n' "Usage: network.sh [label|open]" >&2
        exit 1
        ;;
esac
