#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROFI_SCRIPT_DIR="$SCRIPT_DIR"
# shellcheck source=../scripts/rofi-common.sh
. "$SCRIPT_DIR/../scripts/rofi-common.sh"

THEME_PATH=$(rofi_theme_path "powermenu")
LOCK_WRAPPER=$(fjordwm_script_path "lock-wrapper.sh")
POWERMENU_CONFIG="$SCRIPT_DIR/powermenu.conf"

if [[ -f "$POWERMENU_CONFIG" ]]; then
    # Optional backend-specific logout overrides. See powermenu.conf.example.
    # shellcheck source=/dev/null
    . "$POWERMENU_CONFIG"
fi

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

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

is_process_running() {
    pgrep -x "$1" >/dev/null 2>&1
}

run_quiet() {
    "$@" >/dev/null 2>&1
}

run_shell_quiet() {
    sh -c "$1" >/dev/null 2>&1
}

desktop_value_matches() {
    local value=${1,,}
    local name=${2,,}

    [[ -n "$value" ]] || return 1
    [[ "$value" == "$name" ]] && return 0

    case ":$value:" in
        *":$name:"*)
            return 0
            ;;
    esac

    return 1
}

session_matches() {
    local name=$1

    desktop_value_matches "${DESKTOP_SESSION:-}" "$name" ||
        desktop_value_matches "${XDG_CURRENT_DESKTOP:-}" "$name" ||
        desktop_value_matches "${XDG_SESSION_DESKTOP:-}" "$name"
}

terminate_current_session() {
    if command_exists loginctl && [[ -n "${XDG_SESSION_ID:-}" ]]; then
        run_quiet loginctl terminate-session "$XDG_SESSION_ID"
        return $?
    fi

    return 1
}

get_logout_override() {
    local backend=${1^^}
    local var_name="LOGOUT_CMD_${backend}"

    printf '%s' "${!var_name:-}"
}

run_logout_override() {
    local backend=$1
    local override

    override=$(get_logout_override "$backend")
    [[ -n "$override" ]] || return 1

    if run_shell_quiet "$override"; then
        return 0
    fi

    notify "Logout" "Custom logout command for ${backend} failed."
    return 2
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

openbox_logout() {
    if run_quiet openbox --exit; then
        return 0
    fi

    notify "Openbox" "Logout failed."
    return 1
}

bspwm_logout() {
    if run_quiet bspc quit; then
        return 0
    fi

    notify "bspwm" "Logout failed."
    return 1
}

i3_logout() {
    if run_quiet i3-msg exit; then
        return 0
    fi

    notify "i3" "Logout failed."
    return 1
}

plasma_logout() {
    if run_quiet qdbus org.kde.ksmserver /KSMServer logout 0 0 0; then
        return 0
    fi

    notify "Plasma" "Logout failed."
    return 1
}

awesome_logout() {
    if command_exists awesome-client; then
        if run_quiet awesome-client 'awesome.quit()'; then
            return 0
        fi

        notify "AwesomeWM" "Logout failed."
        return 1
    fi

    notify "AwesomeWM" "awesome-client is not installed."
    return 1
}

hyprland_logout() {
    if command_exists hyprctl; then
        if run_quiet hyprctl dispatch exit; then
            return 0
        fi

        notify "Hyprland" "Logout failed."
        return 1
    fi

    notify "Hyprland" "hyprctl is not installed."
    return 1
}

fjordwl_logout() {
    if command_exists mmsg && run_quiet mmsg -q; then
        return 0
    fi

    if terminate_current_session; then
        return 0
    fi

    if is_process_running "fjordwl" && run_quiet pkill -x "fjordwl"; then
        return 0
    fi

    notify "fjordwl" "Logout failed."
    return 1
}

dwl_logout() {
    if terminate_current_session; then
        return 0
    fi

    if is_process_running "dwl" && run_quiet pkill -x "dwl"; then
        return 0
    fi

    notify "dwl" "Logout failed."
    return 1
}

fjordwm_logout() {
    if is_process_running "fjordwm" && run_quiet pkill -x "fjordwm"; then
        notify "fjordwm" "Logged out successfully."
        return 0
    fi

    notify "fjordwm" "fjordwm is not running."
    return 1
}

dwm_logout() {
    if is_process_running "dwm" && run_quiet pkill -x "dwm"; then
        notify "dwm" "Logged out successfully."
        return 0
    fi

    notify "dwm" "dwm is not running."
    return 1
}

unknown_logout() {
    notify "Logout" "No known WM detected."
    return 1
}

detect_logout_backend() {
    if session_matches "openbox"; then
        printf '%s\n' "openbox"
    elif session_matches "bspwm"; then
        printf '%s\n' "bspwm"
    elif session_matches "i3"; then
        printf '%s\n' "i3"
    elif session_matches "plasma"; then
        printf '%s\n' "plasma"
    elif session_matches "awesome" || is_process_running "awesome"; then
        printf '%s\n' "awesome"
    elif session_matches "hyprland"; then
        printf '%s\n' "hyprland"
    elif session_matches "fjordwl" || is_process_running "fjordwl"; then
        printf '%s\n' "fjordwl"
    elif session_matches "dwl" || is_process_running "dwl"; then
        printf '%s\n' "dwl"
    elif session_matches "fjordwm" || is_process_running "fjordwm"; then
        printf '%s\n' "fjordwm"
    elif session_matches "dwm" || is_process_running "dwm"; then
        printf '%s\n' "dwm"
    else
        printf '%s\n' "unknown"
    fi
}

run_logout_backend() {
    case "$1" in
        openbox)
            openbox_logout
            ;;
        bspwm)
            bspwm_logout
            ;;
        i3)
            i3_logout
            ;;
        plasma)
            plasma_logout
            ;;
        awesome)
            awesome_logout
            ;;
        hyprland)
            hyprland_logout
            ;;
        fjordwl)
            fjordwl_logout
            ;;
        dwl)
            dwl_logout
            ;;
        fjordwm)
            fjordwm_logout
            ;;
        dwm)
            dwm_logout
            ;;
        *)
            unknown_logout
            ;;
    esac
}

logout_current_session() {
    local backend
    local override_status=1

    notify "Rofi Logout" "DESKTOP_SESSION=${DESKTOP_SESSION:-}  XDG_CURRENT_DESKTOP=${XDG_CURRENT_DESKTOP:-}"
    backend=$(detect_logout_backend)

    if run_logout_override "$backend"; then
        return 0
    else
        override_status=$?
    fi

    if [[ "$override_status" -eq 2 ]]; then
        return 1
    fi

    run_logout_backend "$backend"
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
