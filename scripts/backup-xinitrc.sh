#!/bin/bash

# backup-xinitrc.sh - Script to backup and switch .xinitrc configurations
# Usage: ./backup-xinitrc.sh [desktop|laptop|backup|restore]

XINITRC_FILE="$HOME/.xinitrc"
BACKUP_DIR="$HOME/.xinitrc-backups"
DESKTOP_CONFIG="$BACKUP_DIR/.xinitrc-desktop"
LAPTOP_CONFIG="$BACKUP_DIR/.xinitrc-laptop"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
CURRENT_BACKUP="$BACKUP_DIR/.xinitrc-backup-$TIMESTAMP"

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Function to show usage
show_usage() {
    echo "Usage: $0 [desktop|laptop|backup|restore|status]"
    echo ""
    echo "Commands:"
    echo "  desktop  - Switch to desktop configuration"
    echo "  laptop   - Switch to laptop configuration"
    echo "  backup   - Create a backup of current .xinitrc"
    echo "  restore  - Restore from latest backup"
    echo "  status   - Show current configuration status"
    echo ""
    echo "This script manages .xinitrc configurations for different setups."
}

# Function to backup current .xinitrc
backup_current() {
    if [[ -f "$XINITRC_FILE" ]]; then
        cp "$XINITRC_FILE" "$CURRENT_BACKUP"
        echo "✓ Backed up current .xinitrc to $CURRENT_BACKUP"
        
        # Keep only last 5 backups
        ls -t "$BACKUP_DIR"/.xinitrc-backup-* 2>/dev/null | tail -n +6 | xargs rm -f 2>/dev/null
    else
        echo "⚠ No .xinitrc file found to backup"
    fi
}

# Function to switch to desktop configuration
switch_to_desktop() {
    echo "🔄 Switching to desktop configuration..."
    
    # Backup current config first
    backup_current
    
    # If desktop config doesn't exist, create it from current
    if [[ ! -f "$DESKTOP_CONFIG" ]]; then
        if [[ -f "$XINITRC_FILE" ]]; then
            cp "$XINITRC_FILE" "$DESKTOP_CONFIG"
            echo "✓ Created desktop configuration from current .xinitrc"
        else
            echo "❌ No current .xinitrc found to create desktop config"
            exit 1
        fi
    fi
    
    # Copy desktop config to .xinitrc
    cp "$DESKTOP_CONFIG" "$XINITRC_FILE"
    echo "✓ Switched to desktop configuration"
    
    # Make executable
    chmod +x "$XINITRC_FILE"
}

