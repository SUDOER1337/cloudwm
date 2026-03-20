#!/bin/bash

# === Config ===
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROFI_SCRIPT_DIR="$SCRIPT_DIR"
# shellcheck source=../scripts/rofi-common.sh
. "$SCRIPT_DIR/../scripts/rofi-common.sh"

THEME_PATH=$(rofi_theme_path "menu")
state_file="/tmp/stretchly_pause_state"

# === Determine toggle label with nerd font ===
if [[ -f "$state_file" && $(cat "$state_file") == "paused" ]]; then
    toggle_label=" Currently OFF (Breaks Paused)"    # lock icon
else
    toggle_label=" Currently ON (Breaks Running)"  # unlocked icon
fi

# === Friendly menu options with icons ===
options="$toggle_label\n Take a Mini Break\n Take a Long Break\n Preferences\n Reset Breaks"

# === Show Rofi menu ===
choice=$(echo -e "$options" | rofi -dmenu -p "Stretchly" $(rofi_vim_keybindings_selection) -theme "$THEME_PATH")

# === Handle selection ===
case "$choice" in
    " Currently OFF (Breaks Paused)"|" Currently ON (Breaks Running)")
        stretchly toggle
        # flip the state
        if [[ -f "$state_file" && $(cat "$state_file") == "paused" ]]; then
            echo "running" > "$state_file"
        else
            echo "paused" > "$state_file"
        fi
        ;;
    " Take a Mini Break")
        stretchly mini -T "Stretch!"  # friendly title
        ;;
    " Take a Long Break")
        stretchly long -T "Time to stretch!" -t "Get up and move!"
        ;;
    " Preferences")
        stretchly preferences
        ;;
    " Reset Breaks")
        stretchly reset
        ;;
    *)
        exit 0
        ;;
esac
