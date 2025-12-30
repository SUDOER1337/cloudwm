#!/usr/bin/env bash
set -euo pipefail

paru -Syu --noconfirm

paru -S --noconfirm \
    dwm \
    picom \
    fish \
    neovim \
    vscodium-bin \
    fzf \
    ripgrep \
    fd
