#!/bin/bash

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROFI_SCRIPT_DIR="$SCRIPT_DIR"
# shellcheck source=../scripts/rofi-common.sh
. "$SCRIPT_DIR/../scripts/rofi-common.sh"

THEME_PATH=$(rofi_theme_path "utility")
UPDATECHECK_SCRIPT=$(fjordwm_script_path "updatecheck.sh")

rofi_cc() {
    printf "%b" "$1" | rofi -dmenu -p "$2" $(rofi_vim_keybindings_text) -theme "$THEME_PATH"
}

options="Run Update\nBack"

choice=$(rofi_cc "$options" "Update")

case "$choice" in
    "Run Update")
        "$UPDATECHECK_SCRIPT" --update
        ;;
    "Back")
        "$SCRIPT_DIR/utility.sh"
        ;;
esac
