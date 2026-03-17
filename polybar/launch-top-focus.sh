#!/usr/bin/env bash
# Polybar launch script for top-focus bar (monitor-aware)
set -euo pipefail

# export wrappers path
export PATH="$HOME/polybar/bin:$PATH"

# Kill existing polybar instances (by PID) if any
pids=$(pgrep -x polybar || true)
if [ -n "$pids" ]; then
    echo "Stopping existing polybar instances: $pids"
    kill $pids || true
    sleep 0.2
fi

# Require polybar in PATH
if ! command -v polybar >/dev/null 2>&1; then
    echo "polybar not found in PATH" >&2
    exit 1
fi

# If MONITOR is provided, only launch on that monitor; otherwise launch on all detected monitors
LOGFILE="$HOME/.cache/polybar-top-focus.log"
mkdir -p "$(dirname "$LOGFILE")"

if [ -n "${MONITOR-}" ]; then
    echo "Starting polybar on monitor: $MONITOR" | tee -a "$LOGFILE"
    MONITOR="$MONITOR" polybar --config="$HOME/fjordwm/polybar/config-top-focus.ini" --reload top 2>&1 | tee -a "$LOGFILE" &
else
    monitors=$(polybar --list-monitors 2>/dev/null || true)
    if [ -n "$monitors" ]; then
        # polybar --list-monitors prints lines like: HDMI-A-1: 1920x1080+0+0
        while IFS= read -r line; do
            name=${line%%:*}
            name=${name%% *}
            name=$(echo "$name" | tr -d '[:space:]')
            echo "Starting polybar on monitor: $name" | tee -a "$LOGFILE"
            MONITOR="$name" polybar --config "$HOME/fjordwm/polybar/config-top-focus.ini" --reload top 2>&1 | tee -a "$LOGFILE" &
        done <<< "$monitors"
    else
        # Fallback: start single instance
        echo "No monitors detected; starting single polybar instance" | tee -a "$LOGFILE"
        polybar --config "$HOME/fjordwm/polybar/config-top-focus.ini" --reload top 2>&1 | tee -a "$LOGFILE" &
    fi
fi

exit 0
