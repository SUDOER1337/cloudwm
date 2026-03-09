#!/bin/sh
DIR="$HOME/cloudwm/rofi/brightness"
THEME="brightness"

# Detect current brightness
current=$(ddcutil getvcp 10 | grep -oP '\d+(?=%)')

# Show Rofi input with current brightness pre-filled
new=$(echo "$current" | rofi -dmenu -p "󰃠  Input Brightness" -theme "${DIR}/${THEME}.rasi")

# Apply if valid
if [ -n "$new" ] && [[ "$new" =~ ^[0-9]+$ ]]; then
    # Clamp 0–100
    [ "$new" -lt 0 ] && new=0
    [ "$new" -gt 100 ] && new=100

    ddcutil setvcp 10 "$new"
fi

