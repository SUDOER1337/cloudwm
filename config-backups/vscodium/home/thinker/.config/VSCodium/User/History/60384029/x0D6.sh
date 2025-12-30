#!/usr/bin/env bash
set -euo pipefail

BACKUP_DIR="$(pwd)/backups"
CONF_FILE="$(pwd)/apps.conf"

mkdir -p "$BACKUP_DIR"

if [[ ! -f "$CONF_FILE" ]]; then
    echo "apps.conf not found!"
    exit 1
fi

echo "Available apps:"
grep -v '^#' "$CONF_FILE" | cut -d= -f1
echo
read -rp "Enter app names to backup (space-separated or 'all'): " SELECTION

mapfile -t APPS < <(grep -v '^#' "$CONF_FILE")

for line in "${APPS[@]}"; do
    APP="${line%%=*}"
    PATHS="${line#*=}"

    if [[ "$SELECTION" != "all" && ! " $SELECTION " =~ " $APP " ]]; then
        continue
    fi

    ARCHIVE="$BACKUP_DIR/$APP.tar.zst"

    echo "Backing up $APP..."

    tar \
        --zstd \
        -cf "$ARCHIVE" \
        --absolute-names \
        $PATHS 2>/dev/null || {
            echo " Warning: Some paths for $APP were missing"
        }

    echo "✔ $APP saved to $ARCHIVE"
done

echo "Backup completed."
