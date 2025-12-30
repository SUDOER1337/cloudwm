#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "=============================="
echo "   Suckless Build Script"
echo "=============================="
echo

PROFILES=("desktop" "laptop")

echo "Select build profile:"
select PROFILE in "${PROFILES[@]}"; do
    [[ -n "$PROFILE" ]] && break
done

build() {
    local name="$1"
    local dir="$ROOT_DIR/$name-$PROFILE"

    if [[ ! -d "$dir" ]]; then
        echo "󰒬  Skipping $name (no $dir)"
        return
    fi

    if [[ ! -f "$dir/config.h" ]]; then
        echo "⚠  $name: config.h missing, skipping"
        return
    fi

    echo
    echo "🔨 Building $name ($PROFILE)"
    echo "   $dir"

    cd "$dir"
    sudo make clean install
}

build cloudwm     # dwm
build slstatus
build slock

echo
echo "✔ All available suckless tools built"
