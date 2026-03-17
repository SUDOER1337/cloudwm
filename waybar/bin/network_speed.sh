#!/usr/bin/env bash
set -euo pipefail

# Determine interface: prefer env NETWORK_IFACE, else use routing, else first carrier=1
IFACE="${NETWORK_IFACE:-$(ip route get 1.1.1.1 2>/dev/null | awk '/dev/{for(i=1;i<=NF;i++) if($i=="dev"){print $(i+1); exit}}')}"
if [ -z "$IFACE" ]; then
  for d in /sys/class/net/*; do
    [ -e "$d/carrier" ] || continue
    carrier=$(cat "$d/carrier" 2>/dev/null || echo 0)
    if [ "$carrier" = "1" ]; then
      IFACE=$(basename "$d")
      break
    fi
  done
fi

[ -n "$IFACE" ] || exit 0
now=$(date +%s)
rx=$(cat /sys/class/net/$IFACE/statistics/rx_bytes 2>/dev/null || echo 0)
tx=$(cat /sys/class/net/$IFACE/statistics/tx_bytes 2>/dev/null || echo 0)
prevfile="/tmp/net_speed_${IFACE}.prev"
if [ -f "$prevfile" ]; then
  read prev_rx prev_tx prev_time < "$prevfile"
else
  prev_rx=$rx; prev_tx=$tx; prev_time=$now
fi
dt=$((now - prev_time))
[ "$dt" -le 0 ] && dt=1
# bits per second
drx=$(( (rx - prev_rx) * 8 / dt ))
dtx=$(( (tx - prev_tx) * 8 / dt ))

human() {
  val=$1
  if [ "$val" -ge 1000000 ]; then
    awk -v v=$val 'BEGIN{printf("%.1fM", v/1000000)}'
  elif [ "$val" -ge 1000 ]; then
    awk -v v=$val 'BEGIN{printf("%.1fk", v/1000)}'
  else
    printf "%db" "$val"
  fi
}

# Print download speed with icon to match Waybar intent
printf "󰛴 %s\n" "$(human $drx)"
# Save current counters
printf "%s %s %s\n" "$rx" "$tx" "$now" > "$prevfile"
