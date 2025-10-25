#!/bin/bash

dbus-launch --sh-syntax --exit-with-session

export XCURSOR_THEME=Bibata-Modern-Classic
export XCURSOR_SIZE=24

pactl set-sink-volume @DEFAULT_SINK@ 0%
pactl set-sink-volume bluez_output.91_AE_2A_52_DA_94.1 10%

/usr/lib/polkit-kde-authentication-agent-1 &
/usr/lib/xdg-desktop-portal-gtk &

feh --bg-scale ~/Pictures/wallpapers/Mountain.png

picom &
flameshot &
slstatus &
redshift -O 2700 &
nm-applet &
greenclip daemon &

# Run autolock script in background
~/cloudwm/scripts/autolock.sh &

# Run Bluetooth auto-pause script in background
~/cloudwm/scripts/bt-autopause.sh &

# using slock login screen lol
slock
# Finally, start dwm
exec dwm
