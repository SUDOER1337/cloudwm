#!/usr/bin/env bash
set -euo pipefail

# Resolve cloudwm root reliably
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT_DIR="$ROOT_DIR/scripts"

echo "====================================="
echo "         cloudwm Setup Menu"
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
            echo "fzf is required. Exiting."
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

run() {
    local script="$SCRIPT_DIR/$1"
    if [[ ! -x "$script" ]]; then
        echo "❌ Script not found or not executable:"
        echo "   $script"
        exit 1
    fi
    "$script"
}

case "$CHOICE" in
    "Restore dotfiles")
        run restore-dotfiles.sh
        ;;
    "Install packages")
        run install-packages.sh
        ;;
    "Build & install dwm")
        run build-dwm.sh
        ;;
    "Setup shell")
        run setup-shell.sh
        ;;
    "Post-setup tasks")
        run post-setup.sh
        ;;
    "Run ALL")
        run restore-dotfiles.sh
        run install-packages.sh
        run build-dwm.sh
        run setup-shell.sh
        run post-setup.sh
        ;;
    *)
        echo "Exiting."
        ;;
esac
