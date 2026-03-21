#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROFI_SCRIPT_DIR="$SCRIPT_DIR"
# shellcheck source=../scripts/rofi-common.sh
. "$SCRIPT_DIR/../scripts/rofi-common.sh"

THEME_PATH=$(rofi_theme_path "powermenu")
LOCK_WRAPPER=$(fjordwm_script_path "lock-wrapper.sh")

uptime="[$(uptime -p | sed -e 's/up //g')]"
host=$(hostname)

shutdown='⏻ Shutdown'
reboot=' Reboot'
lock=' Lock'
suspend='󰒲 Suspend'
logout='󰗽 Logout'
yes=' Yes'
no='󰜺 No'

notify() {
    if command -v notify-send >/dev/null 2>&1; then
        notify-send "$1" "$2" >/dev/null 2>&1 || true
    fi
}

is_process_running() {
    pgrep -x "$1" >/dev/null 2>&1
}

pause_media() {
    if command -v playerctl >/dev/null 2>&1; then
        playerctl pause >/dev/null 2>&1 || true
    elif command -v mpc >/dev/null 2>&1; then
        mpc -q pause >/dev/null 2>&1 || true
    fi
}

mute_audio() {
    if command -v wpctl >/dev/null 2>&1; then
        wpctl set-mute @DEFAULT_AUDIO_SINK@ 1 >/dev/null 2>&1 || true
    elif command -v amixer >/dev/null 2>&1; then
        amixer set Master mute >/dev/null 2>&1 || true
    fi
}

rofi_cmd() {
    rofi -dmenu \
        -p "$host" \
        -mesg "Uptime : $uptime" \
        $(rofi_vim_keybindings_selection) \
        -theme "$THEME_PATH"
}

confirm_cmd() {
    rofi -theme-str 'window {location: center; anchor: center; fullscreen: false; width: 250px;}' \
        -theme-str 'mainbox {children: [ "message", "listview" ];}' \
        -theme-str 'listview {columns: 2; lines: 1;}' \
        -theme-str 'element-text {horizontal-align: 0.5;}' \
        -theme-str 'textbox {horizontal-align: 0.5;}' \
        -dmenu \
        -p 'Confirmation' \
        -mesg 'Are you Sure?' \
        $(rofi_vim_keybindings_selection) \
        -theme "$THEME_PATH"
}

confirm_exit() {
    printf '%b\n' "$yes\n$no" | confirm_cmd
}

run_rofi() {
    printf '%b\n' "$lock\n$suspend\n$logout\n$reboot\n$shutdown" | rofi_cmd
}

fjordwm_logout() {
    if is_process_running "fjordwm"; then
        pkill -x "fjordwm"
        notify "fjordwm" "Logged out successfully."
    elif is_process_running "dwm"; then
        pkill -x "dwm"
        notify "dwm" "Logged out successfully."
    else
        notify "fjordwm" "fjordwm/dwm is not running."
    fi
}

wayland_logout() {
    if command -v loginctl >/dev/null 2>&1 && [[ -n "${XDG_SESSION_ID:-}" ]]; then
        loginctl terminate-session "$XDG_SESSION_ID"
    elif is_process_running "fjordwl"; then
        pkill -x "fjordwl"
    elif is_process_running "dwl"; then
        pkill -x "dwl"
    else
        notify "fjordwl" "fjordwl/dwl is not running."
    fi
}

logout_current_session() {
    notify "Rofi Logout" "DESKTOP_SESSION=${DESKTOP_SESSION:-}  XDG_CURRENT_DESKTOP=${XDG_CURRENT_DESKTOP:-}"

    if [[ "${DESKTOP_SESSION:-}" == "openbox" ]]; then
        openbox --exit
    elif [[ "${DESKTOP_SESSION:-}" == "bspwm" ]]; then
        bspc quit
    elif [[ "${DESKTOP_SESSION:-}" == "i3" ]]; then
        i3-msg exit
    elif [[ "${DESKTOP_SESSION:-}" == "plasma" ]]; then
        qdbus org.kde.ksmserver /KSMServer logout 0 0 0
    elif [[ "${DESKTOP_SESSION:-}" == "awesome" || "${XDG_CURRENT_DESKTOP:-}" == "awesome" ]] || is_process_running "awesome"; then
        if command -v awesome-client >/dev/null 2>&1; then
            awesome-client 'awesome.quit()' >/dev/null 2>&1 || notify "AwesomeWM" "Logout failed."
        else
            notify "AwesomeWM" "awesome-client is not installed."
        fi
    elif [[ "${XDG_CURRENT_DESKTOP:-}" == "Hyprland" || "${DESKTOP_SESSION:-}" == "hyprland" ]]; then
        if command -v hyprctl >/dev/null 2>&1; then
            hyprctl dispatch exit >/dev/null 2>&1 || notify "Hyprland" "Logout failed."
        else
            notify "Hyprland" "hyprctl is not installed."
        fi
    elif [[ "${DESKTOP_SESSION:-}" == "fjordwl" || "${XDG_CURRENT_DESKTOP:-}" == "fjordwl" || "${XDG_SESSION_DESKTOP:-}" == "fjordwl" || "${DESKTOP_SESSION:-}" == "dwl" || "${XDG_CURRENT_DESKTOP:-}" == "dwl" || "${XDG_SESSION_DESKTOP:-}" == "dwl" ]] || is_process_running "fjordwl" || is_process_running "dwl"; then
        wayland_logout
    elif [[ "${DESKTOP_SESSION:-}" == "fjordwm" || "${XDG_CURRENT_DESKTOP:-}" == "fjordwm" || "${DESKTOP_SESSION:-}" == "dwm" || "${XDG_CURRENT_DESKTOP:-}" == "dwm" ]] || is_process_running "fjordwm" || is_process_running "dwm"; then
        fjordwm_logout
    else
        notify "Logout" "No known WM detected."
    fi
}

run_suspend() {
    pause_media
    mute_audio

    if fjordwm_is_wayland_session; then
        "$LOCK_WRAPPER" --daemonize >/dev/null 2>&1 || "$LOCK_WRAPPER" >/dev/null 2>&1 || true
    else
        "$LOCK_WRAPPER" >/dev/null 2>&1 || true
    fi

    systemctl suspend
}

run_cmd() {
    local selected

    selected=$(confirm_exit)
    if [[ "$selected" != "$yes" ]]; then
        return 0
    fi

    case "$1" in
        --shutdown)
            systemctl poweroff
            ;;
        --reboot)
            systemctl reboot
            ;;
        --suspend)
            run_suspend
            ;;
        --logout)
            logout_current_session
            ;;
    esac
}

chosen=$(run_rofi)
case "$chosen" in
    "$shutdown")
        run_cmd --shutdown
        ;;
    "$reboot")
        run_cmd --reboot
        ;;
    "$lock")
        "$LOCK_WRAPPER"
        ;;
    "$suspend")
        run_cmd --suspend
        ;;
    "$logout")
        run_cmd --logout
        ;;
esac
