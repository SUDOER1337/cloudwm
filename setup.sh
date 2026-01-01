#!/usr/bin/env bash
set -euo pipefail

# Resolve cloudwm root reliably
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT_DIR="$ROOT_DIR/suckless"


# ─────────────────────────────────────────────
# Ensure scripts are executable
# ─────────────────────────────────────────────

if [[ -d "$SCRIPT_DIR" ]]; then
    chmod +x "$SCRIPT_DIR"/*.sh 2>/dev/null || true
fi

echo "====================================="
echo "    Welcome to cloudwm Setup Menu"
echo "====================================="
echo

sleep 1

# ─────────────────────────────────────────────
# fzf check (setup menu dependency only)
# ─────────────────────────────────────────────

if ! command -v fzf >/dev/null; then
    echo "fzf not found."
    read -rp "Install fzf now? [Y/n]: " ANS
    case "$ANS" in
        n|N|no|NO)
            echo "fzf is required to continue. Exiting."
            exit 1
            ;;
        *)
            if command -v paru >/dev/null; then
                paru -S --noconfirm fzf
            else
                sudo pacman -S --noconfirm fzf
            fi
            ;;
    esac
fi

# ─────────────────────────────────────────────
# Menu
# ─────────────────────────────────────────────

OPTIONS=(
    "Run ALL"
    "Install packages"
    "Build & install dwm"
    "Setup shell"
    "Post-setup tasks"
)

CHOICE="$(printf '%s\n' "${OPTIONS[@]}" | fzf --prompt="Select setup task: ")"
echo

run() {
    local script="$SCRIPT_DIR/$1"
    if [[ ! -x "$script" ]]; then
        echo " Script not found or not executable:"
        echo "   $script"
        exit 1
    fi
    "$script"
}

case "$CHOICE" in 
    "Run ALL")
        run install-packages.sh
        run build-suckless.sh
        run setup-shell.sh
        ;;
    "Install packages")
        run install-packages.sh
        ;;
    "Build & install dwm")
        run build-suckless.sh
        ;;
    "Setup shell")
        run setup-shell.sh
        ;;
    *)
        echo "Exiting."
        ;;
esac
