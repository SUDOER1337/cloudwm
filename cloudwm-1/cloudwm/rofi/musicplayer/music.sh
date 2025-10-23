#!/bin/bash

# === Config ===
dir="$HOME/cloudwm/rofi/musicplayer/"
theme='menu'
START_DIR="$HOME/Music"
MPV_SOCKET="/tmp/mpvsocket"

# === Function: Browse directories and play music ===
browse_dir() {
    local current_dir="$1"
    while true; do
        # List directories and audio files (mp3/ogg/wav)
        local entries=$(ls -1A "$current_dir" | sort)
        entries="..\n$entries"

        # Show Rofi menu
        local choice=$(echo -e "$entries" | rofi -dmenu -i -p "Browse: $(basename "$current_dir")" -theme "${dir}/${theme}.rasi")
        [ -z "$choice" ] && return 1  # exit if user cancels

        local path="$current_dir/$choice"

        if [[ "$choice" == ".." ]]; then
            # Go up one directory
            current_dir=$(dirname "$current_dir")
        elif [[ -d "$path" ]]; then
            # Enter directory
            current_dir="$path"
        elif [[ -f "$path" && "$path" =~ \.(mp3|ogg|wav)$ ]]; then
            # Return selected audio file
            echo "$path"
            return 0
        fi
    done
}

# === Start browsing from ~/Music ===
selected_file=$(browse_dir "$START_DIR")
[ -z "$selected_file" ] && exit 0

# === Play or toggle ===
if pgrep -x "mpv" >/dev/null; then
    # Get current playing file
    current=$(pgrep -x -a mpv | awk '{$1=""; print substr($0,2)}')
    current_base=$(basename "$current")

    if [[ "$current_base" == "$(basename "$selected_file")" ]]; then
        # Toggle pause
        echo '{ "command": ["cycle", "pause"] }' | socat - "$MPV_SOCKET"
    else
        # Stop old and play new
        pkill mpv
        mpv --input-ipc-server="$MPV_SOCKET" "$selected_file" >/dev/null 2>&1 &
    fi
else
    # Start fresh mpv
    mpv --input-ipc-server="$MPV_SOCKET" "$selected_file" >/dev/null 2>&1 &
fi

