#!/usr/bin/env bash
# toggle-layout.sh — clean EN/TH toggle + notification

LAYOUT1="us"
LAYOUT2="th"

# Use xkblayout-state if installed — much more accurate
if command -v xkblayout-state >/dev/null 2>&1; then
    current=$(xkblayout-state print "%s")
else
    current=$(setxkbmap -query | awk '/layout:/ {print $2}')
fi

# Decide next layout
if [ "$current" = "$LAYOUT1" ]; then
    NEXT="$LAYOUT2"
    LABEL="TH"
else
    NEXT="$LAYOUT1"
    LABEL="EN"
fi

# Switch layout
setxkbmap "$NEXT"

# Notify (with dunstify priority)
if command -v dunstify >/dev/null 2>&1; then
    dunstify -r 9999 -t 1200 "Switched to $LABEL"
else
    notify-send "Switched to $LABEL" -t 1200
fi
