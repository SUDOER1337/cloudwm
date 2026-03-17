#!/usr/bin/env bash
set -euo pipefail

SCRIPT_SOURCE=${BASH_SOURCE[0]:-$0}
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$SCRIPT_SOURCE")" && pwd)
# shellcheck source=common.sh
. "$SCRIPT_DIR/common.sh"

start_notification_daemon() {
    local backend

    backend=$(fjordwm_notification_backend 2>/dev/null || true)
    case "$backend" in
        mako)
            if [[ -f "$FJORDWM_ROOT/mako/config" ]]; then
                mako --config "$FJORDWM_ROOT/mako/config" >/dev/null 2>&1 &
            else
                mako >/dev/null 2>&1 &
            fi
            disown
            ;;
        dunst)
            dunst >/dev/null 2>&1 &
            disown
            ;;
        *)
            return 1
            ;;
    esac
}

notifications_running() {
    local backend

    backend=$(fjordwm_notification_backend 2>/dev/null || true)
    [[ -n "$backend" ]] || return 1
    pgrep -x "$backend" >/dev/null 2>&1
}

notifications_label() {
    if notifications_running; then
        printf '%s\n' "On"
    else
        printf '%s\n' "Off"
    fi
}

toggle_notifications() {
    local backend

    backend=$(fjordwm_notification_backend 2>/dev/null || true)
    if [[ -z "$backend" ]]; then
        notify "Notifications" "No supported notification daemon found."
        return 1
    fi

    if pgrep -x "$backend" >/dev/null 2>&1; then
        pkill -x "$backend" >/dev/null 2>&1 || true
        notify "Notifications" "Disabled $backend."
    else
        start_notification_daemon || return 1
        notify "Notifications" "Enabled $backend."
    fi
}

idle_label() {
    local state

    state=$("$FJORDWM_ROOT/scripts/wayland-idle.sh" status 2>/dev/null || printf '%s' "off")
    if [[ "$state" == "on" ]]; then
        printf '%s\n' "On"
    else
        printf '%s\n' "Off"
    fi
}

toggle_idle() {
    "$FJORDWM_ROOT/scripts/wayland-idle.sh" toggle >/dev/null 2>&1 || true
}

case "${1:-notifications-label}" in
    notifications-label)
        notifications_label
        ;;
    toggle-notifications)
        toggle_notifications
        ;;
    idle-label)
        idle_label
        ;;
    toggle-idle)
        toggle_idle
        ;;
    *)
        printf '%s\n' "Usage: session-state.sh [notifications-label|toggle-notifications|idle-label|toggle-idle]" >&2
        exit 1
        ;;
esac