# Function to switch to laptop configuration
switch_to_laptop() {
    echo "🔄 Switching to laptop configuration..."
    
    # Backup current config first
    backup_current
    
    # If laptop config doesn't exist, create a basic laptop config
    if [[ ! -f "$LAPTOP_CONFIG" ]]; then
        echo "📝 Creating laptop configuration..."
        cat > "$LAPTOP_CONFIG" << 'EOF'
#!/bin/bash
# ~/.xinitrc - laptop configuration for fjordwm

# ─── Environment Variables ─────────────────────────────────────────────

# Start a session bus
eval "$(dbus-launch --sh-syntax --exit-with-session)"

# Make sure environment variables are sane
export XDG_SESSION_TYPE=x11
export XDG_CURRENT_DESKTOP=fjordwm
export XDG_SESSION_DESKTOP=fjordwm

export QT_QPA_PLATFORMTHEME=qt5ct
export XCURSOR_THEME=Bibata-Modern-Classic
export XCURSOR_SIZE=24
export XDG_MENU_PREFIX=arch-

# Make X11/session vars visible to systemd --user and DBus-activated services
# (needed for portal backends like xdg-desktop-portal-gtk).
if command -v systemctl >/dev/null 2>&1; then
  systemctl --user import-environment DISPLAY XAUTHORITY \
    XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP XDG_SESSION_TYPE
fi
if command -v dbus-update-activation-environment >/dev/null 2>&1; then
  dbus-update-activation-environment --systemd DISPLAY XAUTHORITY \
    XDG_CURRENT_DESKTOP XDG_SESSION_DESKTOP XDG_SESSION_TYPE
fi

export KDE_FULL_SESSION=true
export KDE_SESSION_VERSION=5

# ─── Services & Daemons ─────────────────────────────────

/usr/lib/polkit-kde-authentication-agent-1 &
/usr/lib/xdg-desktop-portal-gtk &
/usr/lib/xdg-desktop-portal &
~/fjordwm/scripts/autolock.sh &
udiskie &
kdeconnectd &

# Merge Xresources
xrdb -merge ~/.Xresources

# Volume
pactl set-sink-volume @DEFAULT_SINK@ 80%

# ─── Screen Settings (Laptop) ────────────────────────────────────────
# Laptop-specific settings (battery optimization)
xrandr -r 60
xset s off          # Disable screen saver
xset s noblank      # Prevent blanking
xset +dpms          # Enable DPMS for power saving
xset dpms 300 600 900  # Standby after 5min, Suspend after 10min, Off after 15min

# ─── Autostart Programs ──────────────────────────────────────────────
greenclip daemon &
flameshot &
dunst &
stretchly &
# Compositor (with laptop optimizations)
picom --config ~/.config/picom/picom-laptop.conf &

# Screen temperature adjustment
redshift -v &

# Status bar
slstatus &

# ─── Optional: Other scripts or applets ─────────────────────────────
nm-applet &
blueman-applet &

# ─── Start Window Manager ────────────────────────────────────────────

# Wallpaper
feh --bg-scale ~/fjordwm/wallpapers/forest1.jpg

sleep 1

exec fjordwm
EOF
        echo "✓ Created laptop configuration"
    fi
    
    # Copy laptop config to .xinitrc
    cp "$LAPTOP_CONFIG" "$XINITRC_FILE"
    echo "✓ Switched to laptop configuration"
    
    # Make executable
    chmod +x "$XINITRC_FILE"
}

# Function to restore from latest backup
restore_backup() {
    LATEST_BACKUP=$(ls -t "$BACKUP_DIR"/.xinitrc-backup-* 2>/dev/null | head -n1)
    
    if [[ -f "$LATEST_BACKUP" ]]; then
        cp "$LATEST_BACKUP" "$XINITRC_FILE"
        echo "✓ Restored .xinitrc from $LATEST_BACKUP"
        chmod +x "$XINITRC_FILE"
    else
        echo "❌ No backup found to restore"
        exit 1
    fi
}

# Function to show status
show_status() {
    echo "📊 .xinitrc Configuration Status"
    echo "=================================="
    
    if [[ -f "$XINITRC_FILE" ]]; then
        echo "✓ Current .xinitrc exists"
        echo "   Size: $(stat -c%s "$XINITRC_FILE") bytes"
        echo "   Modified: $(stat -c%y "$XINITRC_FILE")"
    else
        echo "❌ No .xinitrc found"
    fi
    
    echo ""
    echo "📁 Available configurations:"
    
    if [[ -f "$DESKTOP_CONFIG" ]]; then
        echo "✓ Desktop config exists ($(stat -c%s "$DESKTOP_CONFIG") bytes)"
    else
        echo "❌ Desktop config not found"
    fi
    
    if [[ -f "$LAPTOP_CONFIG" ]]; then
        echo "✓ Laptop config exists ($(stat -c%s "$LAPTOP_CONFIG") bytes)"
    else
        echo "❌ Laptop config not found"
    fi
    
    echo ""
    echo "💾 Recent backups:"
    ls -la "$BACKUP_DIR"/.xinitrc-backup-* 2>/dev/null | tail -n5 || echo "No backups found"
}

# Main script logic
case "${1:-}" in
    "desktop")
        switch_to_desktop
        ;;
    "laptop")
        switch_to_laptop
        ;;
    "backup")
        backup_current
        ;;
    "restore")
        restore_backup
        ;;
    "status")
        show_status
        ;;
    *)
        show_usage
        exit 1
        ;;
esac

echo ""
echo "🎉 Operation completed successfully!"
echo "💡 Run '$0 status' to see current configuration status"
