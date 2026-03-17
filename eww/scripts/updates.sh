#!/usr/bin/env bash
set -euo pipefail

SCRIPT_SOURCE=${BASH_SOURCE[0]:-$0}
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$SCRIPT_SOURCE")" && pwd)
# shellcheck source=common.sh
. "$SCRIPT_DIR/common.sh"

print_label() {
    local count

    count=$("$FJORDWM_ROOT/scripts/updatecheck.sh" --count 2>/dev/null || printf '%s' "?")
    [[ -n "$count" ]] || count="?"
    printf '󰚰 %s\n' "$count"
}

case "${1:-label}" in
    label)
        print_label
        ;;
    run)
        "$FJORDWM_ROOT/scripts/updatecheck.sh" --update >/dev/null 2>&1 &
        disown
        ;;
    *)
        printf '%s\n' "Usage: updates.sh [label|run]" >&2
        exit 1
        ;;
esac
