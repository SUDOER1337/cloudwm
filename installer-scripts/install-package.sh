#!/usr/bin/env bash
set -euo pipefail

paru -Syu --noconfirm

paru -S --noconfirm \
    picom \
    fish \
    neovim \
    vscodium-bin \
    ripgrep \
    fd  \
    lsd
