#!/usr/bin/env bash
set -eo pipefail

# CloudWM Configuration Backup Script
# Creates timestamped backup before installation

CLOUDWM_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_DIR="$HOME/.config/cloudwm-backups"
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
BACKUP_FILE="cloudwm-backup-$TIMESTAMP.tar.gz"

echo "🔄 CloudWM Configuration Backup"
echo "=============================="

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Create temporary backup location
TEMP_DIR="/tmp/cloudwm-backup-$$"
mkdir -p "$TEMP_DIR"
trap "rm -rf $TEMP_DIR" EXIT

echo "📁 Creating backup of existing configurations..."

# Backup configurations that exist
backup_count=0

# Function to backup a path
backup_path() {
    local src="$1"
    local dest="$TEMP_DIR/${src#$HOME/}"
    
    if [[ -e "$src" ]]; then
        mkdir -p "$(dirname "$dest")"
        cp -r "$src" "$dest"
        echo "  ✓ Backed up: ${src#$HOME/}"
        backup_count=$((backup_count + 1))
    fi
}

# Backup common configuration locations
backup_path "$HOME/.config/fish"
backup_path "$HOME/.config/rofi"
backup_path "$HOME/.config/picom"
backup_path "$HOME/.config/kitty"
backup_path "$HOME/.config/nvim"
backup_path "$HOME/.config/gtk-3.0"
backup_path "$HOME/.config/gtk-4.0"
backup_path "$HOME/.themes"
backup_path "$HOME/.icons"
backup_path "$HOME/.local/share/fonts"
backup_path "$HOME/.xinitrc"
backup_path "$HOME/.Xresources"
backup_path "$HOME/.xprofile"
backup_path "$HOME/.bashrc"
backup_path "$HOME/.zshrc"

# Create backup info
cat > "$TEMP_DIR/BACKUP_INFO.txt" << EOF
CloudWM Configuration Backup
==========================
Created: $(date)
Timestamp: $TIMESTAMP
User: $(whoami)
Hostname: $(hostname)
Files backed up: $backup_count

To restore:
tar -xzf cloudwm-backup-$TIMESTAMP.tar.gz -C ~/
EOF

# Create the backup archive
echo "📦 Creating compressed archive..."
cd "$TEMP_DIR"
tar -czf "$BACKUP_DIR/$BACKUP_FILE" .

# Check if backup was created successfully
if [[ -f "$BACKUP_DIR/$BACKUP_FILE" ]]; then
    backup_size=$(du -h "$BACKUP_DIR/$BACKUP_FILE" | cut -f1)
    echo "✅ Backup created successfully!"
    echo "📂 Location: $BACKUP_DIR/$BACKUP_FILE"
    echo "📊 Size: $backup_size"
    echo "📋 Files backed up: $backup_count"
    
    # Clean up old backups (keep last 5)
    cd "$BACKUP_DIR"
    ls -t cloudwm-backup-*.tar.gz 2>/dev/null | tail -n +6 | xargs -r rm -f
    
    echo ""
    echo "📋 Available backups:"
    ls -lh cloudwm-backup-*.tar.gz 2>/dev/null || echo "  No previous backups found"
else
    echo "❌ Failed to create backup!"
    exit 1
fi

echo ""
echo "🎉 Backup process completed!"
