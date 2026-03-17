#!/usr/bin/env bash
set -euo pipefail

SCRIPT_SOURCE=${BASH_SOURCE[0]:-$0}
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$SCRIPT_SOURCE")" && pwd)
# shellcheck source=common.sh
. "$SCRIPT_DIR/common.sh"

pause_media() {
    if command -v playerctl >/dev/null 2>&1; then
        playerctl pause >/dev/null 2>&1 || true
    fi
}

mute_audio() {
    if command -v wpctl >/dev/null 2>&1; then
        wpctl set-mute @DEFAULT_AUDIO_SINK@ 1 >/dev/null 2>&1 || true
    elif command -v amixer >/dev/null 2>&1; then
        amixer set Master mute >/dev/null 2>&1 || true
    fi
}

logout_session() {
    if command -v loginctl >/dev/null 2>&1 && [[ -n "${XDG_SESSION_ID:-}" ]]; then
        loginctl terminate-session "$XDG_SESSION_ID"
        return 0
    fi

    pkill -x fjordwl >/dev/null 2>&1 || pkill -x dwl >/dev/null 2>&1 || true
}

"$SCRIPT_DIR/toggle-panel.sh" close-all >/dev/null 2>&1 || true

case "${1:-}" in
    lock)
        exec "$FJORDWM_ROOT/scripts/lock-wrapper.sh"
        ;;
    logout)
        logout_session
        ;;
    suspend)
        pause_media
        mute_audio
        "$FJORDWM_ROOT/scripts/lock-wrapper.sh" --daemonize >/dev/null 2>&1 || \
            "$FJORDWM_ROOT/scripts/lock-wrapper.sh" >/dev/null 2>&1 || true
        exec systemctl suspend
        ;;
    reboot)
        exec systemctl reboot
        ;;
    shutdown)
        exec systemctl poweroff
        ;;
    *)
        printf '%s\n' "Usage: power.sh [lock|logout|suspend|reboot|shutdown]" >&2
        exit 1
        ;;
esac
