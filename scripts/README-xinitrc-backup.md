# .xinitrc Backup and Configuration Manager

This script allows you to easily backup and switch between different `.xinitrc` configurations for desktop and laptop setups.

## Usage

```bash
./backup-xinitrc.sh [command]
```

## Commands

- **`desktop`** - Switch to desktop configuration
- **`laptop`** - Switch to laptop configuration  
- **`backup`** - Create a backup of current `.xinitrc`
- **`restore`** - Restore from latest backup
- **`status`** - Show current configuration status

## Features

- **Automatic backups**: Every switch creates a timestamped backup
- **Configuration management**: Maintains separate desktop and laptop configs
- **Power management**: Laptop config includes DPMS settings for battery optimization
- **Cleanup**: Keeps only the last 5 backups to save space
- **Status monitoring**: Shows current configuration and available backups

## Configuration Differences

### Desktop Configuration
- Higher refresh rate (120Hz)
- Full volume (100%)
- Additional services (Synergy, etc.)
- No power management restrictions

### Laptop Configuration  
- Standard refresh rate (60Hz)
- Lower volume (80%) for battery
- DPMS power saving enabled
- Power management timeouts:
  - Standby: 5 minutes
  - Suspend: 10 minutes  
  - Off: 15 minutes
- Bluetooth applet enabled

## Examples

```bash
# Switch to laptop configuration
./backup-xinitrc.sh laptop

# Check current status
./backup-xinitrc.sh status

# Switch back to desktop
./backup-xinitrc.sh desktop

# Create manual backup
./backup-xinitrc.sh backup

# Restore from backup
./backup-xinitrc.sh restore
```

## File Locations

- **Main config**: `~/.xinitrc`
- **Desktop config**: `~/.xinitrc-backups/.xinitrc-desktop`
- **Laptop config**: `~/.xinitrc-backups/.xinitrc-laptop`
- **Backups**: `~/.xinitrc-backups/.xinitrc-backup-YYYYMMDD_HHMMSS`

## Notes

- The script automatically makes `.xinitrc` executable
- Backups are rotated to keep disk usage minimal
- Laptop configuration is optimized for battery life
- Desktop configuration prioritizes performance
