#!/usr/bin/env bash
# Emits:  <count>
SCRIPT="$HOME/fjordwm/waybar/bin/updatecheck.sh"
BUTTON=${BUTTON:-}

case "$BUTTON" in
    1) $HOME/fjordwm/rofi/powermenu/powermenu.sh ;; # left click: open updater/menu (example)
    3) $HOME/fjordwm/waybar/bin/updatecheck.sh --open || true ;;
esac

if [ -x "$SCRIPT" ]; then
    out=$($SCRIPT 2>/dev/null | tr -d '\n')
    # Expect the script to output a number or empty
    if [ -z "$out" ]; then
        echo " 0"
    else
        echo " $out"
    fi
else
    echo " ?"
fi
