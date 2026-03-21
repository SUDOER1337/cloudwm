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
switch_player='󰓦  Switch Player'
open_rmpc='  Open rmpc'
selected_player=''

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

message_label() {
    printf '<span alpha="80%%"><b>%s:</b></span>' "$1"
}

format_status() {
    status=$1

    case $status in
        Playing)
            printf '<span foreground="#98c379"> %s</span>' "$(escape_markup "$status")"
            ;;
        Paused)
            printf '<span foreground="#e5c07b"> %s</span>' "$(escape_markup "$status")"
            ;;
        Stopped)
            printf '<span foreground="#e06c75"> %s</span>' "$(escape_markup "$status")"
            ;;
        *)
            printf '<span foreground="#abb2bf">󰎇 %s</span>' "$(escape_markup "${status:-Unknown}")"
            ;;
    esac
}

format_track() {
    title=$1
    artist=$2

    printf '<b>%s</b>' "$(escape_markup "$title")"

    if [ -n "$artist" ]; then
        printf ' <span alpha="65%%">by %s</span>' "$(escape_markup "$artist")"
    fi
}


list_players() {
    if ! command -v playerctl >/dev/null 2>&1; then
        return 1
    fi

    playerctl --list-all 2>/dev/null
}

player_exists() {
    target_player=$1
    [ -n "$target_player" ] || return 1
    list_players | grep -Fx -- "$target_player" >/dev/null 2>&1
}

active_player() {
    if ! command -v playerctl >/dev/null 2>&1; then
        return 1
    fi

    if player_exists "$selected_player"; then
        printf '%s\n' "$selected_player"
        return 0
    fi

    playing_player=$(playerctl --all-players metadata --format '{{playerName}} {{status}}' 2>/dev/null | \
        awk '$2 == "Playing" { print $1; exit }')
    if [ -n "$playing_player" ]; then
        printf '%s\n' "$playing_player"
        return 0
    fi

    first_player=$(list_players | head -n1)
    if [ -n "$first_player" ]; then
        printf '%s\n' "$first_player"
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

    [ -n "$title" ] || title="Unknown Title"
    [ -n "$artist" ] || artist="Unknown Artist"

    player_line="$(message_label "Player") $(escape_markup "$player")"
    status_line="$(message_label "Status") $(format_status "$status")"
    track_line="$(message_label "Track") $(format_track "$title" "$artist")"

    printf '%s\n%s\n%s\n' \
        "$player_line" \
        "$status_line" \
        "$track_line"
}

run_rofi() {
    printf '%s\n' \
        "$play_pause" \
        "$next_track" \
        "$previous_track" \
        "$stop_playback" \
        "$switch_player" \
        "$open_rmpc" \
        | \
        rofi -dmenu \
            -i \
            -markup-rows \
            -p "  Media" \
            -mesg "$(build_media_message)" \
            $(rofi_vim_keybindings_selection) \
            -theme "$THEME_PATH"
}

choose_player() {
    current_player=$(active_player 2>/dev/null)
    players=$(list_players)

    if [ -z "$players" ]; then
        notify_media "No MPRIS players available."
        return 1
    fi

    choices=$(printf '%s\n' "$players" | while IFS= read -r player; do
        if [ "$player" = "$current_player" ]; then
            printf '● %s\n' "$player"
        else
            printf '○ %s\n' "$player"
        fi
    done)

    selection=$(printf '%s\n' "$choices" | \
        rofi -dmenu \
            -i \
            -p "󰓦  Player" \
            $(rofi_vim_keybindings_selection) \
            -theme "$THEME_PATH")

    [ -n "$selection" ] || return 1

    selected_player=${selection#? }
    if ! player_exists "$selected_player"; then
        notify_media "Selected player is no longer available."
        selected_player=''
        return 1
    fi
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
        "$switch_player")
            choose_player
            ;;
        "$open_rmpc")
            if launch_rmpc; then
                exit 0
            fi
            ;;
        *)
            exit 0
            ;;
    esac
done
