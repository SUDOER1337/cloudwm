#!/usr/bin/env bash
# Simple adapter: call existing waybar media status script and print polybar-friendly text
SCRIPT="$HOME/fjordwm/waybar/fjordwl-media-status.sh"
BUTTON=${BUTTON:-}

case "$BUTTON" in
    1) playerctl play-pause ;;
    3) playerctl next ;;
    2) playerctl previous ;;
esac

if [ -x "$SCRIPT" ]; then
    "$SCRIPT" | head -n1
else
    # Fallback: query playerctl
    status=$(playerctl status 2>/dev/null || echo "Stopped")
    if [ "$status" = "Playing" ]; then
        artist=$(playerctl metadata xesam:artist 2>/dev/null)
        title=$(playerctl metadata xesam:title 2>/dev/null)
        echo " ${artist:-} - ${title:-}"
    elif [ "$status" = "Paused" ]; then
        echo " Paused"
    else
        echo " Stopped"
    fi
fi
