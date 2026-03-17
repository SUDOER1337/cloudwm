#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID -eq 0 ]]; then
    echo "This script should not be run as root."
    exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
THEME_NAME="achromatic24.css"
THEME_SOURCE="$ROOT_DIR/themes/betterdiscord/$THEME_NAME"
CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
BETTERDISCORD_DIR="$CONFIG_HOME/BetterDiscord"
BETTERDISCORD_THEME_DIR="$BETTERDISCORD_DIR/themes"
BETTERDISCORD_DATA_DIR="$BETTERDISCORD_DIR/data/stable"
ASSUME_YES=false
SKIP_PACKAGES=false

usage() {
    cat <<'EOF'
Usage: ./suckless/install-betterdiscord.sh [--yes] [--skip-packages]

Installs Discord, installs or updates BetterDiscord, and copies the bundled
fjordwm BetterDiscord theme into both the theme directory and custom.css.

Options:
  --yes, -y          Run package installs without confirmation prompts
  --skip-packages    Skip Discord / betterdiscordctl package installation
  --help, -h         Show this message
EOF
}

require_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "Missing required command: $1"
        exit 1
    fi
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --yes|-y)
                ASSUME_YES=true
                shift
                ;;
            --skip-packages)
                SKIP_PACKAGES=true
                shift
                ;;
            --help|-h)
                usage
                exit 0
                ;;
            *)
                echo "Unknown argument: $1"
                usage
                exit 1
                ;;
        esac
    done
}

package_installed() {
    pacman -Q "$1" >/dev/null 2>&1
}

install_repo_package() {
    local pkg="$1"

    if package_installed "$pkg"; then
        echo "Package already installed: $pkg"
        return
    fi

    if command -v paru >/dev/null 2>&1; then
        if [[ "$ASSUME_YES" == true ]]; then
            paru -S --needed --noconfirm "$pkg"
        else
            paru -S --needed "$pkg"
        fi
        return
    fi

    require_cmd sudo
    if [[ "$ASSUME_YES" == true ]]; then
        sudo pacman -S --needed --noconfirm "$pkg"
    else
        sudo pacman -S --needed "$pkg"
    fi
}

install_aur_package() {
    local pkg="$1"
    local workdir

    if package_installed "$pkg"; then
        echo "AUR package already installed: $pkg"
        return
    fi

    if command -v paru >/dev/null 2>&1; then
        if [[ "$ASSUME_YES" == true ]]; then
            paru -S --needed --noconfirm "$pkg"
        else
            paru -S --needed "$pkg"
        fi
        return
    fi

    require_cmd git
    require_cmd makepkg

    workdir="$(mktemp -d)"
    trap "rm -rf '$workdir'" EXIT

    git clone "https://aur.archlinux.org/${pkg}.git" "$workdir/$pkg"
    (
        cd "$workdir/$pkg"
        if [[ "$ASSUME_YES" == true ]]; then
            makepkg -si --noconfirm
        else
            makepkg -si
        fi
    )
}

ensure_packages() {
    install_repo_package discord

    if command -v betterdiscordctl >/dev/null 2>&1; then
        echo "Found betterdiscordctl in PATH."
    else
        install_aur_package betterdiscordctl-git
    fi

    require_cmd betterdiscordctl
}

ensure_theme_source() {
    if [[ ! -f "$THEME_SOURCE" ]]; then
        echo "Bundled theme file not found: $THEME_SOURCE"
        exit 1
    fi
}

betterdiscord_installed() {
    local status_output

    if ! status_output="$(betterdiscordctl status 2>/dev/null)"; then
        return 1
    fi

    grep -q 'BetterDiscord asar installed: .*yes' <<<"$status_output" &&
        grep -q 'Discord "index.js" injected: yes' <<<"$status_output"
}

install_or_update_betterdiscord() {
    if betterdiscord_installed; then
        echo "BetterDiscord already installed; refreshing files..."
        betterdiscordctl reinstall
    else
        echo "Installing BetterDiscord into Discord..."
        betterdiscordctl install
    fi
}

backup_if_needed() {
    local source="$1"
    local target="$2"
    local backup

    if [[ ! -e "$target" ]]; then
        return
    fi

    if cmp -s "$source" "$target"; then
        return
    fi

    backup="${target}.bak.$(date +%Y%m%d-%H%M%S)"
    cp -a "$target" "$backup"
    echo "Backed up existing file to: $backup"
}

install_theme_files() {
    mkdir -p "$BETTERDISCORD_THEME_DIR" "$BETTERDISCORD_DATA_DIR"

    backup_if_needed "$THEME_SOURCE" "$BETTERDISCORD_THEME_DIR/$THEME_NAME"
    install -m 644 "$THEME_SOURCE" "$BETTERDISCORD_THEME_DIR/$THEME_NAME"

    backup_if_needed "$THEME_SOURCE" "$BETTERDISCORD_DATA_DIR/custom.css"
    install -m 644 "$THEME_SOURCE" "$BETTERDISCORD_DATA_DIR/custom.css"
}

print_summary() {
    cat <<EOF

BetterDiscord setup complete.

Installed theme file:
  $BETTERDISCORD_THEME_DIR/$THEME_NAME

Installed custom CSS:
  $BETTERDISCORD_DATA_DIR/custom.css

Open Discord and reload it if needed. If BetterDiscord's Custom CSS is disabled,
enable it in Settings > BetterDiscord > Custom CSS.
EOF
}

parse_args "$@"
require_cmd pacman
ensure_theme_source

if [[ "$SKIP_PACKAGES" == false ]]; then
    ensure_packages
else
    require_cmd discord
    require_cmd betterdiscordctl
fi

install_or_update_betterdiscord
install_theme_files
print_summary
