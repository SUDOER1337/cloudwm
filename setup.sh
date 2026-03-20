#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID -eq 0 ]]; then
    echo "This script should not be run as root."
    exit 1
fi

trap 'echo "Error on line $LINENO: Command failed with exit code $?"' ERR

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_DIR="$ROOT_DIR/suckless"

TASK=""
PROFILE=""
ASSUME_YES=false
WM_TARGET="fjordwm"
CONFIG_SELECTION=""

usage() {
    cat <<'EOF'
Usage: ./setup.sh [--task TASK] [--profile PROFILE] [--wm TARGET] [--configs ITEMS] [--yes]

Tasks:
  all       Run packages, build, config install, shell setup, and post-setup tasks
  packages  Install required packages
  build     Build and install the selected window-manager stack
  config    Install selected configuration backups
  shell     Install the fish shell configuration
  post      Run desktop-session post-setup tasks
  betterdiscord  Install BetterDiscord and the bundled fjordwm theme

Profiles:
  desktop
  laptop

Options:
  --task TASK         Select which task to run
  --profile PROFILE   Build profile for fjordwm/both build/all tasks
  --wm TARGET         fjordwm, dwl, or both
  --configs ITEMS     all or a comma-separated config list for config/all
  --yes, -y           Run without confirmation prompts
  --help, -h          Show this message
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

validate_task() {
    case "$1" in
        all|packages|build|config|shell|post|betterdiscord) return 0 ;;
        *)
            echo "Invalid task: $1"
            return 1
            ;;
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

validate_wm() {
    case "$1" in
        fjordwm|dwl|both) return 0 ;;
        *)
            echo "Invalid window manager target: $1"
            return 1
            ;;
    esac
}

wm_requires_profile() {
    [[ "$WM_TARGET" == "fjordwm" || "$WM_TARGET" == "both" ]]
}

ensure_fzf() {
    if command -v fzf >/dev/null 2>&1; then
        return
    fi

    if ! is_interactive; then
        echo "fzf is required for interactive mode. Use --task/--profile or install fzf first."
        exit 1
    fi

    echo "fzf not found."
    read -rp "Install fzf now? [Y/n]: " answer
    case "$answer" in
        n|N|no|NO)
            echo "fzf is required to continue in interactive mode."
            exit 1
            ;;
        *)
            if command -v paru >/dev/null 2>&1; then
                paru -S --noconfirm fzf
            else
                require_cmd pacman
                require_cmd sudo
                sudo pacman -S --noconfirm fzf
            fi
            ;;
    esac
}

prompt_task() {
    local selection

    ensure_fzf
    selection="$(
        printf '%s\n' \
            "all: Run all tasks" \
            "packages: Install packages" \
            "build: Build and install the selected WM stack" \
            "config: Install selected configs" \
            "shell: Setup fish shell" \
            "post: Run post-setup tasks" \
            "betterdiscord: Install BetterDiscord and theme" |
        fzf --prompt="Select setup task: " --height=40% --border
    )"

    TASK="${selection%%:*}"
    if [[ -z "$TASK" ]]; then
        echo "No task selected."
        exit 1
    fi
}

available_configs() {
    grep -Ev '^\s*(#|$)' "$ROOT_DIR/config-backups/apps.conf" | cut -d= -f1
}

prompt_configs() {
    local selection

    ensure_fzf
    selection="$(
        {
            printf '%s\n' all
            available_configs
        } | fzf --multi --prompt="Select configs (TAB marks, ENTER confirms): " --height=60% --border
    )"

    if [[ -z "$selection" ]]; then
        echo "No configs selected."
        exit 1
    fi

    if grep -qx 'all' <<< "$selection"; then
        CONFIG_SELECTION="all"
        return
    fi

    CONFIG_SELECTION="$(paste -sd, <<< "$selection")"
}

