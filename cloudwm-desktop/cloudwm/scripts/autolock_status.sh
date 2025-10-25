#!/bin/bash
# ────────────────────────────────
#  Report autolock/DPMS status for slstatus
# ────────────────────────────────

# Check if xautolock is running
if pgrep -x xautolock >/dev/null; then
    # Get idle time in milliseconds
    IDLE=$(xprintidle)
    
    # Threshold for "idle" (e.g., 60 seconds)
    THRESHOLD=$((60 * 1000))
    
    if [ "$IDLE" -ge "$THRESHOLD" ]; then
        echo "󰒲 IDLE"
    else
        echo " WAKE"
    fi
else
    # xautolock not running → consider system active
    echo " WAKE"
fi

