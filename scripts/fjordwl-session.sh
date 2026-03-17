#!/usr/bin/env bash
set -euo pipefail

run_once() {
    [[ $# -gt 0 ]] || return 0

    local cmd="$1"
    local cmd_name="${cmd##*/}"

    if [[ "$cmd" == */* ]]; then
        [[ -x "$cmd" ]] || return 0
    else
        command -v "$cmd" >/dev/null 2>&1 || return 0
    fi

    pgrep -u "$UID" -x "$cmd_name" >/dev/null 2>&1 && return 0
    "$@" >/dev/null 2>&1 &
}

ensure_dbus() {
    if [[ -n "${DBUS_SESSION_BUS_ADDRESS:-}" ]]; then
        return 0
    fi

    if command -v dbus-launch >/dev/null 2>&1; then
        eval "$(dbus-launch --sh-syntax --exit-with-session)"
    fi
}

export XDG_CURRENT_DESKTOP="${XDG_CURRENT_DESKTOP:-fjordwl}"
export XDG_SESSION_DESKTOP="${XDG_SESSION_DESKTOP:-fjordwl}"
export XDG_SESSION_TYPE="${XDG_SESSION_TYPE:-wayland}"
export XDG_MENU_PREFIX="${XDG_MENU_PREFIX:-arch-}"

ensure_dbus

if command -v systemctl >/dev/null 2>&1; then
    systemctl --user import-environment \
        WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP XDG_SESSION_TYPE \
        >/dev/null 2>&1 || true
fi

if command -v dbus-update-activation-environment >/dev/null 2>&1; then
    dbus-update-activation-environment --systemd \
        WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP XDG_SESSION_TYPE \
        >/dev/null 2>&1 || true
fi

run_once /usr/lib/polkit-kde-authentication-agent-1
run_once waybar
run_once swaync
run_once nm-applet

if [[ -x "$HOME/fjordwm/scripts/wayland-idle.sh" ]] && command -v swayidle >/dev/null 2>&1; then
    "$HOME/fjordwm/scripts/wayland-idle.sh" start >/dev/null 2>&1 || true
fi
