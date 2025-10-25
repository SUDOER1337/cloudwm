#!/usr/bin/env bash
# ─── CloudWM Setup Script ────────────────────────────────────────────────
# Purpose: Clean install and build CloudWM (dwm + suckless tools)
# Author: You
# ─────────────────────────────────────────────────────────────────────────

# Exit immediately if a command fails
set -e

# ─── Paths ───────────────────────────────────────────────────────────────
CLOUDWM="$HOME/cloudwm"
DWM_DIR="$CLOUDWM"
SUCKLESS_DIR="$CLOUDWM/suckless"
XSESSION_DIR="/usr/share/xsessions"
XSESSION_FILE="$XSESSION_DIR/dwm.desktop"

# ─── Install dependencies ────────────────────────────────────────────────
echo "Installing required packages..."
sudo pacman -Syu --noconfirm \
    base-devel git gcc make pkg-config xorg-server xorg-xinit \
    libX11 libXft libXinerama

# ─── Build and install dwm ───────────────────────────────────────────────
echo "Building dwm..."
cd "$DWM_DIR"
make clean
make
sudo make install

# ─── Build and install suckless tools ────────────────────────────────────
for tool in slock slstatus; do
    echo "Building $tool..."
    cd "$SUCKLESS_DIR/$tool"
    make clean
    make
    sudo make install
done

# ─── Create dwm.desktop for Display Managers ─────────────────────────────
echo "Creating dwm.desktop for display managers..."
echo "[Desktop Entry]
Encoding=UTF-8
Name=CLOUDWM (xinitrc)
Comment=CLOUDWM via xinitrc
Exec=$HOME/.xinitrc
Icon=dwm
Type=XSession" | sudo tee "$XSESSION_FILE" > /dev/null

sudo chmod 644 "$XSESSION_FILE"
echo "dwm.desktop created at $XSESSION_FILE"

# ─── Optional: Copy .xinitrc ─────────────────────────────────────────────
# Uncomment the line below if you want to copy your .xinitrc
# cp .xinitrc $HOME/.xinitrc

echo "CloudWM setup complete!"

