#!/bin/bash
# ────────────────────────────────
#  DWM AutoLock + DPMS Manager
#  Always active (ignores games)
# ────────────────────────────────

# --- CONFIG -----------------------------------------------------
LOCKER="slock"               # Screen locker
LOCK_DELAY=1                 # Minutes before lock
NOTIFY_BEFORE=30             # Seconds before locking
DPMS_TIMERS="600 900 1200"   # Screen standby/suspend/off times in seconds

# --- SAFETY RESET ----------------------------------------------
killall xautolock 2>/dev/null
xset s off                   # Disable legacy screensaver
xset +dpms
xset dpms $DPMS_TIMERS       # Configure DPMS

# --- START AUTOLOCK --------------------------------------------
echo "[autolock] Starting auto-lock system..."
xautolock -time "$LOCK_DELAY" \
          -locker "$LOCKER" \
          -notify "$NOTIFY_BEFORE" \
          -notifier "notify-send -u low 'Locking in $NOTIFY_BEFORE seconds...'" &

