#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROFI_SCRIPT_DIR="$SCRIPT_DIR"
# shellcheck source=../scripts/rofi-common.sh
. "$SCRIPT_DIR/../scripts/rofi-common.sh"

THEME_PATH=$(rofi_theme_path "windows")

show_error() {
    rofi -e "$1"
}

build_window_rows() {
    wmctrl -lx | awk '
        {
            id = $1
            title = ""

            if (NF >= 5) {
                title = $5
                for (i = 6; i <= NF; i++) {
                    title = title " " $i
                }
            }

            printf "%s\t%s\n", id, title
        }
    '
}

if ! command -v wmctrl > /dev/null 2>&1; then
    show_error "wmctrl is required for the windows menu."
    exit 1
fi

window_ids=()
entries=()

while IFS=$'\t' read -r window_id window_title; do
    [ -n "$window_id" ] || continue

    entry_number=$((${#window_ids[@]} + 1))

    if [ -z "$window_title" ]; then
        window_title="(untitled)"
    fi

    window_ids+=("$window_id")
    entries+=("$(printf '%d :: %s' "$entry_number" "$window_title")")
done < <(build_window_rows)

if [ ${#entries[@]} -eq 0 ]; then
    show_error "No windows found."
    exit 1
fi

if ! selected_index=$(
    printf '%s\n' "${entries[@]}" | rofi \
        -dmenu \
        -i \
        $(rofi_vim_keybindings_selection) \
        -no-custom \
        -format i \
        -theme "$THEME_PATH"
); then
    exit 0
fi

[ -n "$selected_index" ] || exit 0
[ "$selected_index" -ge 0 ] 2>/dev/null || exit 0

wmctrl -i -a "${window_ids[$selected_index]}"
