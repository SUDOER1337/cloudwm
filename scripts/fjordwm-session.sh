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

export XDG_CURRENT_DESKTOP="${XDG_CURRENT_DESKTOP:-fjordwm}"
export XDG_SESSION_DESKTOP="${XDG_SESSION_DESKTOP:-fjordwm}"
export XDG_SESSION_TYPE="${XDG_SESSION_TYPE:-x11}"
export XDG_MENU_PREFIX="${XDG_MENU_PREFIX:-arch-}"

ensure_dbus

if command -v systemctl >/dev/null 2>&1; then
    systemctl --user import-environment \
        DISPLAY XAUTHORITY XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP XDG_SESSION_TYPE \
        >/dev/null 2>&1 || true
fi

if command -v dbus-update-activation-environment >/dev/null 2>&1; then
    dbus-update-activation-environment --systemd \
        DISPLAY XAUTHORITY XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP XDG_SESSION_TYPE \
        >/dev/null 2>&1 || true
fi

run_once /usr/lib/polkit-kde-authentication-agent-1
run_once dunst
run_once nm-applet
run_once picom
run_once slstatus
run_once udiskie

if command -v feh >/dev/null 2>&1 && [[ -f "$HOME/fjordwm/wallpapers/forest1.jpg" ]]; then
    feh --bg-scale "$HOME/fjordwm/wallpapers/forest1.jpg" >/dev/null 2>&1 || true
fi

if [[ -x "$HOME/fjordwm/scripts/autolock.sh" ]]; then
    run_once "$HOME/fjordwm/scripts/autolock.sh"
fi

if command -v redshift >/dev/null 2>&1; then
    run_once redshift
fi

if [[ -x "$HOME/.local/bin/fjordwm" ]]; then
    exec "$HOME/.local/bin/fjordwm"
fi

exec fjordwm
