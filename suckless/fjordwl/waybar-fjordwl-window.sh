#!/usr/bin/env bash
set -euo pipefail

if [[ -n "${XDG_RUNTIME_DIR:-}" ]]; then
  status_file="${XDG_RUNTIME_DIR}/fjordwl/waybar-window.json"
else
  status_file="/tmp/fjordwl-$(id -u)/waybar-window.json"
fi

if [[ -f "$status_file" ]]; then
  cat "$status_file"
else
  printf '%s\n' '{"text":"","tooltip":"","class":"empty"}'
fi
