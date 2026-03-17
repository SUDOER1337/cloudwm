#!/usr/bin/env bash
set -euo pipefail

SCRIPT_SOURCE=${BASH_SOURCE[0]:-$0}
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$SCRIPT_SOURCE")" && pwd)
# shellcheck source=common.sh
. "$SCRIPT_DIR/common.sh"

icons=("󰇧" "" "" "󱌣" "󰍡" "󰠮")
tagmask=$(( (1 << ${#icons[@]}) - 1 ))

read -r occupied selected focused urgent <<<"$(read_state selected_tags "0 1 0 0")"

selected=${selected:-1}
occupied=${occupied:-0}
focused=${focused:-0}
urgent=${urgent:-0}

all_selected=0
if ((selected > tagmask)); then
    all_selected=1
fi

workspace_class() {
    local index=$1
    local bit=$2
    local class="workspace slot-$((index + 1))"

    if ((occupied & bit)); then
        class+=" is-occupied"
    else
        class+=" is-empty"
    fi
    if ((all_selected == 1 || (selected & bit))); then
        class+=" is-active"
    fi
    if ((focused & bit)); then
        class+=" has-focus"
    fi
    if ((urgent & bit)); then
        class+=" is-urgent"
    fi

    printf '%s' "$class"
}

printf '(box :class "workspace-strip" :spacing 4'
for index in "${!icons[@]}"; do
    bit=$((1 << index))
    class=$(workspace_class "$index" "$bit")

    printf ' (box :class "%s" :orientation "vertical" :spacing 4' "$class"
    printf ' (box :class "workspace-face" :orientation "horizontal" :spacing 6'
    printf ' (label :class "workspace-glyph" :text "%s")' "${icons[$index]}"
    printf ' (box :class "workspace-dot"))'
    printf ' (box :class "workspace-indicator"))'
done
printf ')\n'
