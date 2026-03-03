#!/usr/bin/env bash
set -euo pipefail

# -------------------------------------------------
# Paths
# -------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

BACKUP_ROOT="$SCRIPT_DIR"
CONFIG_BACKUP="$BACKUP_ROOT/.config"
CONF_FILE="$BACKUP_ROOT/apps.conf"
XINITRC_SRC="$HOME/.xinitrc"
XINITRC_DESKTOP="$PROJECT_ROOT/suckless/.xinitrc-desktop"
XINITRC_LAPTOP="$PROJECT_ROOT/suckless/.xinitrc-laptop"
XINITRC_DESKTOP_REL="suckless/.xinitrc-desktop"
XINITRC_LAPTOP_REL="suckless/.xinitrc-laptop"

mkdir -p "$CONFIG_BACKUP"

sync_laptop_exports_from_desktop() {
    local desktop_file="$1"
    local laptop_file="$2"
    local export_map
    local tmp_file

    export_map="$(mktemp)"
    tmp_file="$(mktemp)"

    while IFS= read -r export_line; do
        local var_name
        var_name="$(sed -E 's/^[[:space:]]*export[[:space:]]+([A-Za-z_][A-Za-z0-9_]*)=.*/\1/' <<< "$export_line")"
        printf '%s\t%s\n' "$var_name" "$export_line" >> "$export_map"
    done < <(sed -n '24,27p;30p' "$desktop_file" | grep -E '^[[:space:]]*export[[:space:]]+[A-Za-z_][A-Za-z0-9_]*=' || true)

    if [[ ! -s "$export_map" ]]; then
        rm -f "$export_map" "$tmp_file"
        echo "  ⚠ Could not read export lines 24-27 and 30 from $XINITRC_DESKTOP_REL"
        return
    fi

    awk -F'\t' '
        NR == FNR {
            repl[$1] = $2
            order[++count] = $1
            next
        }
        {
            line = $0
            if (line ~ /^[[:space:]]*export[[:space:]]+[A-Za-z_][A-Za-z0-9_]*=/) {
                sub(/^[[:space:]]*export[[:space:]]+/, "", line)
                split(line, parts, "=")
                key = parts[1]
                if (key in repl) {
                    print repl[key]
                    seen[key] = 1
                    next
                }
            }
            print
        }
        END {
            for (i = 1; i <= count; i++) {
                key = order[i]
                if (!(key in seen)) {
                    print repl[key]
                }
            }
        }
    ' "$export_map" "$laptop_file" > "$tmp_file"

    mv "$tmp_file" "$laptop_file"
    rm -f "$export_map"
    echo "  → Synced $XINITRC_LAPTOP_REL using desktop lines 24-27 and 30"
}

sync_xinitrc_profiles() {
    if [[ ! -f "$XINITRC_SRC" ]]; then
        echo "⚠ Skipping xinitrc sync: $XINITRC_SRC not found"
        return
    fi

    mkdir -p "$(dirname "$XINITRC_DESKTOP")"
    mkdir -p "$(dirname "$XINITRC_LAPTOP")"

    cp "$XINITRC_SRC" "$XINITRC_DESKTOP"
    chmod +x "$XINITRC_DESKTOP"
    echo "→ Updated $XINITRC_DESKTOP_REL from ~/.xinitrc"

    if [[ ! -f "$XINITRC_LAPTOP" ]]; then
        cp "$XINITRC_DESKTOP" "$XINITRC_LAPTOP"
        echo "  → Created $XINITRC_LAPTOP_REL from desktop profile"
    fi

    sync_laptop_exports_from_desktop "$XINITRC_DESKTOP" "$XINITRC_LAPTOP"
    chmod +x "$XINITRC_LAPTOP"
}

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
echo "󱋟 Syncing xinitrc profiles"
sync_xinitrc_profiles

echo
echo " Backup completed!"
