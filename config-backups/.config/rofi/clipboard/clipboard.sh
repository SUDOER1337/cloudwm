#!/usr/bin/env bash
set -euo pipefail

THEME_PATH="$HOME/.config/rofi/clipboard/clipboard.rasi"

exec clipman pick -t rofi --tool-args="-theme $THEME_PATH"
