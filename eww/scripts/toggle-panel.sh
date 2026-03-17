#!/usr/bin/env bash
set -euo pipefail

SCRIPT_SOURCE=${BASH_SOURCE[0]:-$0}
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$SCRIPT_SOURCE")" && pwd)
# shellcheck source=common.sh
. "$SCRIPT_DIR/common.sh"

panel=${1:-}

case "$panel" in
    control-panel)
        other_panel="power-panel"
        ;;
    power-panel)
        other_panel="control-panel"
        ;;
    close-all)
        eww_cmd close control-panel >/dev/null 2>&1 || true
        eww_cmd close power-panel >/dev/null 2>&1 || true
        exit 0
        ;;
    *)
        printf '%s\n' "Usage: toggle-panel.sh [control-panel|power-panel|close-all]" >&2
        exit 1
        ;;
esac

active=$(eww_cmd active-windows 2>/dev/null || true)
if printf '%s\n' "$active" | awk -F': ' '{print $2}' | grep -Fx "$panel" >/dev/null 2>&1; then
    eww_cmd close "$panel" >/dev/null 2>&1 || true
    exit 0
fi

mapfile -t screens < <("$SCRIPT_DIR/monitors.sh")
screen=${screens[0]:-0}

eww_cmd close "$other_panel" >/dev/null 2>&1 || true
if ! eww_cmd open "$panel" --screen "$screen" >/dev/null 2>&1; then
    eww_cmd open "$panel" >/dev/null 2>&1 || true
fi
