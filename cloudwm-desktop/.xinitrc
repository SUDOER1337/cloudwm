#!/bin/bash
# ~/.xinitrc - auto-start apps and settings for DWM

# ─── Environment Variables ─────────────────────────────────────────────

# Start a session bus

dbus-launch --sh-syntax --exit-with-session

# Make sure environment variables are sane
export XDG_SESSION_TYPE=x11
export XDG_CURRENT_DESKTOP=dwm
export XDG_SESSION_DESKTOP=dwm

export QT_QPA_PLATFORMTHEME=qt5ct
export XCURSOR_THEME=Bibata-Modern-Classic
export XCURSOR_SIZE=24
export XDG_MENU_PREFIX=arch-

export KDE_FULL_SESSION=true
export KDE_SESSION_VERSION=5


# ─── Services & Daemons ─────────────────────────────────

/usr/lib/polkit-kde-authentication-agent-1 &
/usr/lib/xdg-desktop-portal-gtk &
/usr/lib/xdg-desktop-portal &
/opt/Synergy/synergy-service &
~/cloudwm/scripts/autolock.sh &
udiskie &

# Merge Xresources
xrdb -merge ~/.Xresources

# Volume
pactl set-sink-volume @DEFAULT_SINK@ 100%

# ─── Screen Settings ──────────────────────────────────────────────────
xrandr -r 120
xset s off          # Disable screen saver
xset s noblank      # Prevent blanking
xset -dpms          # Disable DPMS (Energy Star) features

# ─── Autostart Programs ──────────────────────────────────────────────
# Wallpaper
feh --bg-scale ~/Pictures/Wallpapers/mountain.jpg &

# Notifications and screenshots
greenclip daemon &
flameshot &
dunst &

# Compositor
picom &

# Screen temperature adjustment
(redshift -O 3800 &)

# Status bar
slstatus &

# ─── Optional: Other scripts or applets ─────────────────────────────
# Example: Network, Bluetooth, etc.
nm-applet &
# blueman-applet &

# ─── Start Window Manager ────────────────────────────────────────────
slock # basically using slock as login screen
exec dwm

