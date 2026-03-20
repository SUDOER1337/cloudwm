#!/usr/bin/env bash

set -euo pipefail

SCRIPT_SOURCE=${BASH_SOURCE[0]:-$0}
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$SCRIPT_SOURCE")" && pwd)
ROFI_SCRIPT_DIR="$SCRIPT_DIR"
# shellcheck source=../scripts/rofi-common.sh
. "$SCRIPT_DIR/../scripts/rofi-common.sh"

THEME_PATH=$(rofi_theme_path "workspaces")
MENU_TITLE="󰨞  VSCodium Workspaces"
ACTION_EXIT=0

detect_codium() {
    if command -v codium >/dev/null 2>&1; then
        printf '%s\n' "codium"
        return 0
    fi

    if command -v vscodium >/dev/null 2>&1; then
        printf '%s\n' "vscodium"
        return 0
    fi

    return 1
}

notify_workspace() {
    local message=$1

    if command -v notify-send >/dev/null 2>&1; then
        notify-send "VSCodium Workspaces" "$message"
    fi
}

rofi_pick_index() {
    local prompt=$1
    local message=$2
    shift 2

    local selection
    if ! selection=$(printf '%s\n' "$@" | rofi -dmenu -i -format i -p "$prompt" -mesg "$message" $(rofi_vim_keybindings_selection) -theme "$THEME_PATH"); then
        return 1
    fi

    [ -n "$selection" ] || return 1
    printf '%s\n' "$selection"
}

rofi_input() {
    local prompt=$1
    local value

    if ! value=$(printf '' | rofi -dmenu -p "$prompt" $(rofi_vim_keybindings_text) -theme "$THEME_PATH"); then
        return 1
    fi

    printf '%s\n' "$value"
}

workspace_roots() {
    local -a roots=()

    if [ -n "${VSCODIUM_WORKSPACE_ROOTS:-}" ]; then
        local root
        IFS=':' read -r -a roots <<< "$VSCODIUM_WORKSPACE_ROOTS"
        for root in "${roots[@]}"; do
            [ -d "$root" ] && printf '%s\n' "$root"
        done
        return 0
    fi

    for root in "$HOME/Workspaces" "$HOME/Projects" "$HOME/Documents"; do
        [ -d "$root" ] && printf '%s\n' "$root"
    done
}

find_workspace_files() {
    [ "$#" -gt 0 ] || return 0

    find "$@" \
        \( -type d \( -name .git -o -name node_modules -o -name .cache -o -name .local -o -name .venv -o -name dist -o -name build -o -name target \) -prune \) \
        -o \( -type f -name '*.code-workspace' -print0 \) |
        sort -z
}

load_workspaces() {
    local -a roots=()
    local -a workspaces=()
    local workspace
    local use_home_fallback=1

    mapfile -t roots < <(workspace_roots)

    if [ "${#roots[@]}" -eq 0 ]; then
        roots=("$HOME")
        use_home_fallback=0
    fi

    while IFS= read -r -d '' workspace; do
        workspaces+=("$workspace")
    done < <(find_workspace_files "${roots[@]}")

    if [ "${#workspaces[@]}" -eq 0 ] && [ "$use_home_fallback" -eq 1 ]; then
        while IFS= read -r -d '' workspace; do
            workspaces+=("$workspace")
        done < <(find_workspace_files "$HOME")
    fi

    if [ "${#workspaces[@]}" -gt 0 ]; then
        printf '%s\0' "${workspaces[@]}"
    fi
}

workspace_label() {
    local workspace=$1
    local name directory

    name=$(basename "$workspace" .code-workspace)
    directory=$(dirname "$workspace")
    directory=${directory/#$HOME/\~}

    printf '%s\n' "󰨞  $name  ·  $directory"
}

open_workspace() {
    local codium_cmd=$1
    local workspace=$2
    shift 2

    "$codium_cmd" "$@" "$workspace" >/dev/null 2>&1 &
    disown
}

reveal_workspace() {
    local workspace=$1
    local workspace_dir

    workspace_dir=$(dirname "$workspace")
    if ! command -v xdg-open >/dev/null 2>&1; then
        rofi -e "xdg-open is not installed."
        return 1
    fi

    xdg-open "$workspace_dir" >/dev/null 2>&1 &
    disown
}

rename_workspace() {
    local workspace=$1
    local current_name new_name target

    current_name=$(basename "$workspace" .code-workspace)
    if ! new_name=$(rofi_input "Rename $current_name"); then
        return 1
    fi

    [ -n "$new_name" ] || return 1

    if [[ "$new_name" == *"/"* ]]; then
        rofi -e "Workspace names cannot contain '/'."
        return 1
    fi

    [[ "$new_name" == *.code-workspace ]] || new_name="${new_name}.code-workspace"
    target="$(dirname "$workspace")/$new_name"

    if [ "$target" = "$workspace" ]; then
        return 0
    fi

    if [ -e "$target" ]; then
        rofi -e "A workspace with that name already exists."
        return 1
    fi

    mv -- "$workspace" "$target"
    notify_workspace "Renamed to $(basename "$target")"
}

delete_workspace() {
    local workspace=$1
    local choice

    if ! choice=$(rofi_pick_index "Delete Workspace" "Delete $(basename "$workspace")?" "Delete" "Cancel"); then
        return 1
    fi

    [ "$choice" = "0" ] || return 1

    rm -- "$workspace"
    notify_workspace "Deleted $(basename "$workspace")"
}

manage_workspace() {
    local codium_cmd=$1
    local workspace=$2
    local label choice
    local -a actions=(
        "󰨞  Open"
        "󰆍  Open in New Window"
        "  Show in Files"
        "󰑕  Rename"
        "󰆴  Delete"
        "  Back"
    )

    label=$(workspace_label "$workspace")

    if ! choice=$(rofi_pick_index "Workspace Action" "$label" "${actions[@]}"); then
        return 0
    fi

    case "$choice" in
        0)
            open_workspace "$codium_cmd" "$workspace" --reuse-window
            ACTION_EXIT=1
            ;;
        1)
            open_workspace "$codium_cmd" "$workspace" --new-window
            ACTION_EXIT=1
            ;;
        2)
            if reveal_workspace "$workspace"; then
                ACTION_EXIT=1
            fi
            ;;
        3)
            rename_workspace "$workspace" || true
            ;;
        4)
            delete_workspace "$workspace" || true
            ;;
        *)
            ;;
    esac
}

main() {
    local codium_cmd
    local -a workspace_files=()
    local -a labels=()
    local workspace choice

    if ! codium_cmd=$(detect_codium); then
        rofi -e "VSCodium was not found. Install 'codium' or 'vscodium'."
        exit 1
    fi

    while true; do
        workspace_files=()
        labels=()
        while IFS= read -r -d '' workspace; do
            workspace_files+=("$workspace")
            labels+=("$(workspace_label "$workspace")")
        done < <(load_workspaces)

        if [ "${#workspace_files[@]}" -eq 0 ]; then
            rofi -e "No .code-workspace files found. Set VSCODIUM_WORKSPACE_ROOTS to customize search roots."
            exit 1
        fi

        if ! choice=$(rofi_pick_index "$MENU_TITLE" "Enter to manage or open a workspace." "${labels[@]}"); then
            exit 0
        fi

        manage_workspace "$codium_cmd" "${workspace_files[$choice]}"

        if [ "$ACTION_EXIT" -eq 1 ]; then
            exit 0
        fi
    done
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
