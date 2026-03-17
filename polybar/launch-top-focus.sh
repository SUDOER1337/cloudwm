#!/usr/bin/env bash
# Polybar launch script for top-focus bar
# Kills existing polybar processes by PID then starts a single top bar.
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

# Start polybar (monitor-aware launch could be added later)
polybar --reload top >/dev/null 2>&1 &

exit 0
