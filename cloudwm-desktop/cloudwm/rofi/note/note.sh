#!/bin/bash
notes_dir="$HOME/Documents/Notes/"
theme_dir="$HOME/cloudwm/rofi/note/"
theme='note'

NOTES_FILE="${notes_dir}/notes.txt"
mkdir -p "$notes_dir"
touch "$NOTES_FILE"

rofi_cc() {
    rofi -dmenu -p "$2" -theme "${theme_dir}/${theme}.rasi"
}

CHOICE=$( (echo " Add New Note"; cat "$NOTES_FILE") | rofi_cc "Notes" )
[ -z "$CHOICE" ] && exit 0

if [[ "$CHOICE" == " Add New Note" ]]; then
    NEW_NOTE=$(rofi_cc "New note:")
    [ -n "$NEW_NOTE" ] && echo "$NEW_NOTE" >> "$NOTES_FILE"
elif grep -Fxq "$CHOICE" "$NOTES_FILE"; then
    ACTION=$(echo -e "󰏫 Edit\n󰖭 Delete" | rofi_cc "Action")
    case "$ACTION" in
        "󰏫 Edit")
            NEW_TEXT=$(rofi_cc "Edit:")
            [ -n "$NEW_TEXT" ] && sed -i "s|^$CHOICE\$|$NEW_TEXT|" "$NOTES_FILE"
            ;;
        "󰖭 Delete")
            sed -i "\|^$CHOICE\$|d" "$NOTES_FILE"
            ;;
    esac
fi

