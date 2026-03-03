#!/usr/bin/env bash

set -u

state_dir="${XDG_RUNTIME_DIR:-/tmp}"
state_file="${state_dir}/slstatus-cpu-${UID}.state"

# Read /proc/stat once and compute delta from the previous sample.
read -r _ user nice system idle iowait irq softirq steal _ < /proc/stat
total=$((user + nice + system + idle + iowait + irq + softirq + steal))
idle_total=$((idle + iowait))
usage=0

if [[ -r "$state_file" ]]; then
    read -r prev_total prev_idle < "$state_file" || true
    delta_total=$((total - prev_total))
    delta_idle=$((idle_total - prev_idle))
    if ((delta_total > 0)); then
        usage=$((100 * (delta_total - delta_idle) / delta_total))
        ((usage < 0)) && usage=0
        ((usage > 100)) && usage=100
    fi
fi
printf "%s %s\n" "$total" "$idle_total" > "$state_file"

# Prefer direct sysfs reads for temperature to avoid spawning sensors each tick.
temp_raw=""
for hw in /sys/class/hwmon/hwmon*; do
    [[ -r "$hw/name" ]] || continue
    read -r hw_name < "$hw/name"
    [[ "$hw_name" == "k10temp" ]] || continue
    for sensor in "$hw"/temp1_input "$hw"/temp2_input "$hw"/temp3_input; do
        if [[ -r "$sensor" ]]; then
            read -r milli_c < "$sensor"
            temp_raw=$((milli_c / 1000))
            break 2
        fi
    done
done

if [[ -z "$temp_raw" && -r /sys/class/thermal/thermal_zone0/temp ]]; then
    read -r milli_c < /sys/class/thermal/thermal_zone0/temp
    temp_raw=$((milli_c / 1000))
fi
[[ -z "$temp_raw" ]] && temp_raw=0

icon=""
if ((temp_raw > 95)); then
    icon=""
elif ((temp_raw > 85)); then
    icon=""
elif ((temp_raw > 70)); then
    icon=""
fi

printf "%02d%% %02d°C %s\n" "$usage" "$temp_raw" "$icon"
