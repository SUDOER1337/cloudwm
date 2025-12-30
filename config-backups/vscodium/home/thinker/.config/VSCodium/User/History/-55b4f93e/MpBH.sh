#!/usr/bin/env bash
set -euo pipefail

# -----------------------------
# Backup root folder
# -----------------------------
BACKUP_ROOT="$HOME/cloudwm/config-backups"
mkdir -p "$BACKUP_ROOT"

# -----------------------------
# apps.conf location
# -----------------------------
CONF_FILE="$BACKUP_ROOT/apps.conf"

if [[ ! -f "$CONF_FILE" ]]; then
    echo "apps.conf not found at $CONF_FILE"
    echo "Please create it with lines like: zsh=\$HOME/.zshrc|\$HOME/.oh-my-zsh"
    exit 1
fi

# -----------------------------
# Show available apps
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
# Read apps.conf
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

    DEST="$BACKUP_ROOT/$APP"
    mkdir -p "$DEST"
    echo "Backing up $APP..."

    # Split paths and expand environment variables
    IFS='|' read -r -a PATH_ARRAY <<< "$PATHS"
    RSYNC_PATHS=()
    for i in "${PATH_ARRAY[@]}"; do
        expanded=$(eval echo "$i")  # expands $HOME, $XDG_CONFIG_HOME, etc.
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

    # Perform backup
    rsync -aAX --relative "${RSYNC_PATHS[@]}" "$DEST/"

    echo "✔ $APP backed up to $DEST"
done

echo "Backup completed!"
