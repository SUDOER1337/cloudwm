#!/usr/bin/env bash
set -euo pipefail

# Security check - don't run as root
if [[ $EUID -eq 0 ]]; then
    echo "This script should not be run as root"
    exit 1
fi

# Error handling
trap 'echo "Error on line $LINENO: Command failed with exit code $?"' ERR

# Resolve cloudwm root reliably
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT_DIR="$ROOT_DIR/suckless"


# ─────────────────────────────────────────────
# Backup existing configurations
# ─────────────────────────────────────────────

backup_configs() {
    local backup_script="$ROOT_DIR/scripts/backup-configs.sh"
    if [[ -f "$backup_script" ]]; then
        echo "Creating backup of existing configurations..."
        "$backup_script"
        echo
    else
        echo "Warning: Backup script not found, skipping backup"
    fi
}

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
    "Build & install cloudwm"
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
        echo "Make sure the script exists and has execute permissions"
        exit 1
    fi
    echo "Running: $script"
    "$script"
}

case "$CHOICE" in 
    "Run ALL")
        backup_configs
        run install-packages.sh
        run build-suckless.sh
        run setup-shell.sh
        ;;
    "Install packages")
        backup_configs
        run install-packages.sh
        ;;
    "Build & install cloudwm")
        run build-suckless.sh
        ;;
    "Setup shell")
        backup_configs
        run setup-shell.sh
        ;;
    *)
        echo "Exiting."
        ;;
esac
