#!/bin/bash

dir="$HOME/cloudwm/rofi/controlcenter/"
theme='controlcenter'

rofi_cc() {
    printf "%b" "$1" | rofi -dmenu -p "$2" -theme "${dir}/${theme}.rasi"
}

options="Run Update\nBack"

choice=$(rofi_cc "$options" "Update")

case "$choice" in
    "Run Update")
        "$HOME/cloudwm/scripts/updatecheck.sh" --update
        ;;
    "Back")
        "$dir/main.sh"
        ;;
esac

