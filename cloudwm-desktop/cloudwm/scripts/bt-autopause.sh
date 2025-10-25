#!/bin/bash

# Replace with your Bluetooth headphone MAC address
BT_MAC="91:AE:2A:52:DA:94"

SINK_NAME="bluez_output.91_AE_2A_52_DA_94.1"  # Use actual sink name
TARGET_VOLUME="10%"

bluetoothctl --monitor | while read -r line; do
    if echo "$line" | grep -q "Device $BT_MAC connected"; then
        echo "Bluetooth device $BT_MAC connected. Setting volume."
        # Wait a few seconds to ensure the sink appears
        sleep 3
        pactl set-sink-volume "$SINK_NAME" "$TARGET_VOLUME"
    elif echo "$line" | grep -q "Device $BT_MAC disconnected"; then
        echo "Bluetooth device $BT_MAC disconnected. Pausing media."
        playerctl pause
    fi
done

