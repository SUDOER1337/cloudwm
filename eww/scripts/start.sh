#!/usr/bin/env bash
set -euo pipefail

SCRIPT_SOURCE=${BASH_SOURCE[0]:-$0}
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$SCRIPT_SOURCE")" && pwd)
# shellcheck source=common.sh
. "$SCRIPT_DIR/common.sh"

if ! command -v eww >/dev/null 2>&1; then
    exit 1
fi

eww_cmd daemon --restart >/dev/null 2>&1 || true
sleep 0.2

if ! eww_cmd ping >/dev/null 2>&1; then
    exit 1
fi

eww_cmd close-all >/dev/null 2>&1 || true

mapfile -t screens < <("$SCRIPT_DIR/monitors.sh")
if [[ ${#screens[@]} -eq 0 ]]; then
    screens=("0")
fi

opened=0
for screen in "${screens[@]}"; do
    window_id="bar-$(sanitize_id "$screen")"
    if eww_cmd open bar --id "$window_id" --screen "$screen" >/dev/null 2>&1; then
        opened=1
        continue
    fi

    if eww_cmd open bar --id "$window_id" >/dev/null 2>&1; then
        opened=1
    fi
done

if ((opened == 0)); then
    exit 1
fi
