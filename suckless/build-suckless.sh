#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID -eq 0 ]]; then
    echo "This script should not be run as root."
    exit 1
fi

trap 'echo "Error on line $LINENO: Command failed with exit code $?"' ERR

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SUCKLESS_DIR="$ROOT_DIR"
HOME_XINIT="$HOME/.xinitrc"
PROFILE=""
INSTALL_MODE=""
ASSUME_YES=false
BUILD_ROOT=""
MODE_MAKE_VARS=()
WM_TARGET="fjordwm"

usage() {
    cat <<'EOF'
Usage: ./suckless/build-suckless.sh [--profile PROFILE] [--wm TARGET] [--install-mode MODE] [--yes]

Options:
  --profile PROFILE         desktop or laptop (required for fjordwm or both)
  --wm TARGET               fjordwm, fjordwl, or both (`dwl` also works)
  --install-mode MODE       sudo, local, or build-only
  --yes, -y                Skip confirmation prompts
  --help, -h               Show this message
EOF
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

normalize_wm() {
    case "$1" in
        dwl|fjordwl) printf '%s\n' "fjordwl" ;;
        *) printf '%s\n' "$1" ;;
    esac
}

validate_profile() {
    case "$1" in
        desktop|laptop) return 0 ;;
        *)
            echo "Invalid profile: $1"
            return 1
            ;;
    esac
}

validate_install_mode() {
    case "$1" in
        sudo|local|build-only) return 0 ;;
        *)
            echo "Invalid install mode: $1"
            return 1
            ;;
    esac
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

wm_requires_profile() {
    [[ "$WM_TARGET" == "fjordwm" || "$WM_TARGET" == "both" ]]
}

wm_includes_fjordwl() {
    [[ "$WM_TARGET" == "fjordwl" || "$WM_TARGET" == "both" ]]
}

default_install_mode() {
    if wm_includes_fjordwl; then
        printf '%s\n' "local"
        return
    fi

    if command -v sudo >/dev/null 2>&1; then
        printf '%s\n' "sudo"
    else
        printf '%s\n' "local"
    fi
}

require_pkg_config_module() {
    local module="$1"
    local label="${2:-$1}"

    if ! pkg-config --exists "$module"; then
        printf '%s\n' "$label"
    fi
}

verify_fjordwl_build_deps() {
    local missing=()
    local module=""

    require_cmd pkg-config

    while IFS= read -r module; do
        [[ -n "$module" ]] && missing+=("$module")
    done < <(
        require_pkg_config_module wayland-server
        require_pkg_config_module xkbcommon
        require_pkg_config_module libinput
        require_pkg_config_module wlroots-0.19
        require_pkg_config_module wayland-scanner
        require_pkg_config_module xcb
        require_pkg_config_module xcb-icccm
    )

    if [[ "${#missing[@]}" -gt 0 ]]; then
        echo "Missing fjordwl build dependencies:"
        printf '  - %s\n' "${missing[@]}"
        echo "Install them with ./setup.sh --task packages --wm fjordwl --yes"
        exit 1
    fi
}

ensure_fzf() {
    if command -v fzf >/dev/null 2>&1; then
        return
    fi

    echo "fzf is required for interactive selection. Re-run with --profile/--install-mode or install fzf."
    exit 1
}

prompt_profile() {
    ensure_fzf
    PROFILE="$(printf 'desktop\nlaptop\n' | fzf --prompt="Select profile: " --height=40% --border)"

    if [[ -z "$PROFILE" ]]; then
        echo "No profile selected."
        exit 1
    fi
}

prompt_install_mode() {
    local options=()

    ensure_fzf

    if wm_includes_fjordwl; then
        options+=(local build-only)
        if command -v sudo >/dev/null 2>&1; then
            options+=(sudo)
        fi
    else
        if command -v sudo >/dev/null 2>&1; then
            options+=(sudo)
        fi
        options+=(local build-only)
    fi

    INSTALL_MODE="$(
        printf '%s\n' "${options[@]}" |
        fzf --prompt="Select install mode: " --height=40% --border
    )"

    if [[ -z "$INSTALL_MODE" ]]; then
        echo "No install mode selected."
        exit 1
    fi
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --profile)
                [[ $# -ge 2 ]] || {
                    echo "--profile requires a value."
                    exit 1
                }
                PROFILE="$2"
                shift 2
                ;;
            --profile=*)
                PROFILE="${1#*=}"
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
            --install-mode)
                [[ $# -ge 2 ]] || {
                    echo "--install-mode requires a value."
                    exit 1
                }
                INSTALL_MODE="$2"
                shift 2
                ;;
            --install-mode=*)
                INSTALL_MODE="${1#*=}"
                shift
                ;;
            --yes|-y)
                ASSUME_YES=true
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

