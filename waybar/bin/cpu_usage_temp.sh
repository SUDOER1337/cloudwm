#!/usr/bin/env bash
set -euo pipefail

read_cpu_line() {
  awk '/^cpu / {print $2, $3, $4, $5, $6, $7, $8, $9, $10, $11; exit}' /proc/stat
}

calc_cpu_usage() {
  local a1 b1 c1 d1 e1 f1 g1 h1 i1 j1
  local a2 b2 c2 d2 e2 f2 g2 h2 i2 j2
  read -r a1 b1 c1 d1 e1 f1 g1 h1 i1 j1 <<<"$(read_cpu_line)"
  sleep 0.2
  read -r a2 b2 c2 d2 e2 f2 g2 h2 i2 j2 <<<"$(read_cpu_line)"

  local idle1=$((d1 + e1))
  local idle2=$((d2 + e2))
  local total1=$((a1 + b1 + c1 + d1 + e1 + f1 + g1 + h1 + i1 + j1))
  local total2=$((a2 + b2 + c2 + d2 + e2 + f2 + g2 + h2 + i2 + j2))
  local dtotal=$((total2 - total1))
  local didle=$((idle2 - idle1))

  if (( dtotal <= 0 )); then
    echo 0
  else
    echo $(( (100 * (dtotal - didle)) / dtotal ))
  fi
}

read_temp() {
  local t
  t="$(sensors 2>/dev/null | awk '
    /Tctl:/ {gsub(/\+|°C/,"",$2); print int($2); exit}
    /Package id 0:/ {gsub(/\+|°C/,"",$4); print int($4); exit}
    /CPU:/ {gsub(/\+|°C/,"",$2); print int($2); exit}
  ')"
  if [[ -n "$t" ]]; then
    echo "$t"
  else
    echo "--"
  fi
}

usage="$(calc_cpu_usage)"
temp="$(read_temp)"

class_name="normal"
if [[ "$temp" =~ ^[0-9]+$ ]]; then
  if (( temp >= 85 )); then
    class_name="hot"
  elif (( temp >= 70 )); then
    class_name="warm"
  fi
fi

if [[ "$temp" =~ ^[0-9]+$ ]]; then
  text="  ${usage}% ${temp}"
  tooltip="CPU ${usage}% | Temp ${temp}"
else
  text="  ${usage}% --"
  tooltip="CPU ${usage}% | Temp unavailable"
fi

printf '{"text":"%s","tooltip":"%s","class":"%s"}\n' "$text" "$tooltip" "$class_name"
