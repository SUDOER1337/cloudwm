#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_DIR="$SCRIPT_DIR/backups"
CONF_FILE="$SCRIPT_DIR/apps.conf"

mkdir -p "$BACKUP_DIR"

if [[ ! -f "$CONF_FILE" ]]; then
    echo "apps.conf not found!"
    exit 1
fi

rsync -aAX --relative \
    "${PATH_ARRAY[@]/%//}" \
    "$DEST/"

echo "Available apps:"
grep -Ev '^\s*(#|$)' "$CONF_FILE" | cut -d= -f1
echo

read -rp "Enter app names to backup (space-separated or 'all'): " SELECTION
read -ra SELECTED <<< "$SELECTION"

mapfile -t APPS < <(grep -Ev '^\s*(#|$)' "$CONF_FILE")

for line in "${APPS[@]}"; do
    APP="${line%%=*}"
    PATHS="${line#*=}"

    if [[ "$SELECTION" != "all" ]]; then
        match=false
        for s in "${SELECTED[@]}"; do
            [[ "$s" == "$APP" ]] && match=true
        done
        $match || continue
    fi

    DEST="$BACKUP_DIR/$APP"
    mkdir -p "$DEST"

    echo "Backing up $APP (raw copy)..."

    if [[ "$APP" == "vscodium" && -x "$SCRIPT_DIR/vscodium-export.sh" ]]; then
        "$SCRIPT_DIR/vscodium-export.sh" || echo " vscodium export failed, continuing"
    fi

    IFS='|' read -r -a PATH_ARRAY <<< "$PATHS"

    rsync -aAX --relative \
        "${PATH_ARRAY[@]}" \
        "$DEST/" || {
            echo " Warning: Some paths for $APP were missing"
        }

    echo "✔ $APP copied to $DEST"
done

echo "Backup completed."
