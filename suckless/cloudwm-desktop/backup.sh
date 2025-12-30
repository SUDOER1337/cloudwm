#!/bin/bash

# === Configuration ===
SOURCE_DIR="$HOME/cloudwm"                      # Folder to back up
XINITRC="$HOME/.xinitrc"                        # Also back up this file
BACKUP_DIR="$HOME/cloudwm"      # Where backups are stored

# === Setup ===
mkdir -p "$BACKUP_DIR"

# === Find next backup number ===
latest_num=$(ls "$BACKUP_DIR" | grep -Eo 'cloudwm-[0-9]+' | grep -Eo '[0-9]+' | sort -n | tail -1)
if [ -z "$latest_num" ]; then
    next_num=1
else
    next_num=$((latest_num + 1))
fi

# === Backup folder name ===
backup_folder="$BACKUP_DIR/cloudwm-$next_num"
mkdir -p "$backup_folder"

# === Copy files ===
echo "📦 Backing up to $backup_folder..."
cp -r "$SOURCE_DIR" "$backup_folder/"
cp "$XINITRC" "$backup_folder/"

# === Confirmation ===
echo "✅ Backup complete!"
echo "   - Folder: $backup_folder"

