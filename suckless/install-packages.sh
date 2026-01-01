#!/usr/bin/env bash
set -euo pipefail

# ─────────────────────────────────────────────
# Core packages (always installed)
# ─────────────────────────────────────────────

CORE_PKGS=(
    # Xorg + dwm deps
    xorg-server
    xorg-xinit
    xorg-xrandr
    xorg-xsetroot
    xorg-xbacklight
    libx11
    libxinerama
    libxft

    # Compositor & UX
    picom
    dunst
    redshift
    feh

    # Fonts (baseline look)
    ttf-iosevka-nerd
    ttf-jetbrains-mono-nerd

    # Shell & editor
    fish
    neovim

    # File managers
    thunar
    nemo

    # CLI tools
    ripgrep
    fd
    lsd
    fastfetch
)

# ─────────────────────────────────────────────
# Optional apps
# ─────────────────────────────────────────────

OPTIONAL_PKGS=(
    deadbeef
    deadbeef-mpris2-plugin
    stretchly-bin
)

# ─────────────────────────────────────────────
# Select optional packages
# ─────────────────────────────────────────────

OPTIONALS_SELECTED=()

if command -v fzf >/dev/null; then
    OPTIONALS_SELECTED=(
        $(printf "%s\n" "${OPTIONAL_PKGS[@]}" |
          fzf --multi --prompt="Select optional apps (TAB to toggle): ")
    )
fi

# ─────────────────────────────────────────────
# Choose helper
# ─────────────────────────────────────────────

if command -v paru >/dev/null; then
    AUR="paru"
else
    echo "paru not found. Falling back to pacman (AUR packages skipped)."
    AUR="sudo pacman"
    # Filter out AUR-only packages
    OPTIONALS_SELECTED=(
        $(printf "%s\n" "${OPTIONALS_SELECTED[@]}" | grep -v '\-bin$' || true)
    )
fi

# ─────────────────────────────────────────────
# Install
# ─────────────────────────────────────────────

$AUR -Syu --noconfirm
$AUR -S --noconfirm "${CORE_PKGS[@]}" "${OPTIONALS_SELECTED[@]}"

echo
echo "✔ Package installation complete"
