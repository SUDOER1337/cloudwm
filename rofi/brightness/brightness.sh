#!/usr/bin/env bash

set -euo pipefail

SCRIPT_SOURCE=${BASH_SOURCE[0]:-$0}
SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$SCRIPT_SOURCE")" && pwd)
ROFI_SCRIPT_DIR="$SCRIPT_DIR"
# shellcheck source=../scripts/rofi-common.sh
. "$SCRIPT_DIR/../scripts/rofi-common.sh"

: "${ROFI_THEME:=$(rofi_theme_path "brightness")}"

STEP_SIZE=5
BRIGHTNESS_MIN=0
BRIGHTNESS_MAX=100

declare -a TARGET_TYPES=()
declare -a TARGET_SELECTOR_KINDS=()
declare -a TARGET_SELECTOR_VALUES=()
declare -a TARGET_NAMES=()
declare -a TARGET_HINTS=()
declare -a TARGET_CURRENTS=()

DDC_DISPLAY_ID=""
DDC_BUS=""
DDC_MONITOR=""
DDC_MODEL=""
DDC_CONNECTOR=""

rofi_cmd() {
    rofi -theme "$ROFI_THEME" $(rofi_vim_keybindings_text) "$@"
}

show_error() {
    rofi -e "$1"
}

trim() {
    local value=$1

    value=${value#"${value%%[![:space:]]*}"}
    value=${value%"${value##*[![:space:]]}"}
    printf '%s' "$value"
}

clamp_percentage() {
    local value=$1

    if [ "$value" -lt "$BRIGHTNESS_MIN" ]; then
        value=$BRIGHTNESS_MIN
    elif [ "$value" -gt "$BRIGHTNESS_MAX" ]; then
        value=$BRIGHTNESS_MAX
    fi

    printf '%s\n' "$value"
}

extract_bus_number() {
    local bus_path=$1
    local bus_number=${bus_path##*-}

    [[ $bus_number =~ ^[0-9]+$ ]] || return 1
    printf '%s\n' "$bus_number"
}

brightness_icon() {
    local value=$1

    if [ "$value" -le 0 ]; then
        printf '%s' "󰃞"
    elif [ "$value" -lt 35 ]; then
        printf '%s' "󰃟"
    elif [ "$value" -lt 75 ]; then
        printf '%s' "󰃠"
    else
        printf '%s' "󰃡"
    fi
}

step_caption() {
    local value=$1

    case "$value" in
        0) printf '%s' "Night" ;;
        25) printf '%s' "Dim" ;;
        50) printf '%s' "Balanced" ;;
        75) printf '%s' "Bright" ;;
        100) printf '%s' "Full" ;;
        *) return 1 ;;
    esac
}

step_label() {
    local value=$1
    local icon caption

    icon=$(brightness_icon "$value")
    printf '%s  %3d%%' "$icon" "$value"
    if caption=$(step_caption "$value"); then
        printf '  ·  %s' "$caption"
    fi
    printf '\n'
}

add_target() {
    TARGET_TYPES+=("$1")
    TARGET_SELECTOR_KINDS+=("$2")
    TARGET_SELECTOR_VALUES+=("$3")
    TARGET_NAMES+=("$4")
    TARGET_HINTS+=("$5")
    TARGET_CURRENTS+=("$6")
}

read_brightnessctl_brightness() {
    local current max

    current=$(brightnessctl g 2>/dev/null) || return 1
    max=$(brightnessctl m 2>/dev/null) || return 1

    [[ $current =~ ^[0-9]+$ ]] || return 1
    [[ $max =~ ^[0-9]+$ ]] || return 1
    [ "$max" -gt 0 ] || return 1

    clamp_percentage $(( current * BRIGHTNESS_MAX / max ))
}

apply_brightnessctl_brightness() {
    local value=$1

    brightnessctl set "${value}%" >/dev/null 2>&1
}

parse_ddcutil_percentage() {
    local output=$1
    local current max

    current=$(printf '%s\n' "$output" | sed -n 's/.*current value = *\([0-9][0-9]*\).*/\1/p' | head -n 1)
    max=$(printf '%s\n' "$output" | sed -n 's/.*max value = *\([0-9][0-9]*\).*/\1/p' | head -n 1)

    [[ $current =~ ^[0-9]+$ ]] || return 1

    if [[ $max =~ ^[0-9]+$ ]] && [ "$max" -gt 0 ] && [ "$max" -ne "$BRIGHTNESS_MAX" ]; then
        current=$(( current * BRIGHTNESS_MAX / max ))
    fi

    clamp_percentage "$current"
}

