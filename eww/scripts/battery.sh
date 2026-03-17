#!/usr/bin/env bash
set -euo pipefail

SCRIPT_SOURCE=${BASH_SOURCE[0]:-$0}
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$SCRIPT_SOURCE")" && pwd)
# shellcheck source=common.sh
. "$SCRIPT_DIR/common.sh"

device=""
if command -v upower >/dev/null 2>&1; then
    device=$(upower -e 2>/dev/null | grep -m 1 battery || true)
fi

if [[ -z "$device" ]]; then
    printf '%s\n' "󰚥 AC"
    exit 0
fi

info=$(upower -i "$device" 2>/dev/null || true)
percentage=$(printf '%s\n' "$info" | awk -F: '/percentage:/ {gsub(/^[ \t]+/, "", $2); gsub(/%/, "", $2); print $2; exit}')
state=$(printf '%s\n' "$info" | awk -F: '/state:/ {gsub(/^[ \t]+/, "", $2); print $2; exit}')

percentage=${percentage:-0}
percentage=$(clamp_percent "$percentage")

if [[ "$state" == "charging" ]]; then
    icon="󰂄"
elif ((percentage < 15)); then
    icon="󰁺"
elif ((percentage < 35)); then
    icon="󰁼"
elif ((percentage < 60)); then
    icon="󰁾"
elif ((percentage < 85)); then
    icon="󰂀"
else
    icon="󰁹"
fi

printf '%s %s%%\n' "$icon" "$percentage"
