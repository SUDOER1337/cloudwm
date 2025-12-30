#!/usr/bin/env bash
set -euo pipefail

# -----------------------------
# Resolve script directory
# -----------------------------
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CONF_FILE="$SCRIPT_DIR/apps.conf"
BACKUP_DIR="$SCRIPT_DIR/backups"

mkdir -p "$BACKUP_DIR"

# -----------------------------
# Check apps.conf exists
# -----------------------------
if [[ ! -f "$CONF_FILE" ]]; then
    echo "apps.conf not found at $CONF_FILE"
    exit 1
fi

# -----------------------------
# Display available apps
# -----------------------------
echo "Available apps:"
grep -Ev '^\s*(#|$)' "$CONF_FILE" | cut -d= -f1
echo

# -----------------------------
# Ask which apps to backup
# -----------------------------
read -rp "Enter app names to backup (space-separated or 'all'): " SELECTION
read -ra SELECTED <<< "$SELECTION"

# -----------------------------
# Read apps.conf lines
# -----------------------------
mapfile -t APPS < <(grep -Ev '^\s*(#|$)' "$CONF_FILE")

# -----------------------------
# Backup loop
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

    DEST="$BACKUP_DIR/$APP"
    mkdir -p "$DEST"
    echo "Backing up $APP..."

    # Optional pre-export
    if [[ "$APP" == "vscodium" && -x "$SCRIPT_DIR/vscodium-export.sh" ]]; then
        "$SCRIPT_DIR/vscodium-export.sh" || \
            echo "⚠ vscodium export failed, continuing"
    fi

    # Split paths and expand environment variables
    IFS='|' read -r -a PATH_ARRAY <<< "$PATHS"
    RSYNC_PATHS=()

    for i in "${PATH_ARRAY[@]}"; do
        expanded=$(eval echo "$i")  # Expand $HOME, $XDG_CONFIG_HOME, etc.
        if [[ -e "$expanded" ]]; then
            RSYNC_PATHS+=("${expanded%/}/")  # trailing slash ensures contents copied
        else
            echo "⚠ Warning: Path does not exist: $expanded"
        fi
    done

    if [[ ${#RSYNC_PATHS[@]} -eq 0 ]]; then
        echo "⚠ No valid paths found for $APP, skipping..."
        continue
    fi

    # Perform backup with rsync
    rsync -aAX --relative "${RSYNC_PATHS[@]}" "$DEST/"

    echo "✔ $APP backed up to $DEST"
done

echo "Backup completed."
