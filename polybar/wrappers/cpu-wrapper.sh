#!/usr/bin/env bash
# Parse waybar cpu/temp script output and map to polybar color via %{F#HEX}...
SCRIPT="$HOME/fjordwm/waybar/bin/cpu_usage_temp.sh"
if [ -x "$SCRIPT" ]; then
    out=$($SCRIPT 2>/dev/null | tr -d '\n')
else
    # fallback: use /proc
    load=$(cut -d' ' -f1 /proc/loadavg 2>/dev/null || echo "0")
    temp=40
    out="CPU ${load} ${temp}C"
fi
# crude temp detection: find number followed by C
temp=$(echo "$out" | grep -oE "[0-9]{1,3}C" | tr -d 'C' | tail -n1 || true)
if [ -n "$temp" ]; then
    if [ "$temp" -ge 70 ]; then
        color="#ff5f5f"
    elif [ "$temp" -ge 55 ]; then
        color="#ffb454"
    else
        color="#C0AF8B"
    fi
    echo "%{F$color}$out%{F-}"
else
    echo "$out"
fi
