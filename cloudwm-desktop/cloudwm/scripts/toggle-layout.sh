#!/usr/bin/env bash
# toggle-layout.sh - toggle between English (us) and Thai (th)
# Updates xsetroot (dwm status) and sends a dunst notification.

# Config: change these if you use different variants or symbols
LAYOUT1="us"
LAYOUT2="th"
# Optional layout variants, e.g. "th" or "th(kanit)" — leave empty if none
VAR1=""
VAR2=""

# Choose notify command: dunstify preferred (works with dunst), fallback to notify-send
NOTIFYCMD="$(command -v dunstify || command -v notify-send || true)"

# Get current layout (from setxkbmap -query)
current=$(setxkbmap -query 2>/dev/null | awk '/layout:/ {print $2}')
# If setxkbmap returns something like "us,th", prefer using xkb-switch or xkblayout-state.
# We'll handle simple single-layout setups.
if [ -z "$current" ]; then
  # fallback: try xkblayout-state if installed
  if command -v xkblayout-state >/dev/null 2>&1; then
    current=$(xkblayout-state print "%s")
  fi
fi

# Decide next
if [ "$current" = "$LAYOUT1" ]; then
  NEXT="$LAYOUT2"
  VARNEXT="$VAR2"
  LABEL="TH"
  ICON=""   # path to icon if you want
else
  NEXT="$LAYOUT1"
  VARNEXT="$VAR1"
  LABEL="EN"
  ICON=""
fi

# Build setxkbmap command
if [ -n "$VARNEXT" ]; then
  setxkbmap "$NEXT" -variant "$VARNEXT"
else
  setxkbmap "$NEXT"
fi

# Update dwm status (xsetroot) so status bar immediately shows layout
# Many people show entire status via xsetroot -name "…"; here we only set an indicator
# If you use a status generator (dwmblocks/slstatus) you might prefer sending it a signal instead.
# xsetroot -name "Layout: $LABEL"

# Send dunst notification (using dunstify if available)
if [ -n "$NOTIFYCMD" ]; then
  if [ "$(basename "$NOTIFYCMD")" = "dunstify" ]; then
    # Use replace id 9999 so notifications don't stack; low urgency and short timeout
    dunstify -r 9999 -t 1500 "Keyboard layout" "$LABEL"
  else
    # notify-send fallback
    notify-send "Keyboard layout" "$LABEL" -t 1500
  fi
fi

exit 0

