#!/usr/bin/env bash
set -euo pipefail

export XDG_SESSION_TYPE=x11
export XDG_CURRENT_DESKTOP=fjordwm
export XDG_SESSION_DESKTOP=fjordwm

launch_from_xinitrc() {
    if [[ "${FJORDWM_USE_XINITRC:-1}" == "0" ]]; then
        return 1
    fi

    local xinitrc="$HOME/.xinitrc"

    if [[ -x "$xinitrc" ]]; then
        exec "$xinitrc"
    fi

    if [[ -f "$xinitrc" ]]; then
        exec /bin/sh "$xinitrc"
    fi
}

launch_session_script() {
    local session_script="$HOME/fjordwm/scripts/fjordwm-session.sh"

    if [[ -x "$session_script" ]]; then
        exec "$session_script"
    fi
}

launch_fallback() {
    if command -v dbus-run-session >/dev/null 2>&1 \
        && [[ -z "${DBUS_SESSION_BUS_ADDRESS:-}" ]] \
        && [[ "${_IN_DBUS_RUN_SESSION:-0}" != "1" ]]; then
        export _IN_DBUS_RUN_SESSION=1
        exec dbus-run-session -- "$0"
    fi

    launch_session_script

    if [[ -x "$HOME/.local/bin/fjordwm" ]]; then
        exec "$HOME/.local/bin/fjordwm"
    fi

    exec fjordwm
}

launch_from_xinitrc
launch_fallback
