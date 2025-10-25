#!/bin/bash
# ────────────────────────────────────────────────
# Bluetooth Auto Connect + Sink Volume Manager
# Works even after switching between phone and PC
# ────────────────────────────────────────────────

BT_MAC="91:AE:2A:52:DA:94"
TARGET_VOLUME="10%"
LOG_FILE="$HOME/.local/share/bt-autopause.log"

mkdir -p "$(dirname "$LOG_FILE")"

log() {
    echo "[$(date '+%H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

set_sink_volume() {
    sleep 2
    SINK_NAME=$(pactl list short sinks | grep "$BT_MAC" | awk '{print $2}')
    if [ -n "$SINK_NAME" ]; then
        log "Setting sink '$SINK_NAME' volume to $TARGET_VOLUME"
        pactl set-sink-volume "$SINK_NAME" "$TARGET_VOLUME"
    else
        log "Sink not found yet, retrying..."
        sleep 3
        SINK_NAME=$(pactl list short sinks | grep "$BT_MAC" | awk '{print $2}')
        [ -n "$SINK_NAME" ] && pactl set-sink-volume "$SINK_NAME" "$TARGET_VOLUME"
    fi
}

connect_bt_device() {
    log "Attempting to connect to $BT_MAC..."
    bluetoothctl connect "$BT_MAC" >/dev/null 2>&1
    sleep 3
    if bluetoothctl info "$BT_MAC" | grep -q "Connected: yes"; then
        log "✅ Connected to device $BT_MAC"
        set_sink_volume
    else
        log "❌ Failed to connect to $BT_MAC. Trying to scan and pair..."
        bluetoothctl scan on >/dev/null 2>&1 &
        sleep 6
        bluetoothctl pair "$BT_MAC" >/dev/null 2>&1
        bluetoothctl trust "$BT_MAC" >/dev/null 2>&1
        bluetoothctl connect "$BT_MAC" >/dev/null 2>&1
        bluetoothctl scan off >/dev/null 2>&1
        if bluetoothctl info "$BT_MAC" | grep -q "Connected: yes"; then
            log "✅ Connected after scanning!"
            set_sink_volume
        else
            log "❌ Still couldn't connect to $BT_MAC."
        fi
    fi
}

monitor_bluetooth() {
    bluetoothctl --monitor | while read -r line; do
        if echo "$line" | grep -q "Device $BT_MAC connected"; then
            log "🎧 $BT_MAC connected"
            set_sink_volume
        elif echo "$line" | grep -q "Device $BT_MAC disconnected"; then
            log "💤 $BT_MAC disconnected — pausing media"
            playerctl pause
            sleep 5
            connect_bt_device
        fi
    done
}

# ────────────────────────────────────────────────
# STARTUP LOGIC
# ────────────────────────────────────────────────
log "───────────────────────────────"
log "Bluetooth auto-manager started."
log "Target device: $BT_MAC"
log "───────────────────────────────"

# Ensure Bluetooth is powered and agent is active
bluetoothctl power on >/dev/null 2>&1
bluetoothctl agent on >/dev/null 2>&1
bluetoothctl default-agent >/dev/null 2>&1

# Initial connect attempt
connect_bt_device

# Start monitoring for connection changes
monitor_bluetooth

