#!/usr/bin/env bash
set -euo pipefail

if ! command -v swaylock >/dev/null 2>&1; then
    printf '%s\n' "swaylock is not installed." >&2
    exit 1
fi

mode="-f"
if [[ "${1:-}" == "--daemonize" ]]; then
    mode="--daemonize"
fi

exec swaylock "$mode" \
    --ignore-empty-password \
    --show-failed-attempts \
    --indicator-idle-visible \
    --clock \
    --font "Iosevka Nerd Font" \
    --datestr "%A, %d %B" \
    --timestr "%H:%M" \
    --indicator-radius 108 \
    --indicator-thickness 7 \
    --inside-color 292828dd \
    --ring-color 556c59ff \
    --key-hl-color c0af8bff \
    --line-color 00000000 \
    --separator-color 00000000 \
    --text-color c0af8bff \
    --inside-clear-color 7d6d51dd \
    --ring-clear-color 7d6d51ff \
    --text-clear-color c0af8bff \
    --inside-ver-color 556c59dd \
    --ring-ver-color 556c59ff \
    --text-ver-color c0af8bff \
    --inside-caps-lock-color 6f8160dd \
    --ring-caps-lock-color 6f8160ff \
    --text-caps-lock-color c0af8bff \
    --inside-wrong-color 725548dd \
    --ring-wrong-color 725548ff \
    --text-wrong-color c0af8bff
