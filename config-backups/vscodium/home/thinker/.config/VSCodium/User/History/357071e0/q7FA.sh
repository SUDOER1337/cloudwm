#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="$(pwd)/backups/vscodium-extra"
mkdir -p "$OUT_DIR"

if command -v codium >/dev/null; then
    echo "Exporting VSCodium extensions list..."
    codium --list-extensions > "$OUT_DIR/extensions.txt"
    codium --list-extensions --show-versions > "$OUT_DIR/extensions-with-versions.txt"
else
    echo "codium command not found, skipping extension export"
fi
