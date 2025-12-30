#!/usr/bin/env bash
set -euo pipefail

BACKUP_DIR="$(pwd)/backups"

if [[ ! -d "$BACKUP_DIR" ]]; then
    echo "No backups directory found!"
    exit 1
fi

echo "Available backups:"
ls "$BACKUP_DIR" | sed 's/.tar.zst//'
echo
read -rp "Enter app names to restore (space-separated or 'all'): " SELECTION

for archive in "$BACKUP_DIR"/*.tar.zst; do
    APP="$(basename "$archive" .tar.zst)"

    if [[ "$SELECTION" != "all" && ! " $SELECTION " =~ " $APP " ]]; then
        continue
    fi

    echo "Restoring $APP..."
    tar --zstd -xpf "$archive"
    echo "✔ $APP restored"
done

echo "Restore completed."
