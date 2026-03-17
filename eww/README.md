# eww Bar for dwm (X11) - Setup & Usage

## Overview

This setup integrates **eww** (Elkowars Wacky Widgets) as the primary status bar for **dwm** (Dynamic Window Manager). eww provides a modern, customizable bar with interactive widgets while maintaining the simplicity and philosophy of dwm.

## Features

- **Workspaces/Tags**: Visual indicator of active/occupied tags
- **Media Control**: Shows currently playing media (if available)
- **System Stats**: Network, Updates, Audio Volume, Brightness, Battery, Clock
- **Interactive Panels**: 
  - Control Panel: Quick access to volume, brightness, updates, notifications
  - Power Panel: Lock, Logout, Suspend, Reboot, Shutdown actions
- **Application Launcher**: Quick access to rofi launcher
- **Wayland Compatible**: Same config works for both dwm (X11) and dwl (Wayland)

## Files

### Configuration
- `eww/eww.yuck` - Widget definitions (works for X11 and Wayland)
- `eww/eww.scss` - Styling with color variables
- `eww/x11-startup.sh` - X11-specific startup script
- `suckless/fjordwm/config.h` - dwm configuration with eww integration

### Scripts (in `eww/scripts/`)
- `workspaces.sh` - Display dwm tags/workspaces
- `clock.sh` - Current time
- `battery.sh` - Battery status
- `audio.sh` - Audio volume and control
- `brightness.sh` - Screen brightness
- `network.sh` - Network status
- `updates.sh` - Package updates available
- `media.sh` - Media player info
- `power.sh` - Power management actions
- `session-state.sh` - Notifications and idle lock status
- `toggle-panel.sh` - Show/hide control and power panels
- `common.sh` - Common utility functions

## Installation & Setup

### Prerequisites
- dwm with eww bar support (already built)
- eww daemon installed: `which eww` should return `/usr/bin/eww`
- Required utilities:
  - `dunst` or `swaync` for notifications
  - `alsa-utils` or `pipewire` for audio control
  - `brightnessctl` for brightness control
  - `rofi` for application launcher (optional but recommended)

### Enabling eww Bar

The eww bar is now the default for fjordwm on X11. It's configured in:
- `suckless/fjordwm/config.h` sets `usealtbar = 1` and `altbarcmd = "$HOME/fjordwm/eww/x11-startup.sh &"`

### Building & Installing

If you modify `eww/eww.yuck` or `eww/eww.scss`, restart eww:

```bash
# Kill existing eww
pkill -f "eww daemon"

# Start new instance
~/.fjordwm/eww/x11-startup.sh
```

To rebuild dwm after config changes:
```bash
cd ~/fjordwm/suckless/fjordwm
make clean
make
# sudo make install  # if you want to install system-wide
```

## Customization

### Colors
Edit `eww/eww.scss` to change colors:
```scss
$bg: #292828;
$fg: #c0af8b;
$focus: #556c59;
// ... more colors
```

### Bar Height
- `eww/eww.yuck`: Change `height` in the `defwindow bar` block (default: 38px)
- `suckless/fjordwm/config.h`: Update `user_bh` to match (default: 38)

### Widgets
- Add/remove/reorder widgets in the `bar-content` widget in `eww/eww.yuck`
- Modify styling in `eww/eww.scss` to match your theme

### Scripts
- Each module script can be independently modified
- Scripts output to stdout; eww polls them at intervals defined by `defpoll`

## Fallback: Polybar

If eww causes issues, you can revert to Polybar:

Edit `suckless/fjordwm/config.h`:
```c
/* Uncomment polybar line, comment eww line */
// static const char altbarcmd[] = "$HOME/fjordwm/eww/x11-startup.sh &";
static const char altbarcmd[] = "$HOME/fjordwm/polybar/launch-top-focus.sh &";
```

Then rebuild dwm:
```bash
cd ~/fjordwm/suckless/fjordwm && make clean && make
```

## Troubleshooting

### Bar doesn't appear
1. Check if eww daemon is running: `ps aux | grep eww`
2. View eww logs: `eww logs`
3. Verify config: `eww --config ~/fjordwm/eww debug`
4. Try manual startup: `~/.fjordwm/eww/x11-startup.sh`

### Workspaces not showing
- Make sure you've switched tags/workspaces in dwm
- Check `eww logs` for script errors
- Verify dwm is running and managing windows

### Widgets not updating
- Check script permissions: `ls -la ~/fjordwm/eww/scripts/`
- Run individual scripts manually to verify they work
- Check interval values in `eww.yuck` (`:interval` parameter)

### Colors not applying
- Reload eww: `eww --config ~/fjordwm/eww reload`
- Verify SCSS is valid and paths are correct

## Integration with dwm Keybindings

The eww bar integrates with dwm controls:
- **Super+P**: Toggle launcher (chip-button click in eww bar)
- **Workspace switching**: Bar updates to show active/inactive workspaces
- **Media control**: Click media widget or use system hotkeys
- **Volume/Brightness**: Click widgets or use function keys

The bar respects dwm's built-in status bar settings and automatically positions above windows.

## Performance Notes

- Polls run at intervals defined in `eww.yuck` (1s to 10m)
- Low CPU impact; most work is idle waiting
- Scripts cache results to avoid repeated system calls
- Wayland support via `exclusive true` in window definition

## See Also

- [eww Documentation](https://github.com/elkowar/eww)
- [dwm Configuration](https://dwm.suckless.org/)
- `~/fjordwm/README.md` - Main project documentation
