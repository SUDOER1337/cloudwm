#!/usr/bin/env bash

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROFI_SCRIPT_DIR="$SCRIPT_DIR"
# shellcheck source=../scripts/rofi-common.sh
. "$SCRIPT_DIR/../scripts/rofi-common.sh"

THEME_PATH=$(rofi_theme_path "clipboard")

if fjordwm_is_wayland_session && command -v cliphist >/dev/null 2>&1 && command -v wl-copy >/dev/null 2>&1; then
    selection=$(
        cliphist list | rofi \
            -dmenu \
            -i \
            -no-custom \
            -p " Clipboard" \
            $(rofi_vim_keybindings_text) \
            -theme "$THEME_PATH"
    ) || exit 0

    [ -n "$selection" ] || exit 0
    printf '%s' "$selection" | cliphist decode | wl-copy
    exit 0
fi

if ! command -v greenclip >/dev/null 2>&1; then
    if command -v notify-send >/dev/null 2>&1; then
        if fjordwm_is_wayland_session; then
            notify-send "Rofi Clipboard" "cliphist and wl-clipboard are required on Wayland."
        else
            notify-send "Rofi Clipboard" "greenclip is not installed."
        fi
    fi
    exit 1
fi

exec rofi \
    -modi "clipboard:greenclip print" \
    -show "clipboard" \
    -run-command "{cmd}" \
    -i \
    -no-custom \
    -eh 10 \
    $(rofi_vim_keybindings_text) \
    -sorting-method "fzf" \
    -p " Clipboard" \
    -theme "$THEME_PATH"