prompt_profile() {
    ensure_fzf
    PROFILE="$(printf 'desktop\nlaptop\n' | fzf --prompt="Select profile: " --height=40% --border)"

    if [[ -z "$PROFILE" ]]; then
        echo "No profile selected."
        exit 1
    fi
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --task)
                [[ $# -ge 2 ]] || {
                    echo "--task requires a value."
                    exit 1
                }
                TASK="$2"
                shift 2
                ;;
            --task=*)
                TASK="${1#*=}"
                shift
                ;;
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
            --configs)
                [[ $# -ge 2 ]] || {
                    echo "--configs requires a value."
                    exit 1
                }
                CONFIG_SELECTION="$2"
                shift 2
                ;;
            --configs=*)
                CONFIG_SELECTION="${1#*=}"
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
    if [[ -n "$TASK" ]]; then
        validate_task "$TASK" || exit 1
    elif [[ "$ASSUME_YES" == true ]] || ! is_interactive; then
        echo "--task is required in non-interactive mode."
        usage
        exit 1
    else
        prompt_task
    fi

    validate_wm "$WM_TARGET" || exit 1

    if [[ -n "$PROFILE" ]]; then
        validate_profile "$PROFILE" || exit 1
    fi

    if [[ "$TASK" == "all" || "$TASK" == "build" ]] && wm_requires_profile; then
        if [[ -n "$PROFILE" ]]; then
            :
        elif [[ "$ASSUME_YES" == true ]] || ! is_interactive; then
            echo "--profile is required for task '$TASK' when building '$WM_TARGET' in non-interactive mode."
            exit 1
        else
            prompt_profile
        fi
    fi

    if [[ "$TASK" == "all" || "$TASK" == "config" ]]; then
        if [[ -n "$CONFIG_SELECTION" ]]; then
            :
        elif [[ "$ASSUME_YES" == true ]] || ! is_interactive; then
            CONFIG_SELECTION="all"
        else
            prompt_configs
        fi
    fi
}

preflight() {
    case "$TASK" in
        all|packages)
            require_cmd pacman
            if ! command -v paru >/dev/null 2>&1; then
                require_cmd sudo
            fi
            ;;&
        betterdiscord)
            require_cmd pacman
            if ! command -v paru >/dev/null 2>&1; then
                require_cmd sudo
            fi
            ;;
        all|build)
            require_cmd make
            require_cmd gcc
            ;;
    esac
}

run_script() {
    local script="$SCRIPT_DIR/$1"
    shift

    if [[ ! -x "$script" ]]; then
        echo "Script not found or not executable: $script"
        exit 1
    fi

    echo "Running: $script $*"
    "$script" "$@"
}

run_packages() {
    local args=()

    if [[ "$ASSUME_YES" == true ]]; then
        args+=(--non-interactive)
    fi
    args+=(--wm "$WM_TARGET")

    run_script install-packages.sh "${args[@]}"
}

run_build() {
    local args=(--wm "$WM_TARGET")

    if [[ -n "$PROFILE" ]]; then
        args+=(--profile "$PROFILE")
    fi

    if [[ "$ASSUME_YES" == true ]]; then
        args+=(--yes)
    fi

    run_script build-suckless.sh "${args[@]}"
}

run_configs() {
    local args=(--apps "$CONFIG_SELECTION")

    run_script install-configs.sh "${args[@]}"
}

run_shell() {
    local args=()

    if [[ "$ASSUME_YES" == true ]]; then
        args+=(--yes)
    fi

    run_script setup-shell.sh "${args[@]}"
}

run_post() {
    run_script post-setup.sh
}

run_betterdiscord() {
    local args=()

    if [[ "$ASSUME_YES" == true ]]; then
        args+=(--yes)
    fi

    run_script install-betterdiscord.sh "${args[@]}"
}

echo "====================================="
echo "  fjordwm setup"
echo "====================================="
echo

parse_args "$@"
resolve_inputs
preflight

case "$TASK" in
    all)
        run_packages
        run_build
        run_configs
        run_shell
        run_post
        ;;
    packages)
        run_packages
        ;;
    build)
        run_build
        ;;
    config)
        run_configs
        ;;
    shell)
        run_shell
        ;;
    post)
        run_post
        ;;
    betterdiscord)
        run_betterdiscord
        ;;
esac
