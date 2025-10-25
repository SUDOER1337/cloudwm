#!/usr/bin/env bash

# --- CPU usage ---
read cpu user nice system idle iowait irq softirq steal guest < /proc/stat
total1=$((user + nice + system + idle + iowait + irq + softirq + steal))
idle1=$idle
sleep 0.5
read cpu user nice system idle iowait irq softirq steal guest < /proc/stat
total2=$((user + nice + system + idle + iowait + irq + softirq + steal))
idle2=$idle

usage=$((100 * ( (total2 - total1) - (idle2 - idle1) ) / (total2 - total1) ))

# --- CPU temp ---
temp_raw=$(sensors k10temp-pci-00c3 | awk '/Tctl/ {gsub(/\+|°C/,""); print int($2)}')
icon=""  # default

if [ "$temp_raw" -gt 95 ]; then icon=""
elif [ "$temp_raw" -gt 85 ]; then icon=""
elif [ "$temp_raw" -gt 70 ]; then icon=""
elif [ "$temp_raw" -gt 50 ]; then icon=""
fi

# --- Formatting with leading zeros ---
usage_fmt=$(printf "%02d" "$usage")
temp_fmt=$(printf "%02d" "$temp_raw")

# --- Output ---
echo "${usage_fmt}% ${temp_fmt}°C $icon"
