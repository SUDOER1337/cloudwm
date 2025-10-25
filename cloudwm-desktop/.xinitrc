#!/bin/bash

export XCURSOR_THEME=Bibata-Modern-Classic
export XCURSOR_SIZE=24

pactl set-sink-volume @DEFAULT_SINK@ 0%
pactl set-sink-volume bluez_output.91_AE_2A_52_DA_94.1 10%

feh --bg-scale ~/Pictures/wallpapers/Mountain.png

picom &
flameshot &
slstatus &
redshift -O 3600 &
nm-applet &

# Run autolock script in background
~/cloudwm/scripts/autolock.sh &

# Run Bluetooth auto-pause script in background
~/cloudwm/scripts/bt-autopause.sh &

# using slock login screen lol
slock
# Finally, start dwm
exec dwm