resolve_inputs() {
    require_cmd make
    require_cmd gcc

    validate_wm "$WM_TARGET" || exit 1
    WM_TARGET="$(normalize_wm "$WM_TARGET")"

    if [[ -n "$PROFILE" ]]; then
        validate_profile "$PROFILE" || exit 1
    fi

    if wm_requires_profile && [[ -z "$PROFILE" ]]; then
        if [[ "$ASSUME_YES" == true || ! -t 0 || ! -t 1 ]]; then
            echo "--profile is required when building '$WM_TARGET' in non-interactive mode."
            exit 1
        fi
        prompt_profile
    fi

    if [[ -z "$INSTALL_MODE" ]]; then
        if [[ "$ASSUME_YES" == true ]] || ! is_interactive; then
            INSTALL_MODE="$(default_install_mode)"
        else
            prompt_install_mode
        fi
    fi
    validate_install_mode "$INSTALL_MODE" || exit 1

    if [[ "$INSTALL_MODE" == "sudo" ]]; then
        require_cmd sudo
    fi

    if wm_includes_fjordwl; then
        verify_fjordwl_build_deps
    fi

    if [[ "$INSTALL_MODE" == "local" ]]; then
        MODE_MAKE_VARS=(
            "PREFIX=$HOME/.local"
            "MANPREFIX=$HOME/.local/share/man"
            "MANDIR=$HOME/.local/share/man"
            "DATADIR=$HOME/.local/share"
        )
    fi
}

confirm_plan() {
    local answer

    if [[ "$ASSUME_YES" == true ]]; then
        return
    fi

    if ! is_interactive; then
        echo "Use --yes to run non-interactively."
        exit 1
    fi

    if wm_requires_profile; then
        echo "Profile: $PROFILE"
    fi
    echo "Window manager target: $WM_TARGET"
    echo "Install mode: $INSTALL_MODE"
    read -rp "Continue? [Y/n]: " answer
    case "$answer" in
        n|N|no|NO)
            echo "Aborted."
            exit 0
            ;;
    esac
}

prepare_build_root() {
    BUILD_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/suckless-build.XXXXXX")"
    trap 'rm -rf "$BUILD_ROOT"' EXIT
}

stage_source_tree() {
    local src_dir="$1"
    local stage_name="$2"
    local stage_dir="$BUILD_ROOT/$stage_name"

    mkdir -p "$stage_dir"
    cp -a "$src_dir"/. "$stage_dir"/
    printf '%s\n' "$stage_dir"
}

build_pkg() {
    local label="$1"
    local src_dir="$2"
    local stage_dir

    if [[ ! -d "$src_dir" ]]; then
        echo "Missing source directory: $src_dir"
        exit 1
    fi

    stage_dir="$(stage_source_tree "$src_dir" "$label")"

    echo "Building $label..."
    make -C "$stage_dir" clean
    make -C "$stage_dir"

    if [[ "$INSTALL_MODE" == "build-only" ]]; then
        echo "Skipping install for $label (build-only mode)."
        return
    fi

    echo "Installing $label..."
    if [[ "$INSTALL_MODE" == "sudo" ]]; then
        sudo make -C "$stage_dir" "${MODE_MAKE_VARS[@]}" install
    else
        make -C "$stage_dir" "${MODE_MAKE_VARS[@]}" install
    fi
}

build_fjordwm_stack() {
    build_pkg fjordwm "$SUCKLESS_DIR/fjordwm"
    build_pkg slock "$SUCKLESS_DIR/slock"
    build_pkg "slstatus-$PROFILE" "$SUCKLESS_DIR/slstatus-$PROFILE"
}

build_fjordwl_stack() {
    build_pkg fjordwl "$SUCKLESS_DIR/fjordwl"
}

install_xinitrc() {
    local src="$SUCKLESS_DIR/.xinitrc-$PROFILE"
    local backup=""
    local temp_file

    if [[ ! -f "$src" ]]; then
        echo "Missing profile xinitrc: $src"
        exit 1
    fi

    temp_file="$(mktemp "$HOME/.xinitrc.tmp.XXXXXX")"
    cp "$src" "$temp_file"
    chmod +x "$temp_file"

    if [[ -f "$HOME_XINIT" ]]; then
        backup="$HOME/.xinitrc.backup.$(date +%Y%m%d%H%M%S)"
        cp "$HOME_XINIT" "$backup"
        echo "Backed up existing .xinitrc to $backup"
    fi

    mv "$temp_file" "$HOME_XINIT"
    echo "Installed $HOME_XINIT"
}

parse_args "$@"
resolve_inputs
confirm_plan
prepare_build_root

case "$WM_TARGET" in
    fjordwm)
        build_fjordwm_stack
        ;;
    fjordwl)
        build_fjordwl_stack
        ;;
    both)
        build_fjordwm_stack
        build_fjordwl_stack
        ;;
esac

if [[ "$INSTALL_MODE" == "build-only" ]]; then
    echo "Build-only mode selected; skipped .xinitrc installation."
elif wm_requires_profile; then
    install_xinitrc
else
    echo "fjordwl selected; skipped .xinitrc installation."
fi

echo "All done."