read_ddcutil_brightness() {
    local selector_kind=$1
    local selector_value=$2
    local output

    if [ "$selector_kind" = "bus" ]; then
        output=$(ddcutil --bus "$selector_value" getvcp 10 2>/dev/null) || return 1
    else
        output=$(ddcutil --display "$selector_value" getvcp 10 2>/dev/null) || return 1
    fi

    parse_ddcutil_percentage "$output"
}

apply_ddcutil_brightness() {
    local selector_kind=$1
    local selector_value=$2
    local value=$3

    if [ "$selector_kind" = "bus" ]; then
        ddcutil --bus "$selector_value" setvcp 10 "$value" >/dev/null 2>&1
    else
        ddcutil --display "$selector_value" setvcp 10 "$value" >/dev/null 2>&1
    fi
}

reset_ddc_target_fields() {
    DDC_DISPLAY_ID=""
    DDC_BUS=""
    DDC_MONITOR=""
    DDC_MODEL=""
    DDC_CONNECTOR=""
}

maybe_add_ddc_target() {
    local selector_kind selector_value current name hint bus_hint

    [ -n "$DDC_DISPLAY_ID" ] || return 0

    selector_kind="display"
    selector_value=$DDC_DISPLAY_ID
    if [ -n "$DDC_BUS" ]; then
        selector_kind="bus"
        selector_value=$DDC_BUS
    fi

    if ! current=$(read_ddcutil_brightness "$selector_kind" "$selector_value"); then
        return 0
    fi

    if [ -n "$DDC_MONITOR" ]; then
        name=$DDC_MONITOR
    elif [ -n "$DDC_MODEL" ]; then
        name=$DDC_MODEL
    else
        name="External display $DDC_DISPLAY_ID"
    fi

    bus_hint=""
    if [ -n "$DDC_BUS" ]; then
        bus_hint="I2C ${DDC_BUS}"
    fi

    hint=${DDC_CONNECTOR:-$bus_hint}
    add_target "ddcutil" "$selector_kind" "$selector_value" "$name" "$hint" "$current"
}

discover_ddcutil_targets() {
    local detect_output line bus_path bus_number

    command -v ddcutil >/dev/null 2>&1 || return 0
    if ! detect_output=$(ddcutil detect 2>/dev/null); then
        return 0
    fi

    [ -n "$detect_output" ] || return 0
    reset_ddc_target_fields

    while IFS= read -r line; do
        case "$line" in
            Display\ *)
                maybe_add_ddc_target
                reset_ddc_target_fields
                DDC_DISPLAY_ID=$(trim "${line#Display }")
                DDC_DISPLAY_ID=${DDC_DISPLAY_ID%% *}
                ;;
            Invalid\ display*)
                maybe_add_ddc_target
                reset_ddc_target_fields
                ;;
            *I2C\ bus:*)
                bus_path=$(trim "${line#*:}")
                if bus_number=$(extract_bus_number "$bus_path"); then
                    DDC_BUS=$bus_number
                fi
                ;;
            *Monitor\ name:*)
                DDC_MONITOR=$(trim "${line#*:}")
                ;;
            *Model:*)
                DDC_MODEL=$(trim "${line#*:}")
                ;;
            *DRM\ connector:*|*DRM_connector:*)
                DDC_CONNECTOR=$(trim "${line#*:}")
                ;;
        esac
    done <<< "$detect_output"

    maybe_add_ddc_target
}

discover_brightnessctl_target() {
    local current

    command -v brightnessctl >/dev/null 2>&1 || return 0
    if ! current=$(read_brightnessctl_brightness); then
        return 0
    fi

    add_target "brightnessctl" "internal" "default" "Internal display" "Laptop panel" "$current"
}

target_icon() {
    local target_type=$1

    case "$target_type" in
        ddcutil) printf '%s' "󰍹" ;;
        brightnessctl) printf '%s' "󰃟" ;;
        *) printf '%s' "󰃠" ;;
    esac
}

target_label() {
    local index=$1
    local current=${TARGET_CURRENTS[$index]}
    local icon hint

    icon=$(target_icon "${TARGET_TYPES[$index]}")
    hint=${TARGET_HINTS[$index]}

    printf '%s  %s' "$icon" "${TARGET_NAMES[$index]}"
    if [ -n "$hint" ]; then
        printf '  ·  %s' "$hint"
    fi
    printf '  ·  %s%%\n' "$current"
}

