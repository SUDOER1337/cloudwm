#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "=============================="
echo "      DWM Build Script"
echo "=============================="
echo

PROFILES=(
    "desktop"
    "laptop"
)

echo "Select DWM build profile:"
select PROFILE in "${PROFILES[@]}"; do
    [[ -n "$PROFILE" ]] && break
done

SRC_DIR="$ROOT_DIR/cloudwm-$PROFILE"

if [[ ! -d "$SRC_DIR" ]]; then
    echo "❌ Source directory not found:"
    echo "  $SRC_DIR"
    exit 1
fi

if [[ ! -f "$SRC_DIR/config.h" ]]; then
    echo "❌ config.h missing in $SRC_DIR"
    exit 1
fi

echo
echo "Building DWM ($PROFILE profile)"
echo "Source: $SRC_DIR"
echo

cd "$SRC_DIR"

read -rp "Run 'sudo make clean install'? [y/N]: " CONFIRM
case "$CONFIRM" in
    y|Y|yes|YES)
        sudo make clean install
        ;;
    *)
        echo "Aborted."
        exit 0
        ;;
esac

echo
echo "✔ DWM ($PROFILE) installed successfully"
