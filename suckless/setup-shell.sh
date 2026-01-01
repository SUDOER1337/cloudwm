#!/usr/bin/env bash
set -euo pipefail

echo "====================================="
echo "    Fish setup"
echo "====================================="
echo

# ─────────────────────────────────────────────
# Check fish
# ─────────────────────────────────────────────

if ! command -v fish >/dev/null; then
    echo "󰅙 fish is not installed."
    echo "Install it via install-packages.sh first."
    exit 1
fi

# ─────────────────────────────────────────────
# Set default shell (ask first)
# ─────────────────────────────────────────────

CURRENT_SHELL="$(getent passwd "$USER" | cut -d: -f7)"

if [[ "$CURRENT_SHELL" != "$(command -v fish)" ]]; then
    read -rp "Set fish as default shell? [Y/n]: " ANS
    case "$ANS" in
        n|N|no|NO)
            echo "Skipping default shell change."
            ;;
        *)
            if ! grep -q "$(command -v fish)" /etc/shells; then
                echo "Adding fish to /etc/shells (requires sudo)"
                echo "$(command -v fish)" | sudo tee -a /etc/shells >/dev/null
            fi
            chsh -s "$(command -v fish)"
            echo "✔ Default shell set to fish (re-login required)"
            ;;
    esac
fi

# ─────────────────────────────────────────────
# Install fish config
# ─────────────────────────────────────────────

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
FISH_SRC="$ROOT_DIR/config-backups/.config/fish/"

FISH_DST="$HOME/.config/fish"

if [[ ! -d "$FISH_SRC" ]]; then
    echo "󰅙 Fish config not found:"
    echo "   $FISH_SRC"
    exit 1
fi

echo
echo "Installing fish config → $FISH_DST"

mkdir -p "$FISH_DST"

# Backup existing config
if [[ -e "$FISH_DST/config.fish" ]]; then
    BACKUP="$FISH_DST/config.fish.bak.$(date +%s)"
    echo "Backing up existing config.fish → $BACKUP"
    cp "$FISH_DST/config.fish" "$BACKUP"
fi

cp -r "$FISH_SRC/"* "$FISH_DST/"

echo
echo "✔ Fish shell setup complete"
