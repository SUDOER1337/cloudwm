#!/bin/bash

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROFI_SCRIPT_DIR="$SCRIPT_DIR"
# shellcheck source=../scripts/rofi-common.sh
. "$SCRIPT_DIR/../scripts/rofi-common.sh"

notes_dir="$HOME/Documents/Notes/"
THEME_PATH=$(rofi_theme_path "note")

NOTES_FILE="${notes_dir}/notes.txt"
mkdir -p "$notes_dir"
touch "$NOTES_FILE"

rofi_cc() {
    rofi -dmenu -p "$2" $(rofi_vim_keybindings_text) -theme "$THEME_PATH"
}

CHOICE=$( (echo " Add New Note"; cat "$NOTES_FILE") | rofi_cc "Notes" )
[ -z "$CHOICE" ] && exit 0

if [[ "$CHOICE" == " Add New Note" ]]; then
    NEW_NOTE=$(rofi_cc "New note :")
    [ -n "$NEW_NOTE" ] && echo "$NEW_NOTE" >> "$NOTES_FILE"
elif grep -Fxq "$CHOICE" "$NOTES_FILE"; then
    ACTION=$(echo -e "󰏫 Edit\n󰖭 Delete" | rofi_cc "Action")
    case "$ACTION" in
        "󰏫 Edit")
            NEW_TEXT=$(rofi_cc "Edit :")
            [ -n "$NEW_TEXT" ] && sed -i "s|^$CHOICE\$|$NEW_TEXT|" "$NOTES_FILE"
            ;;
        "󰖭 Delete")
            sed -i "\|^$CHOICE\$|d" "$NOTES_FILE"
            ;;
    esac
fi
