#!/bin/sh

DIR="$HOME/cloudwm/rofi/brightness"
THEME="brightness"

# Try ddcutil first (external monitor)
if command -v ddcutil >/dev/null 2>&1 && ddcutil detect | grep -q "Display"; then
    METHOD="ddcutil"
    current=$(ddcutil getvcp 10 2>/dev/null | grep -oP '\d+(?=%)' | head -n1)
# Fallback to brightnessctl (internal monitor)
elif command -v brightnessctl >/dev/null 2>&1; then
    METHOD="brightnessctl"
    current=$(brightnessctl g)
    max=$(brightnessctl m)
    if [ "$max" -gt 0 ]; then
        current=$(( current * 100 / max ))
    else
        current=50  # fallback default
    fi
else
    rofi -e "No supported brightness tool found (ddcutil or brightnessctl)"
    exit 1
fi

# Prompt for new brightness using Rofi
new=$(echo "$current" | rofi -dmenu -p "󰃠  Input Brightness (0–100)" -theme "${DIR}/${THEME}.rasi")

# Check input is valid number
if [ -n "$new" ] && echo "$new" | grep -qE '^[0-9]+$'; then
    [ "$new" -lt 0 ] && new=0
    [ "$new" -gt 100 ] && new=100

    if [ "$METHOD" = "ddcutil" ]; then
        ddcutil setvcp 10 "$new"
    elif [ "$METHOD" = "brightnessctl" ]; then
        max=$(brightnessctl m)
        value=$(( new * max / 100 ))
        brightnessctl s "$value"
    fi
fi

