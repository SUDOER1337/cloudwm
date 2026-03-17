#!/usr/bin/env bash
set -eo pipefail

# FjordWM Configuration Restore Script
# Restores configurations from backup archives

BACKUP_DIR="$HOME/.config/fjordwm-backups"

echo "🔄 FjordWM Configuration Restore"
echo "=============================="

# Check if backup directory exists
if [[ ! -d "$BACKUP_DIR" ]]; then
    echo "❌ No backup directory found at $BACKUP_DIR"
    exit 1
fi

# List available backups
echo "📋 Available backups:"
backups=($(ls -t "$BACKUP_DIR"/fjordwm-backup-*.tar.gz 2>/dev/null))

if [[ ${#backups[@]} -eq 0 ]]; then
    echo "  No backups found"
    exit 1
fi

for i in "${!backups[@]}"; do
    backup_file=$(basename "${backups[$i]}")
    backup_size=$(du -h "${backups[$i]}" | cut -f1)
    echo "  $((i+1)). $backup_file ($backup_size)"
done

# Select backup to restore
if command -v fzf >/dev/null 2>&1; then
    selected_backup=$(printf '%s\n' "${backups[@]}" | fzf \
        --prompt="Select backup to restore: " \
        --height=40% \
        --border)
else
    echo ""
    read -p "Enter backup number (1-${#backups[@]}): " choice
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [[ $choice -ge 1 ]] && [[ $choice -le ${#backups[@]} ]]; then
        selected_backup="${backups[$((choice-1))]}"
    else
        echo "❌ Invalid selection"
        exit 1
    fi
fi

if [[ -z "$selected_backup" ]]; then
    echo "❌ No backup selected"
    exit 1
fi

backup_name=$(basename "$selected_backup")

# Show backup info if available
temp_dir=$(mktemp -d)
trap "rm -rf $temp_dir" EXIT

if tar -tf "$selected_backup" BACKUP_INFO.txt >/dev/null 2>&1; then
    echo ""
    echo "📄 Backup Information:"
    tar -xzf "$selected_backup" -C "$temp_dir" BACKUP_INFO.txt
    cat "$temp_dir/BACKUP_INFO.txt"
    echo ""
fi

# Confirm restore
echo "⚠️  This will overwrite your current configurations!"
echo "📂 Backup to restore: $backup_name"
read -p "Continue? [y/N]: " confirm

if [[ ! "$confirm" =~ ^[yY] ]]; then
    echo "❌ Restore cancelled"
    exit 0
fi

# Perform restore
echo "🔄 Restoring configurations..."
cd "$HOME"
tar -xzf "$selected_backup"

echo "✅ Configuration restored successfully!"
echo "🔄 Please restart your session or reload configurations to apply changes"

# List restored files
echo ""
echo "📋 Restored files:"
tar -tzf "$selected_backup" | grep -v "BACKUP_INFO.txt" | sed 's/^/  /'
