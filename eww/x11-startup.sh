#!/bin/bash
# eww bar startup script for X11 (dwm)
# This script launches eww with X11-specific configuration

EWW_DIR="$HOME/fjordwm/eww"
CONFIG_DIR="$EWW_DIR"

# Kill existing eww processes
pkill -f "eww daemon" 2>/dev/null || true
sleep 0.5

# Start eww daemon
eww daemon --config "$CONFIG_DIR" &
sleep 1

# Open the bar window
eww --config "$CONFIG_DIR" open bar

echo "eww bar started for dwm (X11)"
