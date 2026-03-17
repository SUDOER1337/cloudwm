#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
WAYLAND_LOCK="$SCRIPT_DIR/wayland-lock.sh"
PREV_LAYOUT=""

if [[ "${XDG_SESSION_TYPE:-}" == "wayland" || -n "${WAYLAND_DISPLAY:-}" ]]; then
    if [[ ! -x "$WAYLAND_LOCK" ]]; then
        printf '%s\n' "Wayland lock helper is missing: $WAYLAND_LOCK" >&2
        exit 1
    fi

    exec "$WAYLAND_LOCK" "$@"
fi

if ! command -v slock >/dev/null 2>&1; then
    printf '%s\n' "slock is not installed." >&2
    exit 1
fi

if command -v setxkbmap >/dev/null 2>&1; then
    PREV_LAYOUT=$(setxkbmap -query | awk '/layout:/ {print $2}')

    if [[ -n "$PREV_LAYOUT" ]]; then
        setxkbmap us
        setxkbmap -query >/dev/null
        sleep 0.1
    fi
fi

slock

if [[ -n "$PREV_LAYOUT" ]] && command -v setxkbmap >/dev/null 2>&1; then
    setxkbmap "$PREV_LAYOUT"
fi
