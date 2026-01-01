#!/usr/bin/env bash
set -e

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUCKLESS_DIR="$ROOT_DIR"
HOME_XINIT="$HOME/.xinitrc"

require() {
    command -v "$1" >/dev/null 2>&1 || {
        echo "Missing dependency: $1"
        exit 1
    }
}

require fzf
require make
require gcc

echo "== Suckless build script =="

# ----------------------------
# Select profile
# ----------------------------
PROFILE=$(printf "desktop\nlaptop" | fzf \
    --prompt="Select profile: " \
    --height=40% \
    --border)

[[ -z "$PROFILE" ]] && {
    echo "No profile selected, aborting."
    exit 1
}

echo "Profile: $PROFILE"

# ----------------------------
# slstatus handling
# ----------------------------
SLSTATUS_SRC="$SUCKLESS_DIR/slstatus-$PROFILE"
SLSTATUS_DST="$SUCKLESS_DIR/slstatus"

[[ ! -d "$SLSTATUS_SRC" ]] && {
    echo "Missing $SLSTATUS_SRC"
    exit 1
}

echo "Preparing slstatus…"
rm -rf "$SLSTATUS_DST"
cp -r "$SLSTATUS_SRC" "$SLSTATUS_DST"

# ----------------------------
# xinitrc handling
# ----------------------------
XINIT_SRC="$SUCKLESS_DIR/.xinitrc-$PROFILE"

[[ ! -f "$XINIT_SRC" ]] && {
    echo "Missing $XINIT_SRC"
    exit 1
}

echo "Installing .xinitrc → $HOME_XINIT"
cp "$XINIT_SRC" "$HOME_XINIT"

# ----------------------------
# Build helper
# ----------------------------
build_pkg() {
    local name="$1"
    local dir="$SUCKLESS_DIR/$name"

    [[ ! -d "$dir" ]] && {
        echo "Skipping $name (not found)"
        return
    }

    echo "Building $name…"
    cd "$dir"
    make clean
    make
    sudo make install
}

# ----------------------------
# Build all
# ----------------------------
build_pkg dwm
build_pkg slock
build_pkg slstatus

echo "All done."
