#!/bin/bash
# ────────────────────────────────────────────────
# Bluetooth Auto Connect + Sink Volume Manager
# Works even after switching between phone and PC
# ────────────────────────────────────────────────

BT_MAC="91:AE:2A:52:DA:94"
TARGET_VOLUME="10%"
LOG_FILE="$HOME/.local/share/bt-autopause.log"
RETRY_DELAY=10

mkdir -p "$(dirname "$LOG_FILE")"

log() {
    echo "[$(date '+%H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

set_sink_volume() {
    for i in {1..5}; do
        SINK_NAME=$(pactl list short sinks | grep -F "$BT_MAC" | awk '{print $2}')
        if [ -n "$SINK_NAME" ]; then
            log "  Setting sink '$SINK_NAME' volume to $TARGET_VOLUME"
            pactl set-sink-volume "$SINK_NAME" "$TARGET_VOLUME"
            return
        fi
        log " Sink not found (attempt $i)..."
        sleep 2
    done
    log "⚠️  Failed to find sink for $BT_MAC after retries."
}

connect_bt_device() {
    log "🔌 Attempting to connect to $BT_MAC..."
    bluetoothctl connect "$BT_MAC" >/dev/null 2>&1
    sleep 3
    if bluetoothctl info "$BT_MAC" | grep -q "Connected: yes"; then
        log "✅ Connected to device $BT_MAC"
        set_sink_volume
    else
        log "❌ Failed to connect. Scanning + pairing..."
        bluetoothctl scan on >/dev/null 2>&1 &
        sleep 6
        bluetoothctl pair "$BT_MAC" >/dev/null 2>&1
        bluetoothctl trust "$BT_MAC" >/dev/null 2>&1
        bluetoothctl connect "$BT_MAC" >/dev/null 2>&1
        bluetoothctl scan off >/dev/null 2>&1

        if bluetoothctl info "$BT_MAC" | grep -q "Connected: yes"; then
            log "✅ Connected after scan!"
            set_sink_volume
        else
            log "❌ Still couldn’t connect. Retrying in $RETRY_DELAY sec..."
            sleep $RETRY_DELAY
            connect_bt_device
        fi
    fi
}

monitor_bluetooth() {
    while true; do
        bluetoothctl --monitor | while read -r line; do
            case "$line" in
                *"Device $BT_MAC connected"*)
                    log "🎧 $BT_MAC connected"
                    set_sink_volume
                    ;;
                *"Device $BT_MAC disconnected"*)
                    log "💤 $BT_MAC disconnected — pausing media"
                    playerctl pause
                    sleep 3
                    connect_bt_device
                    ;;
            esac
        done
        log "⚠️  Monitor stream ended, restarting..."
        sleep 2
    done
}

# ────────────────────────────────────────────────
# STARTUP LOGIC
# ────────────────────────────────────────────────
log "───────────────────────────────"
log "Bluetooth auto-manager started."
log "Target device: $BT_MAC"
log "───────────────────────────────"

bluetoothctl power on >/dev/null 2>&1
bluetoothctl agent on >/dev/null 2>&1
bluetoothctl default-agent >/dev/null 2>&1

connect_bt_device
monitor_bluetooth

