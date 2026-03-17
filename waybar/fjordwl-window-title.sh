#!/usr/bin/env bash
set -euo pipefail

if [[ -n "${XDG_RUNTIME_DIR:-}" ]]; then
  status_file="${XDG_RUNTIME_DIR}/fjordwl/waybar-window.json"
else
  status_file="/tmp/fjordwl-$(id -u)/waybar-window.json"
fi

default_state='{"text":"● No window yet","tooltip":"No active window","class":"no-window"}'

if [[ ! -f "$status_file" ]]; then
  printf '%s\n' "$default_state"
  exit 0
fi

if ! command -v jq >/dev/null 2>&1; then
  cat "$status_file"
  exit 0
fi

if ! jq -e . "$status_file" >/dev/null 2>&1; then
  printf '%s\n' "$default_state"
  exit 0
fi

text="$(jq -r '.text // ""' "$status_file")"
tooltip="$(jq -r '.tooltip // "No active window"' "$status_file")"
class_name="$(jq -r '.class // "active-window"' "$status_file")"

if [[ -z "${text// }" ]]; then
  printf '%s\n' "$default_state"
  exit 0
fi

text_json="$(jq -Rn --arg v "$text" '$v')"
tooltip_json="$(jq -Rn --arg v "$tooltip" '$v')"
class_json="$(jq -Rn --arg v "$class_name" '$v')"
printf '{"text":%s,"tooltip":%s,"class":%s}\n' "$text_json" "$tooltip_json" "$class_json"
