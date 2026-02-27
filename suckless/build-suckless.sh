#!/usr/bin/env bash
set -euo pipefail

# Security check - don't run as root
if [[ $EUID -eq 0 ]]; then
    echo "This script should not be run as root"
    exit 1
fi

# Error handling
trap 'echo "Error on line $LINENO: Command failed with exit code $?"' ERR

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUCKLESS_DIR="$ROOT_DIR"
HOME_XINIT="$HOME/.xinitrc"

require() {
    command -v "$1" >/dev/null 2>&1 || {
        echo "Missing dependency: $1"
        echo "Please install $1 and try again"
        exit 1
    }
}

require fzf
require make
require gcc

echo "== Suckless build script =="

# Validate profile selection
validate_profile() {
    local profile="$1"
    case "$profile" in
        desktop|laptop)
            return 0
            ;;
        *)
            echo "Invalid profile: $profile"
            return 1
            ;;
    esac
}

# ----------------------------
# Select profile
# ----------------------------
echo "Available profiles:"
echo "  desktop - Full desktop configuration"
echo "  laptop  - Laptop optimized configuration"
echo

PROFILE=$(printf "desktop\nlaptop" | fzf \
    --prompt="Select profile: " \
    --height=40% \
    --border)

[[ -z "$PROFILE" ]] && {
    echo "No profile selected, aborting."
    exit 1
}

# Validate selected profile
if ! validate_profile "$PROFILE"; then
    echo "Invalid profile selection"
    exit 1
fi

echo "Profile: $PROFILE"
echo "This will build and install DWM, slock, and slstatus for $PROFILE configuration"
read -p "Continue? [Y/n]: " confirm
if [[ "$confirm" =~ ^(n|N|no|NO)$ ]]; then
    echo "Aborted by user"
    exit 0
fi

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
    
    # Check if installation requires privileges
    if [[ $EUID -ne 0 ]]; then
        echo "Installing $name (requires sudo)…"
        sudo make install
    else
        echo "Installing $name…"
        make install
    fi
}

# Check if running in container that restricts sudo
check_sudo_access() {
    if ! sudo -n true 2>/dev/null; then
        echo "Warning: Cannot use sudo (possibly running in container)"
        echo "Alternative installation options:"
        echo "1. Build without installing (manual install later)"
        echo "2. Install to local directory (~/.local/bin)"
        echo "3. Exit and run with proper sudo access"
        
        local choice=$(printf "Build only\nInstall locally\nExit" | fzf \
            --prompt="Choose option: " \
            --height=40% \
            --border)
        
        case "$choice" in
            "Build only")
                return 1  # Skip installation
                ;;
            "Install locally")
                export PREFIX="$HOME/.local"
                echo "Installing to $PREFIX/bin"
                return 0  # Continue with local install
                ;;
            *)
                echo "Exiting. Please run with proper sudo access."
                exit 1
                ;;
        esac
    fi
    return 0  # Normal sudo available
}
# ----------------------------
# Build all
# ----------------------------
# Check sudo access before building
if ! check_sudo_access; then
    echo "Building without installation..."
    BUILD_ONLY=true
else
    BUILD_ONLY=false
fi

build_pkg cloudwm
build_pkg slock
build_pkg slstatus

echo "All done."
