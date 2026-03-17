#!/usr/bin/env bash

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROFI_SCRIPT_DIR="$SCRIPT_DIR"
# shellcheck source=../scripts/rofi-common.sh
. "$SCRIPT_DIR/../scripts/rofi-common.sh"

THEME_PATH=$(rofi_theme_path "media")

play_pause='  Play/Pause'
next_track='  Next'
previous_track='  Previous'
stop_playback='  Stop'
open_rmpc='  Open rmpc'
refresh_info='  Refresh Info'

notify_media() {
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "Rofi Media" "$1"
    fi
}

escape_markup() {
    printf '%s' "$1" | sed \
        -e 's/&/\&amp;/g' \
        -e 's/</\&lt;/g' \
        -e 's/>/\&gt;/g'
}

format_duration() {
    value=$1

    case $value in
        ''|*[!0-9.]*)
            return 1
            ;;
    esac

    seconds=${value%.*}

    if [ -z "$seconds" ]; then
        return 1
    fi

    if [ "$seconds" -ge 3600 ]; then
        printf '%d:%02d:%02d\n' \
            "$((seconds / 3600))" \
            "$(((seconds % 3600) / 60))" \
            "$((seconds % 60))"
    else
        printf '%02d:%02d\n' \
            "$((seconds / 60))" \
            "$((seconds % 60))"
    fi
}

active_player() {
    if ! command -v playerctl >/dev/null 2>&1; then
        return 1
    fi

    player=$(playerctl metadata --format '{{playerName}}' 2>/dev/null | head -n1)

    if [ -z "$player" ]; then
        player=$(playerctl -l 2>/dev/null | head -n1)
    fi

    if [ -n "$player" ]; then
        printf '%s\n' "$player"
        return 0
    fi

    return 1
}

player_status() {
    player=$1
    playerctl --player="$player" status 2>/dev/null
}

player_metadata() {
    player=$1
    key=$2
    playerctl --player="$player" metadata --format "$key" 2>/dev/null
}

build_media_message() {
    if ! command -v playerctl >/dev/null 2>&1; then
        printf '%s\n' '<b>playerctl not found</b>
Install <i>playerctl</i> to control MPRIS players.
<i>Open rmpc</i> is still available below.'
        return
    fi

    if ! player=$(active_player); then
        printf '%s\n' '<b>No active MPRIS player</b>
Start playback in a compatible app or pick <i>Open rmpc</i>.
Use <i>Refresh Info</i> after a player appears.'
        return
    fi

    status=$(player_status "$player")
    artist=$(player_metadata "$player" '{{artist}}')
    title=$(player_metadata "$player" '{{title}}')
    album=$(player_metadata "$player" '{{album}}')
    position_raw=$(playerctl --player="$player" position 2>/dev/null)
    length_us=$(playerctl --player="$player" metadata mpris:length 2>/dev/null)

    [ -n "$artist" ] || artist="Unknown Artist"
    [ -n "$title" ] || title="Unknown Title"

    player_line="<b>Player 󰇛</b> $(escape_markup "$player")"
    status_line="<b>Status 󰇛</b> $(escape_markup "${status:-Unknown}")"
    track_line="<b>Track 󰇛</b> $(escape_markup "$artist") - $(escape_markup "$title")"

    if [ -n "$album" ]; then
        album_line="<b>Album 󰇛</b> $(escape_markup "$album")"
    else
        album_line="<b>Album 󰇛</b> <i>Unavailable</i>"
    fi

    if position_fmt=$(format_duration "${position_raw:-}"); then
        if [ -n "$length_us" ] && length_fmt=$(format_duration "$((length_us / 1000000))"); then
            time_line="<b>Time 󰇛</b> $position_fmt / $length_fmt"
        else
            time_line="<b>Time 󰇛</b> $position_fmt"
        fi
    else
        time_line="<b>Time 󰇛</b> <i>Unavailable</i>"
    fi

    printf '%s\n%s\n%s\n%s\n%s\n' \
        "$player_line" \
        "$status_line" \
        "$track_line" \
        "$album_line" \
        "$time_line"
}

run_rofi() {
    printf '%s\n' \
        "$play_pause" \
        "$next_track" \
        "$previous_track" \
        "$stop_playback" \
        "$open_rmpc" \
        "$refresh_info" | \
        rofi -dmenu \
            -i \
            -markup-rows \
            -p "  Media" \
            -mesg "$(build_media_message)" \
            $(rofi_vim_keybindings) \
            -theme "$THEME_PATH"
}

run_player_action() {
    action=$1

    if ! command -v playerctl >/dev/null 2>&1; then
        notify_media "playerctl is not installed."
        return
    fi

    if ! player=$(active_player); then
        notify_media "No active MPRIS player found."
        return
    fi

    if ! playerctl --player="$player" "$action" >/dev/null 2>&1; then
        notify_media "Failed to run '$action' for $player."
    fi
}

launch_rmpc() {
    if ! command -v kitty >/dev/null 2>&1; then
        notify_media "kitty is not installed."
        return 1
    fi

    if ! command -v rmpc >/dev/null 2>&1; then
        notify_media "rmpc is not installed."
        return 1
    fi

    kitty \
        --class "rmpc-float" \
        --title "rmpc" \
        -o "initial_window_width=1248" \
        -o "initial_window_height=683" \
        -e rmpc >/dev/null 2>&1 &
}

while :; do
    choice=$(run_rofi)

    case $choice in
        "$play_pause")
            run_player_action "play-pause"
            ;;
        "$next_track")
            run_player_action "next"
            ;;
        "$previous_track")
            run_player_action "previous"
            ;;
        "$stop_playback")
            run_player_action "stop"
            ;;
        "$open_rmpc")
            if launch_rmpc; then
                exit 0
            fi
            ;;
        "$refresh_info")
            ;;
        *)
            exit 0
            ;;
    esac
done
