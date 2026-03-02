#!/usr/bin/env bash
# ────────────────────────────────
# ~/cloudwm/scripts/auto-lock.sh
# CloudWM AutoLock + DPMS Manager
# ────────────────────────────────

# --- CONFIG -----------------------------------------------------
LOCKER="$HOME/cloudwm/scripts/lock-wrapper.sh"  # safe lock wrapper
LOCK_DELAY=1                 # Minutes before auto-lock
NOTIFY_BEFORE=30             # Seconds before locking
DPMS_TIMERS="600 900 1200"   # Screen standby/suspend/off (in seconds)

# --- SAFETY RESET ----------------------------------------------
killall xautolock 2>/dev/null
xset s off                   # disable legacy screensaver
xset +dpms
xset dpms $DPMS_TIMERS

# Make sure display environment is correct
export DISPLAY=${DISPLAY:-:0}
export XAUTHORITY=${XAUTHORITY:-$HOME/.Xauthority}

# --- START AUTOLOCK --------------------------------------------
echo "[autolock] Starting auto-lock system..."
xautolock -time "$LOCK_DELAY" \
          -locker "$LOCKER" \
          -notify "$NOTIFY_BEFORE" \
          -notifier "notify-send -u low 'Locking in $NOTIFY_BEFORE seconds...'" &

echo "[autolock] Auto-lock initialized (delay: $LOCK_DELAY min, notify: $NOTIFY_BEFORE sec)"

