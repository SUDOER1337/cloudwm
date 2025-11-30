WALLDIR="$HOME/cloudwm/wallpapers/"   # change to your folder
INTERVAL=530                          # seconds between swaps
FEH_MODE="--bg-fill"                  # --bg-fill / --bg-scale / etc.
# ---------------------------

set -euo pipefail

while true; do
  # get shuffled list
  mapfile -t IMGS < <(find "$WALLDIR" -type f | shuf)

  # nothing? wait and retry
  [ "${#IMGS[@]}" -eq 0 ] && sleep 60 && continue

  # loop through each image
  for img in "${IMGS[@]}"; do
    # kill any existing feh instances
    pkill -x feh 2>/dev/null || true

    # set new wallpaper
    feh $FEH_MODE --no-fehbg "$img" 2>/dev/null

    sleep "$INTERVAL"
  done
done

