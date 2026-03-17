#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID -eq 0 ]]; then
    echo "This script should not be run as root."
    exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FISH_SRC="$ROOT_DIR/config-backups/.config/fish"
FISH_DST="$HOME/.config/fish"
BACKUP_ROOT="$HOME/.config/fish-backups"
ASSUME_YES=false
FISH_ITEMS=(
    completions
    conf.d
    functions
    config.fish
    fish_plugins
)

usage() {
    cat <<'EOF'
Usage: ./suckless/setup-shell.sh [--yes]

Options:
  --yes, -y    Skip prompts and apply the default shell change
  --help, -h   Show this message
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

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
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

current_shell() {
    if command -v getent >/dev/null 2>&1; then
        getent passwd "$USER" | cut -d: -f7
        return
    fi

    awk -F: -v user="$USER" '$1 == user { print $7 }' /etc/passwd
}

confirm_shell_change() {
    local answer

    if [[ "$ASSUME_YES" == true ]]; then
        return 0
    fi

    if ! is_interactive; then
        return 1
    fi

    read -rp "Set fish as default shell? [Y/n]: " answer
    case "$answer" in
        n|N|no|NO) return 1 ;;
        *) return 0 ;;
    esac
}

ensure_shell_entry() {
    local fish_path="$1"

    if grep -qxF "$fish_path" /etc/shells; then
        return
    fi

    require_cmd sudo
    echo "Adding $fish_path to /etc/shells"
    printf '%s\n' "$fish_path" | sudo tee -a /etc/shells >/dev/null
}

maybe_set_default_shell() {
    local fish_path="$1"
    local active_shell

    active_shell="$(current_shell)"
    if [[ "$active_shell" == "$fish_path" ]]; then
        echo "fish is already the default shell."
        return
    fi

    if ! confirm_shell_change; then
        echo "Skipping default shell change."
        return
    fi

    require_cmd chsh
    ensure_shell_entry "$fish_path"
    chsh -s "$fish_path"
    echo "Default shell set to fish. Re-login required."
}

backup_existing_config() {
    local timestamp backup_dir

    if [[ ! -d "$FISH_DST" ]]; then
        return
    fi

    timestamp="$(date +%Y%m%d%H%M%S)"
    backup_dir="$BACKUP_ROOT/$timestamp"
    mkdir -p "$backup_dir"
    cp -a "$FISH_DST"/. "$backup_dir"/
    echo "Backed up existing fish config to $backup_dir"
}

sync_item() {
    local item="$1"

    if [[ ! -e "$FISH_SRC/$item" ]]; then
        return
    fi

    rm -rf "$FISH_DST/$item"
    cp -a "$FISH_SRC/$item" "$FISH_DST/"
}

parse_args "$@"
require_cmd fish

if [[ ! -d "$FISH_SRC" ]]; then
    echo "Fish config not found: $FISH_SRC"
    exit 1
fi

echo "====================================="
echo "  Fish setup"
echo "====================================="
echo

maybe_set_default_shell "$(command -v fish)"

backup_existing_config
mkdir -p "$FISH_DST"

for item in "${FISH_ITEMS[@]}"; do
    sync_item "$item"
done

echo
echo "Fish shell setup complete."
