#!/usr/bin/env bash

## Author : SUDOER1337
## Github : ?
#
## Rofi   : Launcher (Modi Drun, Run, File Browser, Window)
#
## Available Styles
#
## style-1     style-2     style-3     style-4     style-5
## style-6     style-7     style-8     style-9     style-10
## style-11    style-12    style-13    style-14    style-15

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
ROFI_SCRIPT_DIR="$SCRIPT_DIR"
# shellcheck source=../scripts/rofi-common.sh
. "$SCRIPT_DIR/../scripts/rofi-common.sh"

THEME_PATH=$(rofi_theme_path "calc")
ROFI_CALC_HINT='Enter a qalc expression. The guide panel lists supported symbols, functions, and conversions.'

## Run
rofi \
    -mesg "$ROFI_CALC_HINT" \
    -show calc \
    $(rofi_vim_keybindings_text) \
    -theme "$THEME_PATH"
