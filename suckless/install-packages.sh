#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID -eq 0 ]]; then
    echo "This script should not be run as root."
    exit 1
fi

COMMON_REPO_PKGS=(
    dunst
    libnotify
    network-manager-applet
    playerctl
    polkit-kde-agent
    rofi
    redshift
    ttf-iosevka-nerd
    ttf-jetbrains-mono-nerd
    udiskie
    fish
    neovim
    thunar
    nemo
    tumbler
    gdk-pixbuf2
    ffmpegthumbnailer
    ripgrep
    fd
    lsd
    fastfetch
)

FJORDWM_REPO_PKGS=(
    xorg-server
    xorg-xinit
    xorg-xrandr
    xorg-xsetroot
    xorg-xbacklight
    libx11
    libxinerama
    libxft
    picom
    feh
)

FJORDWL_REPO_PKGS=(
    brightnessctl
    cliphist
    eww
    foot
    grim
    libinput
    mako
    qt5-wayland
    qt6-wayland
    slurp
    swayidle
    swaylock
    swaync
    swww
    waybar
    wayland
    wlroots
    wl-clipboard
    xkbcommon
    wayland-protocols
    pkgconf
    libxcb
    xcb-util-wm
    xdg-desktop-portal
    xdg-desktop-portal-gtk
    xdg-desktop-portal-wlr
    xorg-xwayland
)

OPTIONAL_PKGS=(
    deadbeef
    deadbeef-mpris2-plugin
    stretchly-bin
)

NON_INTERACTIVE=false
OPTIONAL_ARGS=()
SELECTED_OPTIONALS=()
REPO_OPTIONALS=()
AUR_OPTIONALS=()
SKIPPED_OPTIONALS=()
PACKAGES_TO_INSTALL=()
HELPER=""
DIALOG_PKG=""
UPDATE_CMD=()
INSTALL_CMD=()
WM_TARGET="fjordwm"

usage() {
    cat <<'EOF'
Usage: ./suckless/install-packages.sh [--non-interactive] [--wm TARGET] [--optional PKG[,PKG...]]

Options:
  --non-interactive       Skip optional-package prompts
  --wm TARGET             fjordwm, fjordwl, or both (`dwl` also works)
  --optional LIST         Comma-separated list of optional packages to install
  --help, -h              Show this message
EOF
}

normalize_wm() {
    case "$1" in
        dwl|fjordwl) printf '%s\n' "fjordwl" ;;
        *) printf '%s\n' "$1" ;;
    esac
}

require_cmd() {
    if ! command -v "$1" >/dev/null 2>&1; then
        echo "Missing required command: $1"
        exit 1
    fi
}

is_interactive() {
    [[ -t 0 && -t 1 ]]
}

package_in_sync_db() {
    pacman -Si "$1" >/dev/null 2>&1
}

array_contains() {
    local needle="$1"
    shift
    local item

    for item in "$@"; do
        if [[ "$item" == "$needle" ]]; then
            return 0
        fi
    done

    return 1
}

validate_wm() {
    case "$1" in
        fjordwm|fjordwl|dwl|both) return 0 ;;
        *)
            echo "Invalid window manager target: $1"
            return 1
            ;;
    esac
}

append_unique_packages() {
    local pkg

    for pkg in "$@"; do
        if ! array_contains "$pkg" "${PACKAGES_TO_INSTALL[@]}"; then
            PACKAGES_TO_INSTALL+=("$pkg")
        fi
    done
}

add_optional_selection() {
    local pkg="$1"

    if ! array_contains "$pkg" "${OPTIONAL_PKGS[@]}"; then
        echo "Unknown optional package: $pkg"
        exit 1
    fi

    if ! array_contains "$pkg" "${SELECTED_OPTIONALS[@]}"; then
        SELECTED_OPTIONALS+=("$pkg")
    fi
}

