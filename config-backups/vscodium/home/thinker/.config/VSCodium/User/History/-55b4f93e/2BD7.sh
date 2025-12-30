#!/usr/bin/env bash
set -euo pipefail

# Resolve script directory reliably
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

CONF_FILE="$SCRIPT_DIR/apps.conf"
BACKUP_DIR="$SCRIPT_DIR/backups"

mkdir -p "$BACKUP_DIR"

if [[ ! -f "$CONF_FILE" ]]; then
    echo "apps.conf not found!"
    exit 1
fi

echo "Available apps:"
grep -Ev '^\s*(#|$)' "$CONF_FILE" | cut -d= -f1
echo

read -rp "Enter app names to backup (space-separated or 'all'): " SELECTION
read -ra SELECTED <<< "$SELECTION"

mapfile -t APPS < <(grep -Ev '^\s*(#|$)' "$CONF_FILE")

for line in "${APPS[@]}"; do
    APP="${line%%=*}"
    PATHS="${line#*=}"

    # Selection filter
    if [[ "$SELECTION" != "all" ]]; then
        match=false
        for s in "${SELECTED[@]}"; do
            [[ "$s" == "$APP" ]] && match=true
        done
        $match || continue
    fi

    DEST="$BACKUP_DIR/$APP"
    mkdir -p "$DEST"

    echo "Backing up $APP..."

    # Optional pre-export
    if [[ "$APP" == "vscodium" && -x "$SCRIPT_DIR/vscodium-export.sh" ]]; then
        "$SCRIPT_DIR/vscodium-export.sh" || \
            echo "⚠ vscodium export failed, continuing"
    fi

    # Split paths safely
    IFS='|' read -r -a PATH_ARRAY <<< "$PATHS"

    # Force trailing slash to copy CONTENTS, not empty dirs
    RSYNC_PATHS=()
    for p in "${PATH_ARRAY[@]}"; do
        [[ -e "$p" ]] && RSYNC_PATHS+=("${p%/}/")
    done

    if [[ ${#RSYNC_PATHS[@]} -eq 0 ]]; then
        echo "⚠ No valid paths found for $APP"
        continue
    fi

    rsync -aAX --relative \
        "${RSYNC_PATHS[@]}" \
        "$DEST/" || {
            echo "⚠ Warning: Some paths for $APP were missing"
        }

    echo "✔ $APP backed up to $DEST"
done

echo "Backup completed."