target_current() {
    local index=$1

    case "${TARGET_TYPES[$index]}" in
        ddcutil)
            read_ddcutil_brightness "${TARGET_SELECTOR_KINDS[$index]}" "${TARGET_SELECTOR_VALUES[$index]}"
            ;;
        brightnessctl)
            read_brightnessctl_brightness
            ;;
        *)
            return 1
            ;;
    esac
}

apply_target_brightness() {
    local index=$1
    local value=$2

    case "${TARGET_TYPES[$index]}" in
        ddcutil)
            apply_ddcutil_brightness "${TARGET_SELECTOR_KINDS[$index]}" "${TARGET_SELECTOR_VALUES[$index]}" "$value"
            ;;
        brightnessctl)
            apply_brightnessctl_brightness "$value"
            ;;
        *)
            return 1
            ;;
    esac
}

choose_target() {
    local selection
    local index
    local -a rows=()

    if [ "${#TARGET_TYPES[@]}" -eq 1 ]; then
        printf '%s\n' "0"
        return 0
    fi

    for ((index = 0; index < ${#TARGET_TYPES[@]}; index++)); do
        rows+=("$(target_label "$index")")
    done

                -${single_newline}
    if ! selection=$(printf '%s\n' "${rows[@]}" | rofi_cmd -dmenu -i -format i -only-match -p "󰍹  Display" -mesg "Choose which display to control."); then
        return 1
    fi

    [ -n "$selection" ] || return 1
    printf '%s\n' "$selection"
}

nearest_step_index() {
    local current=$1
    local max_index=$(( (BRIGHTNESS_MAX - BRIGHTNESS_MIN) / STEP_SIZE ))
    local index=$(( (current + (STEP_SIZE / 2)) / STEP_SIZE ))

    if [ "$index" -lt 0 ]; then
        index=0
    elif [ "$index" -gt "$max_index" ]; then
        index=$max_index
    fi

    printf '%s\n' "$index"
}

resolve_brightness_input() {
    local selection
    local value

    selection=$(trim "$1")
    [ -n "$selection" ] || return 1

    if [[ $selection =~ ^-?[0-9]+$ ]]; then
        value=$selection
    else
        value=$(printf '%s\n' "$selection" | sed -n 's/^[^0-9-]*\(-\?[0-9][0-9]*\).*/\1/p' | head -n 1)
    fi

    [[ $value =~ ^-?[0-9]+$ ]] || return 1
    clamp_percentage "$value"
}

choose_brightness() {
    local index=$1
    local current selection active_row message value
    local -a rows=()

    if ! current=$(target_current "$index"); then
        current=${TARGET_CURRENTS[$index]:-}
    fi

    [[ $current =~ ^[0-9]+$ ]] || {
        show_error "Unable to read the current brightness for ${TARGET_NAMES[$index]}."
        return 2
    }

    TARGET_CURRENTS[$index]=$current
    active_row=$(nearest_step_index "$current")
    message="${TARGET_NAMES[$index]} · current ${current}% · choose a step or type 0-100 and press Enter."

    for ((value = BRIGHTNESS_MIN; value <= BRIGHTNESS_MAX; value += STEP_SIZE)); do
        rows+=("$(step_label "$value")")
    done

    if ! selection=$(printf '%s\n' "${rows[@]}" | rofi_cmd -dmenu -i -selected-row "$active_row" -a "$active_row" -p "󰃠  Brightness" -mesg "$message"); then
        return 1
    fi

    if ! resolve_brightness_input "$selection"; then
        show_error "Brightness must be a whole number between 0 and 100."
        return 2
    fi
}

main() {
    local target_index new_value status

    discover_ddcutil_targets
    discover_brightnessctl_target

    if [ "${#TARGET_TYPES[@]}" -eq 0 ]; then
        show_error "No supported brightness device found (ddcutil or brightnessctl)."
        exit 1
    fi

    if ! target_index=$(choose_target); then
        exit 0
    fi

    if ! new_value=$(choose_brightness "$target_index"); then
        status=$?
        if [ "$status" -eq 1 ]; then
            exit 0
        fi
        exit "$status"
    fi

    if ! apply_target_brightness "$target_index" "$new_value"; then
        show_error "Failed to set brightness for ${TARGET_NAMES[$target_index]}."
        exit 1
    fi
}

main "$@"
