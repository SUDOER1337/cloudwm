#!/bin/sh

# Shared path helpers for rofi menu scripts.

: "${ROFI_SCRIPT_DIR:?Set ROFI_SCRIPT_DIR before sourcing rofi-common.sh}"

ROFI_ROOT=$(CDPATH= cd -- "$ROFI_SCRIPT_DIR/.." && pwd)
FJORDWM_ROOT=$(CDPATH= cd -- "$ROFI_ROOT/.." && pwd)

rofi_theme_path() {
    theme_name=$1

    if [ -z "$theme_name" ]; then
        printf '%s\n' "rofi_theme_path requires a theme name" >&2
        return 1
    fi

    printf '%s/%s.rasi\n' "$ROFI_SCRIPT_DIR" "$theme_name"
}

fjordwm_script_path() {
    script_name=$1

    if [ -z "$script_name" ]; then
        printf '%s\n' "fjordwm_script_path requires a script name" >&2
        return 1
    fi

    printf '%s/scripts/%s\n' "$FJORDWM_ROOT" "$script_name"
}

fjordwm_is_wayland_session() {
    [ "${XDG_SESSION_TYPE:-}" = "wayland" ] || [ -n "${WAYLAND_DISPLAY:-}" ]
}

fjordwm_terminal() {
    if fjordwm_is_wayland_session && command -v foot >/dev/null 2>&1; then
        printf '%s\n' "foot"
        return 0
    fi

    if command -v kitty >/dev/null 2>&1; then
        printf '%s\n' "kitty"
        return 0
    fi

    if command -v xterm >/dev/null 2>&1; then
        printf '%s\n' "xterm"
        return 0
    fi

    return 1
}

fjordwm_notification_backend() {
    if fjordwm_is_wayland_session && command -v mako >/dev/null 2>&1; then
        printf '%s\n' "mako"
        return 0
    fi

    if command -v dunst >/dev/null 2>&1; then
        printf '%s\n' "dunst"
        return 0
    fi

    return 1
}

fjordwm_mako_config_path() {
    printf '%s/mako/config\n' "$FJORDWM_ROOT"
}

rofi_vim_keybindings_selection() {
    printf "%s\n" \
        "-kb-row-up" "k" \
        "-kb-row-down" "j" \
        "-kb-row-left" "h" \
        "-kb-row-right" "l"
}

rofi_vim_keybindings_text() {
    printf "%s\n" \
        "-kb-row-up" "Alt+k" \
        "-kb-row-down" "Alt+j" \
        "-kb-row-left" "Alt+h" \
        "-kb-row-right" "Alt+l"
}

rofi_vim_keybindings() {
    rofi_vim_keybindings_text
}

rofi_vim_keybindings_dmenu() {
    rofi_vim_keybindings_text
}