parse_optional_arg() {
    local raw="$1"
    local value trimmed

    IFS=',' read -r -a OPTIONAL_ARGS <<< "$raw"
    for value in "${OPTIONAL_ARGS[@]}"; do
        trimmed="${value#"${value%%[![:space:]]*}"}"
        trimmed="${trimmed%"${trimmed##*[![:space:]]}"}"
        [[ -n "$trimmed" ]] || continue
        add_optional_selection "$trimmed"
    done
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --non-interactive)
                NON_INTERACTIVE=true
                shift
                ;;
            --wm)
                [[ $# -ge 2 ]] || {
                    echo "--wm requires a value."
                    exit 1
                }
                WM_TARGET="$2"
                shift 2
                ;;
            --wm=*)
                WM_TARGET="${1#*=}"
                shift
                ;;
            --optional)
                [[ $# -ge 2 ]] || {
                    echo "--optional requires a value."
                    exit 1
                }
                parse_optional_arg "$2"
                shift 2
                ;;
            --optional=*)
                parse_optional_arg "${1#*=}"
                shift
                ;;
            --help|-h)
                usage
                exit 0
                ;;
            *)
                echo "Unknown argument: $1"
                usage
                exit 1
                ;;
        esac
    done
}

choose_installer() {
    require_cmd pacman

    if command -v paru >/dev/null 2>&1; then
        HELPER="paru"
        DIALOG_PKG="zenity-gtk3"
        UPDATE_CMD=(paru -Syu --noconfirm)
        INSTALL_CMD=(paru -S --noconfirm)
        return
    fi

    require_cmd sudo
    HELPER="pacman"
    DIALOG_PKG="zenity"
    UPDATE_CMD=(sudo pacman -Syu --noconfirm)
    INSTALL_CMD=(sudo pacman -S --noconfirm)
}

prompt_optional_packages() {
    if [[ "${#SELECTED_OPTIONALS[@]}" -gt 0 ]]; then
        return
    fi

    if [[ "$NON_INTERACTIVE" == true ]]; then
        return
    fi

    if ! is_interactive; then
        return
    fi

    if ! command -v fzf >/dev/null 2>&1; then
        echo "fzf not found; skipping optional package selection."
        return
    fi

    mapfile -t SELECTED_OPTIONALS < <(
        printf '%s\n' "${OPTIONAL_PKGS[@]}" |
        fzf --multi --prompt="Select optional apps (TAB to toggle): " --height=40% --border || true
    )
}

classify_optional_packages() {
    local pkg

    for pkg in "${SELECTED_OPTIONALS[@]}"; do
        if package_in_sync_db "$pkg"; then
            REPO_OPTIONALS+=("$pkg")
        elif [[ "$HELPER" == "paru" ]]; then
            AUR_OPTIONALS+=("$pkg")
        else
            SKIPPED_OPTIONALS+=("$pkg")
        fi
    done
}

build_install_list() {
    PACKAGES_TO_INSTALL=()
    append_unique_packages "${COMMON_REPO_PKGS[@]}"

    case "$WM_TARGET" in
        fjordwm)
            append_unique_packages "${FJORDWM_REPO_PKGS[@]}"
            ;;
        fjordwl)
            append_unique_packages "${FJORDWL_REPO_PKGS[@]}"
            ;;
        both)
            append_unique_packages "${FJORDWM_REPO_PKGS[@]}" "${FJORDWL_REPO_PKGS[@]}"
            ;;
    esac

    append_unique_packages "$DIALOG_PKG"

    if [[ "$HELPER" == "paru" ]]; then
        append_unique_packages "${REPO_OPTIONALS[@]}" "${AUR_OPTIONALS[@]}"
    else
        append_unique_packages "${REPO_OPTIONALS[@]}"
    fi
}

print_list() {
    local label="$1"
    shift || true

    echo "$label"
    if [[ $# -eq 0 ]]; then
        echo "  (none)"
        return
    fi

    local item
    for item in "$@"; do
        echo "  - $item"
    done
}

parse_args "$@"
validate_wm "$WM_TARGET" || exit 1
WM_TARGET="$(normalize_wm "$WM_TARGET")"
choose_installer
prompt_optional_packages
classify_optional_packages
build_install_list

echo "Using package helper: $HELPER"
echo "Window manager target: $WM_TARGET"
echo "Preferred dialog package: $DIALOG_PKG"

"${UPDATE_CMD[@]}"
"${INSTALL_CMD[@]}" "${PACKAGES_TO_INSTALL[@]}"

echo
echo "Package installation complete."
echo
print_list "Installed optional packages:" "${REPO_OPTIONALS[@]}" "${AUR_OPTIONALS[@]}"
print_list "Skipped optional packages:" "${SKIPPED_OPTIONALS[@]}"
echo
echo "Run ./suckless/post-setup.sh from an active desktop session to apply GUI settings."
