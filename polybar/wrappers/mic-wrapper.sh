#!/usr/bin/env bash
# Show mic mute state and toggle on click. Uses wpctl if available.
BUTTON=${BUTTON:-}
if command -v wpctl >/dev/null 2>&1; then
    mute=$(wpctl get-mute @DEFAULT_AUDIO_SOURCE@ 2>/dev/null || echo "false")
    if [ "$BUTTON" = "1" ]; then
        wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle
        exit 0
    fi
    if [ "$mute" = "true" ]; then
        echo " muted"
    else
        echo " on"
    fi
else
    echo "mic?"
fi
