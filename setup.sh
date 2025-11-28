#!/bin/bash
# setup.sh - Setup / Update DWM and configs using fzf

REPO_BASE=~/cloudwm
CONFIG_SRC=~/cloudwm/config/

# Ensure fzf is installed
if ! command -v fzf &>/dev/null; then
    echo "fzf is not installed. Install it first (sudo pacman -S fzf)"
    exit 1
fi

clear
echo "=== CloudWM Setup / Update ==="

# 1. Select machine version
MACHINE=$(printf "Desktop\nLaptop\nCancel" | fzf --height 10 --border --prompt="Select machine: ")

case $MACHINE in
    Desktop) DWMDIR="$REPO_BASE/cloudwm-desktop" ;;
    Laptop) DWMDIR="$REPO_BASE/cloudwm-laptop" ;;
    Cancel|"") echo "Cancelled"; exit 0 ;;
esac

# 2. Check for Git updates
cd "$DWMDIR" || exit
echo "Checking for updates..."
git fetch origin
LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse origin/main)

if [ "$LOCAL" != "$REMOTE" ]; then
    UPDATE=$(printf "Yes\nNo" | fzf --height 5 --border --prompt="Updates found! Pull now? ")
    if [ "$UPDATE" == "Yes" ]; then
        git pull origin main
        echo "Pulled latest changes."
    else
        echo "Skipping update."
    fi
else
    echo "Already up-to-date."
fi

# 3. Build and install DWM
echo "Building and installing DWM..."
sudo make clean install
echo "DWM installation complete."

# 4. Deploy configs
DEPLOY=$(printf "Yes\nNo" | fzf --height 5 --border --prompt="Deploy configs (~/.config)? ")
if [ "$DEPLOY" == "Yes" ]; then
    # Backup existing configs
    TIMESTAMP=$(date +%Y%m%d-%H%M%S)
    mkdir -p ~/.config_backup/$TIMESTAMP
    echo "Backing up existing configs..."
    for d in $(ls -d ~/.config/*); do
        cp -r "$d" ~/.config_backup/$TIMESTAMP/
    done

    # Copy new configs
    echo "Copying configs..."
    cp -r "$CONFIG_SRC/"* ~/.config/
    echo "Configs deployed!"
fi

echo "=== Setup / Update finished ==="

