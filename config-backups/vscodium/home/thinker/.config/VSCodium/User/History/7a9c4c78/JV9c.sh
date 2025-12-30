#!/bin/bash
# ────────────────────────────────
#  DWM AutoLock + DPMS Manager
# ────────────────────────────────

# --- CONFIG -----------------------------------------------------
LOCKER="slock"
LOCK_DELAY=1
NOTIFY_BEFORE=30
DPMS_TIMERS="600 900 1200"

# Wrapper script executed before slock
LOCKER_WRAPPER="/tmp/lock_wrapper.sh"

# --- CREATE LOCK WRAPPER ---------------------------------------
cat << 'EOF' > "$LOCKER_WRAPPER"
#!/bin/bash

# Save current layout
PREV_LAYOUT=$(setxkbmap -query | awk '/layout/{print $2}')

# Force English before slock
setxkbmap us
sleep 0.2   # IMPORTANT: prevent slock softlock on TH layout

# Run slock
slock

# Restore previous layout after unlocking
[ -n "$PREV_LAYOUT" ] && setxkbmap "$PREV_LAYOUT"
EOF

chmod +x "$LOCKER_WRAPPER"

# --- SAFETY RESET ----------------------------------------------
killall xautolock 2>/dev/null
setxkbmap us
xset s off
xset +dpms
xset dpms $DPMS_TIMERS

# --- START AUTOLOCK --------------------------------------------
echo "[autolock] Starting auto-lock system..."
xautolock -time "$LOCK_DELAY" \
          -locker "$LOCKER_WRAPPER" \
          -notify "$NOTIFY_BEFORE" \
          -notifier "notify-send -u low 'Locking in $NOTIFY_BEFORE seconds...'" &
