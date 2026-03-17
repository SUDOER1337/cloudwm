#!/usr/bin/env bash
set -euo pipefail

SCRIPT_SOURCE=${BASH_SOURCE[0]:-$0}
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$SCRIPT_SOURCE")" && pwd)
# shellcheck source=common.sh
. "$SCRIPT_DIR/common.sh"

printed=0

if command -v wlr-randr >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    output=$(wlr-randr --json 2>/dev/null || true)
    if [[ -n "$output" ]]; then
        while IFS= read -r screen; do
            [[ -n "$screen" ]] || continue
            printf '%s\n' "$screen"
            printed=1
        done < <(
            printf '%s\n' "$output" | jq -r '
                (if type == "object" and has("outputs") then .outputs else . end)
                | map(select((.enabled // true) == true))
                | to_entries[]
                | .key
            ' 2>/dev/null
        )
    fi
fi

if ((printed == 0)); then
    printf '%s\n' "0"
fi
