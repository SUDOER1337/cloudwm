#!/usr/bin/env bash

PREV_LAYOUT=$(setxkbmap -query | awk '/layout:/ {print $2}')

setxkbmap us
setxkbmap -query > /dev/null   # force XKB to apply
sleep 0.1

slock

[ -n "$PREV_LAYOUT" ] && setxkbmap "$PREV_LAYOUT"

