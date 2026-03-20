#!/usr/bin/env bash
set -euo pipefail

if [[ $EUID -eq 0 ]]; then
    echo "This script should not be run as root."
    exit 1
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_ROOT="$ROOT_DIR/config-backups"
CONF_FILE="$BACKUP_ROOT/apps.conf"
APP_SELECTION=""

usage() {
    cat <<'EOF'
Usage: ./suckless/install-configs.sh [--apps all|app1,app2]

Options:
  --apps VALUE   Install all configs or a comma-separated app list
  --help, -h     Show this message
EOF
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --apps)
                [[ $# -ge 2 ]] || {
                    echo "--apps requires a value."
                    exit 1
                }
                APP_SELECTION="$2"
                shift 2
                ;;
            --apps=*)
                APP_SELECTION="${1#*=}"
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

load_apps() {
    mapfile -t APP_LINES < <(grep -Ev '^\s*(#|$)' "$CONF_FILE")
    if [[ ${#APP_LINES[@]} -eq 0 ]]; then
        echo "No config entries found in $CONF_FILE"
        exit 1
    fi

    APP_NAMES=()
    for line in "${APP_LINES[@]}"; do
        APP_NAMES+=("${line%%=*}")
    done
}

has_app() {
    local needle="$1"
    local app

    for app in "${APP_NAMES[@]}"; do
        if [[ "$app" == "$needle" ]]; then
            return 0
        fi
    done

    return 1
}

expand_target() {
    local target="$1"
    eval "printf '%s\n' \"$target\""
}

source_path_for_target() {
    local expanded_target="$1"
    local relative_path

    case "$expanded_target" in
        "$HOME"/*)
            relative_path="${expanded_target#"$HOME"/}"
            printf '%s\n' "$BACKUP_ROOT/$relative_path"
            ;;
        *)
            return 1
            ;;
    esac
}

sync_target() {
    local source_path="$1"
    local target_path="$2"

    if [[ ! -e "$source_path" ]]; then
        echo "  Skipping missing source: $source_path"
        return
    fi

    if [[ -d "$source_path" ]]; then
        mkdir -p "$target_path"
        cp -a "$source_path"/. "$target_path"/
        return
    fi

    mkdir -p "$(dirname "$target_path")"
    cp -a "$source_path" "$target_path"
}

install_app() {
    local app="$1"
    local line paths raw_target expanded_target source_path

    for line in "${APP_LINES[@]}"; do
        if [[ "${line%%=*}" == "$app" ]]; then
            paths="${line#*=}"
            break
        fi
    done

    if [[ -z "${paths:-}" ]]; then
        echo "Skipping $app: missing manifest entry."
        return
    fi

    echo "Installing config for $app..."
    IFS='|' read -r -a TARGETS <<< "$paths"
    for raw_target in "${TARGETS[@]}"; do
        expanded_target="$(expand_target "$raw_target")"
        if ! source_path="$(source_path_for_target "$expanded_target")"; then
            echo "  Skipping unsupported target: $expanded_target"
            continue
        fi
        sync_target "$source_path" "$expanded_target"
    done
}

select_apps() {
    local normalized selection item

    normalized="${APP_SELECTION//,/ }"
    read -r -a REQUESTED_APPS <<< "$normalized"

    if [[ ${#REQUESTED_APPS[@]} -eq 0 ]]; then
        APP_SELECTION="all"
        REQUESTED_APPS=("all")
    fi

    if [[ "${REQUESTED_APPS[0]}" == "all" && ${#REQUESTED_APPS[@]} -eq 1 ]]; then
        SELECTED_APPS=("${APP_NAMES[@]}")
        return
    fi

    SELECTED_APPS=()
    for item in "${REQUESTED_APPS[@]}"; do
        if [[ "$item" == "all" ]]; then
            SELECTED_APPS=("${APP_NAMES[@]}")
            return
        fi

        if ! has_app "$item"; then
            echo "Unknown config selection: $item"
            echo "Available configs: ${APP_NAMES[*]}"
            exit 1
        fi

        SELECTED_APPS+=("$item")
    done
}

parse_args "$@"

if [[ ! -f "$CONF_FILE" ]]; then
    echo "Config manifest not found: $CONF_FILE"
    exit 1
fi

load_apps
select_apps

echo "====================================="
echo "  Config install"
echo "====================================="
echo

for app in "${SELECTED_APPS[@]}"; do
    install_app "$app"
done

echo
echo "Config installation complete."
