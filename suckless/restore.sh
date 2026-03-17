#!/usr/bin/env bash
set -euo pipefail

# -----------------------------
# Backup root folder
# -----------------------------
BACKUP_ROOT="$HOME/fjordwm/config-backups"

# apps.conf location
CONF_FILE="$BACKUP_ROOT/apps.conf"

if [[ ! -f "$CONF_FILE" ]]; then
    echo "apps.conf not found at $CONF_FILE"
    exit 1
fi

# -----------------------------
# Show available backups
# -----------------------------
echo "Available backups:"
grep -Ev '^\s*(#|$)' "$CONF_FILE" | cut -d= -f1
echo

# Ask which apps to restore
read -rp "Enter app names to restore (space-separated or 'all'): " SELECTION
read -ra SELECTED <<< "$SELECTION"

# -----------------------------
# Read apps.conf
# -----------------------------
mapfile -t APPS < <(grep -Ev '^\s*(#|$)' "$CONF_FILE")

# -----------------------------
# Restore loop
# -----------------------------
for line in "${APPS[@]}"; do
    APP="${line%%=*}"
    PATHS="${line#*=}"

    # Skip if not selected
    if [[ "$SELECTION" != "all" ]]; then
        match=false
        for s in "${SELECTED[@]}"; do
            [[ "$s" == "$APP" ]] && match=true
        done
        $match || continue
    fi

    BACKUP_DIR="$BACKUP_ROOT/$APP"
    if [[ ! -d "$BACKUP_DIR" ]]; then
        echo "⚠ Backup for $APP not found, skipping..."
        continue
    fi

    echo "Restoring $APP..."

    # Split paths and expand env vars
    IFS='|' read -r -a PATH_ARRAY <<< "$PATHS"
    for i in "${PATH_ARRAY[@]}"; do
        TARGET=$(eval echo "$i")  # expands $HOME, $XDG_CONFIG_HOME, etc.
        if [[ ! -e "$TARGET" ]]; then
            mkdir -p "$TARGET"  # ensure target exists
        fi

        rsync -aAX --relative "$BACKUP_DIR"/ "$TARGET"/ || {
            echo "⚠ Warning: Restore may have failed for $TARGET"
        }
    done

    echo "✔ $APP restored"
done

echo "Restore completed!"
