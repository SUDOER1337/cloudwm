#!/usr/bin/env bash
set -euo pipefail

find_fjordwl_bin() {
    if command -v fjordwl >/dev/null 2>&1; then
        command -v fjordwl
        return 0
    fi

    if command -v dwl >/dev/null 2>&1; then
        command -v dwl
        return 0
    fi

    return 1
}

FJORDWL_BIN="$(find_fjordwl_bin || true)"

if [[ -z "$FJORDWL_BIN" ]]; then
    printf '%s\n' "fjordwl is not installed." >&2
    exit 1
fi

if [[ -z "${XDG_RUNTIME_DIR:-}" ]]; then
    printf '%s\n' "XDG_RUNTIME_DIR is not set. Start fjordwl from logind/seatd-backed session." >&2
    exit 1
fi

ensure_display_info_compat() {
    local compat_dir="$HOME/.local/lib"
    local compat_target="$compat_dir/libdisplay-info.so.2"

    if ! command -v ldd >/dev/null 2>&1; then
        return 0
    fi

    if ! ldd "$FJORDWL_BIN" 2>/dev/null | grep -q 'libdisplay-info\.so\.2 => not found'; then
        return 0
    fi

    if [[ -e /usr/lib/libdisplay-info.so.3 ]]; then
        mkdir -p "$compat_dir"
        ln -sf /usr/lib/libdisplay-info.so.3 "$compat_target"
        export LD_LIBRARY_PATH="$compat_dir${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"
    fi
}

ensure_portal_config() {
    local config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
    local portal_dir="$config_home/xdg-desktop-portal"
    local portal_conf="$portal_dir/fjordwl-portals.conf"

    if [[ -e "$portal_conf" ]]; then
        return 0
    fi

    mkdir -p "$portal_dir"
    cat >"$portal_conf" <<'EOF'
[preferred]
default=gtk
org.freedesktop.impl.portal.ScreenCast=wlr
org.freedesktop.impl.portal.Screenshot=wlr
EOF
}

export XDG_CURRENT_DESKTOP=fjordwl
export XDG_SESSION_DESKTOP=fjordwl
export XDG_SESSION_TYPE=wayland
export GDK_BACKEND="${GDK_BACKEND:-wayland,x11,*}"
export QT_QPA_PLATFORM="${QT_QPA_PLATFORM:-wayland;xcb}"
export QT_QPA_PLATFORMTHEME="${QT_QPA_PLATFORMTHEME:-gtk3}"
export SDL_VIDEODRIVER="${SDL_VIDEODRIVER:-wayland}"
export CLUTTER_BACKEND="${CLUTTER_BACKEND:-wayland}"
export MOZ_ENABLE_WAYLAND="${MOZ_ENABLE_WAYLAND:-1}"
export QT_WAYLAND_DISABLE_WINDOWDECORATION="${QT_WAYLAND_DISABLE_WINDOWDECORATION:-1}"
export _JAVA_AWT_WM_NONREPARENTING=1

ensure_display_info_compat
ensure_portal_config

exec "$FJORDWL_BIN" -s "/usr/bin/env bash \"$HOME/fjordwm/scripts/fjordwl-session.sh\""
