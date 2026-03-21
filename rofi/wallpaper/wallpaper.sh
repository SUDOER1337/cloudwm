#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
SELF="$SCRIPT_DIR/wallpaper.sh"
ROFI_SCRIPT_DIR="$SCRIPT_DIR"
# shellcheck source=../scripts/rofi-common.sh
. "$SCRIPT_DIR/../scripts/rofi-common.sh"

# Customizable image sources. Override with:
#   WALLPAPER_DIRS="$HOME/fjordwm/wallpapers:$HOME/Pictures/Wallpapers"
DEFAULT_WALLPAPER_DIRS=(
  "$HOME/fjordwm/wallpapers"
  "$HOME/Pictures/Wallpapers"
)

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/wallpaper-picker"
PID_FILE="$CACHE_DIR/shuffle.pid"
ROFI_THEME="${ROFI_THEME:-$(rofi_theme_path "wallpaper")}"
FEH_OPTS="${FEH_OPTS:---bg-fill}"
SHUFFLE_INTERVAL="${SHUFFLE_INTERVAL:-530}"
SHUFFLE_RETRY_DELAY="${SHUFFLE_RETRY_DELAY:-60}"

WALLPAPER_FILES=()

notify() {
  local title=$1
  local body=$2

  if command -v notify-send >/dev/null 2>&1; then
    notify-send "$title" "$body" >/dev/null 2>&1 || printf '%s: %s\n' "$title" "$body" >&2
  else
    printf '%s: %s\n' "$title" "$body" >&2
  fi
}

require_command() {
  local command_name=$1

  if ! command -v "$command_name" >/dev/null 2>&1; then
    printf '%s\n' "Missing required command: $command_name" >&2
    exit 1
  fi
}

require_graphical_session() {
  if fjordwm_is_wayland_session; then
    if [ -z "${WAYLAND_DISPLAY:-}" ] && [ -z "${DISPLAY:-}" ]; then
      printf '%s\n' "No active Wayland session found." >&2
      exit 1
    fi
    return
  fi

  if [ -z "${DISPLAY:-}" ]; then
    printf '%s\n' "DISPLAY is not set. Launch wallpaper.sh from your X session." >&2
    exit 1
  fi

  if command -v xset >/dev/null 2>&1 && ! xset q >/dev/null 2>&1; then
    printf '%s\n' "Cannot access the X display in DISPLAY=$DISPLAY." >&2
    exit 1
  fi
}

require_wallpaper_backend() {
  if fjordwm_is_wayland_session; then
    if command -v swww >/dev/null 2>&1 || command -v swaybg >/dev/null 2>&1; then
      return 0
    fi

    printf '%s\n' "Missing Wayland wallpaper backend: install swww or swaybg." >&2
    exit 1
  fi

  require_command feh
}

ensure_swww_daemon() {
  local attempt

  if ! pgrep -u "$UID" -x swww-daemon >/dev/null 2>&1; then
    swww-daemon >/dev/null 2>&1 &
    disown
  fi

  for attempt in 1 2 3 4 5; do
    if swww query >/dev/null 2>&1; then
      return 0
    fi
    sleep 0.2
  done

  printf '%s\n' "swww-daemon did not become ready." >&2
  exit 1
}

set_wayland_wallpaper() {
  local wallpaper=$1

  if command -v swww >/dev/null 2>&1; then
    ensure_swww_daemon
    swww img "$wallpaper" \
      --transition-type simple \
      --transition-duration 1 >/dev/null 2>&1
    return 0
  fi

  pkill -u "$UID" -x swaybg >/dev/null 2>&1 || true
  swaybg -i "$wallpaper" -m fill >/dev/null 2>&1 &
  disown
}

set_x11_wallpaper() {
  local wallpaper=$1
  local -a feh_args=()

  if [ -n "$FEH_OPTS" ]; then
    read -r -a feh_args <<< "$FEH_OPTS"
  fi

  feh "${feh_args[@]}" "$wallpaper"
}

