#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(pwd)"
BACKUP_DIR="$ROOT_DIR/backups"

if [[ ! -d "$BACKUP_DIR" ]]; then
    echo "No backups directory found."
    exit 1
fi

echo "Available backups:"
ls "$BACKUP_DIR" | grep '.tar.zst' | sed 's/.tar.zst//'
echo
read -rp "Enter app names to restore (space-separated or 'all'): " SELECTION

for archive in "$BACKUP_DIR"/*.tar.zst; do
    APP="$(basename "$archive" .tar.zst)"

    if [[ "$SELECTION" != "all" && ! " $SELECTION " =~ " $APP " ]]; then
        continue
    fi

    echo
    echo "=== Restoring $APP ==="

    tar --zstd -xpf "$archive"

    # --- VSCODIUM POST-RESTORE LOGIC ---
    if [[ "$APP" == "vscodium" ]]; then
        EXTRA_DIR="$BACKUP_DIR/vscodium-extra"

        if [[ -d "$EXTRA_DIR" && -f "$EXTRA_DIR/extensions.txt" ]]; then
            if command -v codium >/dev/null; then
                echo "Reinstalling VSCodium extensions..."
                while read -r ext; do
                    codium --install-extension "$ext" || true
                done < "$EXTRA_DIR/extensions.txt"
                echo "✔ Extensions restored"
            else
                echo "⚠ codium not installed — skipping extension restore"
                echo "  Install VSCodium and re-run restore.sh vscodium"
            fi
        else
            echo "⚠ No extension list found for VSCodium"
        fi
    fi
done

echo
echo "Restore completed."
