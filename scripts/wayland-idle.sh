#!/usr/bin/env bash
set -euo pipefail

LOCK_SCRIPT="${LOCK_SCRIPT:-$HOME/fjordwm/scripts/wayland-lock.sh}"
LOCK_DELAY_MINUTES="${LOCK_DELAY_MINUTES:-1}"
NOTIFY_BEFORE="${NOTIFY_BEFORE:-30}"

idle_running() {
    pgrep -u "$UID" -x swayidle >/dev/null 2>&1
}

notify_idle() {
    local message=$1

    if command -v notify-send >/dev/null 2>&1; then
        notify-send -u low "Autolock" "$message" >/dev/null 2>&1 || true
    fi
}

start_idle() {
    local lock_after
    local warn_after
    local -a cmd

    if idle_running; then
        return 0
    fi

    if ! command -v swayidle >/dev/null 2>&1; then
        printf '%s\n' "swayidle is not installed." >&2
        exit 1
    fi

    lock_after=$((LOCK_DELAY_MINUTES * 60))
    warn_after=$((lock_after - NOTIFY_BEFORE))
    cmd=(swayidle -w)

    if ((warn_after > 0)); then
        cmd+=(timeout "$warn_after" "notify-send -u low 'Autolock' 'Locking in ${NOTIFY_BEFORE} seconds...'")
    fi

    cmd+=(timeout "$lock_after" "$LOCK_SCRIPT")
    cmd+=(before-sleep "$LOCK_SCRIPT --daemonize")

    "${cmd[@]}" >/dev/null 2>&1 &
    disown
}

stop_idle() {
    pkill -u "$UID" -x swayidle >/dev/null 2>&1 || true
}

status_idle() {
    if idle_running; then
        printf '%s\n' "on"
    else
        printf '%s\n' "off"
    fi
}

toggle_idle() {
    if idle_running; then
        stop_idle
        notify_idle "Disabled."
    else
        start_idle
        notify_idle "Enabled."
    fi
}

case "${1:-start}" in
    start)
        start_idle
        ;;
    stop)
        stop_idle
        ;;
    toggle)
        toggle_idle
        ;;
    status)
        status_idle
        ;;
    *)
        printf '%s\n' "Usage: wayland-idle.sh [start|stop|toggle|status]" >&2
        exit 1
        ;;
esac
