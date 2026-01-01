#!/usr/bin/env bash
set -euo pipefail

# -------------------------------------------------
# Paths
# -------------------------------------------------
BACKUP_ROOT="$HOME/cloudwm/config-backups"
CONFIG_BACKUP="$BACKUP_ROOT/.config"
CONF_FILE="$BACKUP_ROOT/apps.conf"

mkdir -p "$CONFIG_BACKUP"

# -------------------------------------------------
# Validate apps.conf
# -------------------------------------------------
if [[ ! -f "$CONF_FILE" ]]; then
    echo "󰅙 apps.conf not found at $CONF_FILE"
    exit 1
fi

# -------------------------------------------------
# Show available apps
# -------------------------------------------------
echo "Available apps:"
grep -Ev '^\s*(#|$)' "$CONF_FILE" | cut -d= -f1
echo

# -------------------------------------------------
# Selection
# -------------------------------------------------
read -rp "Enter app names to backup (space-separated or 'all'): " SELECTION
read -ra SELECTED <<< "$SELECTION"

mapfile -t APPS < <(grep -Ev '^\s*(#|$)' "$CONF_FILE")

# -------------------------------------------------
# Backup loop
# -------------------------------------------------
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

    echo " Processing $APP"

    IFS='|' read -r -a PARTS <<< "$PATHS"

    for raw in "${PARTS[@]}"; do
        # Expand $HOME, etc.
        SRC="$(eval echo "$raw")"

        # Only accept ~/.config paths
        if [[ "$SRC" != "$HOME/.config/"* ]]; then
            continue
        fi

        if [[ ! -d "$SRC" ]]; then
            echo "  ⚠ Skipping non-directory: $SRC"
            continue
        fi

        REL="${SRC#$HOME/.config/}"
        DEST="$CONFIG_BACKUP/$REL"

        mkdir -p "$DEST"

        echo "  → .config/$REL"

        rsync -aAX --delete \
            --info=stats1 \
            "$SRC/" "$DEST/"
    done
done

echo
echo " Backup completed!"

