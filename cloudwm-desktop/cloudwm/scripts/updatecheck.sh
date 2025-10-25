#!/usr/bin/env bash

set -e

# Tool check
check() {
  command -v "$1" &>/dev/null
}

notify() {
  check notify-send && notify-send -a "UpdateCheck" "$@" || echo "$@"
}

stringToLen() {
  local str="$1"
  local len="$2"
  if [ ${#str} -gt "$len" ]; then
    echo "${str:0:$((len - 2))}.."
  else
    printf "%-${len}s" "$str"
  fi
}

if [[ "$1" == "--count" ]]; then
  cache_file="/tmp/update_count.txt"
  # If cache exists and is <10 minutes old, use it
  if [[ -f "$cache_file" ]] && [[ $(($(date +%s) - $(stat -c %Y "$cache_file"))) -lt 600 ]]; then
      cat "$cache_file"
      exit 0
  fi

  # Otherwise recalc in background and cache it
  (
    mapfile -t updates < <(checkupdates --nocolor 2>/dev/null || true)
    mapfile -t aur_updates < <(pacman -Qm | aur vercmp 2>/dev/null || true)
    mapfile -t flatpak_updates < <(flatpak remote-ls --updates --columns=application 2>/dev/null || true)
    total_count=$(( ${#updates[@]} + ${#aur_updates[@]} + ${#flatpak_updates[@]} ))
    echo "$total_count" > "$cache_file"
  ) &
  
  # Print last known value or “?” if nothing cached yet
  if [[ -f "$cache_file" ]]; then
    cat "$cache_file"
  else
    echo "?"
  fi
  exit 0
fi



# Action: --check
if [[ "$1" == "--check" ]]; then
  notify "Checking for updates..."
fi

# Action: --update
if [[ "$1" == "--update" ]]; then
  notify "Running system updates..."
  kitty -e bash -c 'paru -Syu && flatpak update; read -n 1 -s -r -p "Press any key to close..."'
  exit 0
fi

# Check required tools
check aur || { notify "aurutils is missing"; exit 1; }
check checkupdates || { notify "pacman-contrib is missing"; exit 1; }

IFS=$'\n'$'\r'

# Kill previous checkupdates instance if any
killall -q checkupdates || true

# Get Arch/AUR updates
cup() {
  checkupdates --nocolor
  pacman -Qm | aur vercmp
}
mapfile -t updates < <(cup)

# Get Flatpak updates
flatpak_updates=()
if check flatpak; then
  mapfile -t flatpak_updates < <(flatpak remote-ls --updates --columns=application 2>/dev/null)
fi

# Display summary
update_count=$(( ${#updates[@]} + ${#flatpak_updates[@]} ))
echo "Total updates available: $update_count"

# Arch/AUR updates
if [ "${#updates[@]}" -gt 0 ]; then
  echo -e "\nArch/AUR Updates:"
  printf "%-20s %-15s %-15s\n" "Package" "Current" "Available"
  for i in "${updates[@]}"; do
    pkg="$(stringToLen "$(echo "$i" | awk '{print $1}')" 20)"
    prev="$(stringToLen "$(echo "$i" | awk '{print $2}')" 15)"
    next="$(stringToLen "$(echo "$i" | awk '{print $4}')" 15)"
    printf "%-20s %-15s %-15s\n" "$pkg" "$prev" "$next"
  done
fi

# Flatpak updates
if [ "${#flatpak_updates[@]}" -gt 0 ]; then
  echo -e "\nFlatpak Updates:"
  for app in "${flatpak_updates[@]}"; do
    echo "• $app"
  done
fi

