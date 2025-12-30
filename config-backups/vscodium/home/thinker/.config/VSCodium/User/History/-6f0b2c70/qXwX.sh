#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT_DIR="$ROOT_DIR/scripts"

echo "====================================="
echo "         cloudwm Setup Menu"
echo "====================================="
echo

# ─────────────────────────────────────────────
# fzf check
# ─────────────────────────────────────────────

if ! command -v fzf >/dev/null; then
    echo "fzf not found."
    read -rp "Install fzf now? [Y/n]: " ANS
    case "$ANS" in
        n|N|no|NO)
            echo "fzf required. Exiting."
            exit 1
            ;;
        *)
            paru -S --noconfirm fzf
            ;;
    esac
fi

# ─────────────────────────────────────────────
# Menu
# ─────────────────────────────────────────────

OPTIONS=(
    "Restore dotfiles"
    "Install packages"
    "Build & install dwm"
    "Setup shell"
    "Post-setup tasks"
    "Run ALL"
    "Exit"
)

CHOICE="$(printf '%s\n' "${OPTIONS[@]}" | fzf --prompt="Select setup task: ")"

echo

case "$CHOICE" in
    "Restore dotfiles")
        "$SCRIPT_DIR/restore-dotfiles.sh"
        ;;
    "Install packages")
        "$SCRIPT_DIR/install-packages.sh"
        ;;
    "Build & install dwm")
        "$SCRIPT_DIR/build-dwm.sh"
        ;;
    "Setup shell")
        "$SCRIPT_DIR/setup-shell.sh"
        ;;
    "Post-setup tasks")
        "$SCRIPT_DIR/post-setup.sh"
        ;;
    "Run ALL")
        "$SCRIPT_DIR/restore-dotfiles.sh"
        "$SCRIPT_DIR/install-packages.sh"
        "$SCRIPT_DIR/build-dwm.sh"
        "$SCRIPT_DIR/setup-shell.sh"
        "$SCRIPT_DIR/post-setup.sh"
        ;;
    *)
        echo "Exiting."
        ;;
esac