pretty_path() {
  case $1 in
    "$HOME")
      printf '%s\n' "~"
      ;;
    "$HOME"/*)
      printf '~/%s\n' "${1#"$HOME"/}"
      ;;
    *)
      printf '%s\n' "$1"
      ;;
  esac
}

get_wallpaper_dirs() {
  local -a configured_dirs=()
  local dir

  if [ -n "${WALLPAPER_DIRS:-}" ]; then
    IFS=':' read -r -a configured_dirs <<< "$WALLPAPER_DIRS"
  else
    configured_dirs=("${DEFAULT_WALLPAPER_DIRS[@]}")
  fi

  for dir in "${configured_dirs[@]}"; do
    [ -d "$dir" ] || continue
    printf '%s\n' "$dir"
  done
}

describe_wallpaper_dirs() {
  local -a active_dirs=()
  local formatted_dirs=()
  local dir

  mapfile -t active_dirs < <(get_wallpaper_dirs)

  if [ ${#active_dirs[@]} -eq 0 ]; then
    printf '%s\n' "No wallpaper directories found"
    return
  fi

  for dir in "${active_dirs[@]}"; do
    formatted_dirs+=("$(pretty_path "$dir")")
  done

  local joined=""
  for dir in "${formatted_dirs[@]}"; do
    if [ -n "$joined" ]; then
      joined="$joined, "
    fi
    joined="$joined$dir"
  done

  printf '%s\n' "$joined"
}

collect_wallpapers() {
  local -a active_dirs=()
  local wallpaper

  WALLPAPER_FILES=()
  mapfile -t active_dirs < <(get_wallpaper_dirs)

  [ ${#active_dirs[@]} -gt 0 ] || return 1

  while IFS= read -r -d '' wallpaper; do
    WALLPAPER_FILES+=("$wallpaper")
  done < <(
    find "${active_dirs[@]}" -type f \
      \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' -o -iname '*.bmp' -o -iname '*.gif' \) \
      ! -name '*~' \
      -print0 2>/dev/null
  )

  [ ${#WALLPAPER_FILES[@]} -gt 0 ]
}

shuffle_pid() {
  [ -f "$PID_FILE" ] || return 1

  local pid
  IFS= read -r pid < "$PID_FILE" || return 1

  case $pid in
    ''|*[!0-9]*)
      rm -f "$PID_FILE"
      return 1
      ;;
  esac

  printf '%s\n' "$pid"
}

is_shuffle_running() {
  local pid
  local command_line

  pid="$(shuffle_pid)" || return 1
  command_line="$(ps -p "$pid" -o args= 2>/dev/null || true)"

  case $command_line in
    *"wallpaper.sh shuffle-daemon"*)
      return 0
      ;;
    *)
      rm -f "$PID_FILE"
      return 1
      ;;
  esac
}

shuffle_status() {
  if is_shuffle_running; then
    printf 'Shuffle : running every %ss\n' "$SHUFFLE_INTERVAL"
  else
    printf '%s\n' "Shuffle : stopped"
  fi
}

run_rofi_index() {
  local prompt=$1
  local message=${2:-}
  local -a rofi_cmd=(
    rofi
    -dmenu
    -i
    -no-custom
    -format
    i
    -p
    "$prompt"
    $(rofi_vim_keybindings_selection)
    -theme
    "$ROFI_THEME"
  )

  require_command rofi
  require_graphical_session

  if [ -n "$message" ]; then
    rofi_cmd+=(-mesg "$message")
  fi

  "${rofi_cmd[@]}"
}

set_wallpaper() {
  local wallpaper=$1

  require_graphical_session
  require_wallpaper_backend

  if fjordwm_is_wayland_session; then
    set_wayland_wallpaper "$wallpaper"
  else
    set_x11_wallpaper "$wallpaper"
  fi
}

random_wallpaper_file() {
  local previous_wallpaper=${1:-}
  local random_index
  local candidate

  if [ ${#WALLPAPER_FILES[@]} -eq 0 ]; then
    return 1
  fi

  if [ ${#WALLPAPER_FILES[@]} -eq 1 ] || [ -z "$previous_wallpaper" ]; then
    random_index=$((RANDOM % ${#WALLPAPER_FILES[@]}))
    printf '%s\n' "${WALLPAPER_FILES[$random_index]}"
    return 0
  fi

  while :; do
    random_index=$((RANDOM % ${#WALLPAPER_FILES[@]}))
    candidate="${WALLPAPER_FILES[$random_index]}"

    [ "$candidate" != "$previous_wallpaper" ] && {
      printf '%s\n' "$candidate"
      return 0
    }
  done
}

stop_shuffle() {
  local quiet=${1:-0}
  local pid

  if ! is_shuffle_running; then
    [ "$quiet" -eq 1 ] || notify "Wallpaper" "Shuffle is not running."
    return 0
  fi

  pid="$(shuffle_pid)"
  kill "$pid" 2>/dev/null || true
  rm -f "$PID_FILE"

  [ "$quiet" -eq 1 ] || notify "Wallpaper" "Shuffle stopped."
}

apply_selected_wallpaper() {
  local wallpaper=$1

  stop_shuffle 1
  set_wallpaper "$wallpaper"
  notify "Wallpaper" "Set $(basename "$wallpaper")"
}

pick_wallpaper() {
  local -a menu_entries=()
  local wallpaper
  local index

  if ! collect_wallpapers; then
    notify "Wallpaper" "No wallpapers found in configured directories."
    return 1
  fi

  for wallpaper in "${WALLPAPER_FILES[@]}"; do
    menu_entries+=("$(basename "$wallpaper")  [$(pretty_path "$(dirname "$wallpaper")")]")
  done

  index="$(printf '%s\n' "${menu_entries[@]}" | run_rofi_index "Pick wallpaper" "Sources : $(describe_wallpaper_dirs)")" || return 0
  [ -n "$index" ] || return 0

  apply_selected_wallpaper "${WALLPAPER_FILES[$index]}"
}

set_random_wallpaper() {
  local wallpaper

  if ! collect_wallpapers; then
    notify "Wallpaper" "No wallpapers found in configured directories."
    return 1
  fi

  wallpaper="$(random_wallpaper_file)"
  apply_selected_wallpaper "$wallpaper"
}

cleanup_shuffle_pid() {
  local pid=""

  pid="$(shuffle_pid 2>/dev/null || true)"
  [ "$pid" = "$$" ] && rm -f "$PID_FILE"
}

shuffle_daemon() {
  local previous_wallpaper=""
  local wallpaper

  mkdir -p "$CACHE_DIR"
  printf '%s\n' "$$" > "$PID_FILE"
  trap cleanup_shuffle_pid EXIT INT TERM HUP

  while :; do
    if ! collect_wallpapers; then
      sleep "$SHUFFLE_RETRY_DELAY"
      continue
    fi

    wallpaper="$(random_wallpaper_file "$previous_wallpaper")"
    previous_wallpaper="$wallpaper"
    set_wallpaper "$wallpaper"

    sleep "$SHUFFLE_INTERVAL" &
    wait "$!" || true
  done
}

start_shuffle() {
  mkdir -p "$CACHE_DIR"

  if is_shuffle_running; then
    notify "Wallpaper" "Shuffle is already running."
    return 0
  fi

  require_graphical_session
  require_wallpaper_backend

  if ! collect_wallpapers; then
    notify "Wallpaper" "No wallpapers found in configured directories."
    return 1
  fi

  nohup "$SELF" shuffle-daemon >/dev/null 2>&1 &
  notify "Wallpaper" "Shuffle started."
}

show_menu() {
  local -a actions=(
    "Pick wallpaper"
    "Random wallpaper"
    "Start shuffle"
    "Stop shuffle"
  )
  local status_message
  local index

  status_message="$(shuffle_status)"
  status_message="$status_message"$'\n'"Sources : $(describe_wallpaper_dirs)"

  index="$(printf '%s\n' "${actions[@]}" | run_rofi_index "Wallpaper" "$status_message")" || exit 0
  [ -n "$index" ] || exit 0

  case $index in
    0) pick_wallpaper ;;
    1) set_random_wallpaper ;;
    2) start_shuffle ;;
    3) stop_shuffle ;;
    *) exit 1 ;;
  esac
}

usage() {
  cat <<'EOF'
Usage: wallpaper.sh [menu|pick|random|shuffle-start|shuffle-stop|shuffle-daemon]
EOF
}

case "${1:-menu}" in
  menu)
    show_menu
    ;;
  pick)
    pick_wallpaper
    ;;
  random)
    set_random_wallpaper
    ;;
  shuffle-start)
    start_shuffle
    ;;
  shuffle-stop)
    stop_shuffle
    ;;
  shuffle-daemon)
    shuffle_daemon
    ;;
  *)
    usage >&2
    exit 1
    ;;
esac
