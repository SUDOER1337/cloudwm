Polybar top-focus bar (dwm-compatible)

This bar mirrors the Waybar configuration at ~/fjordwm/waybar/bars/fjordwl-top-focus.jsonc and is intended for use with dwm (or sway with XWayland).

Files
- config-top-focus.ini : Polybar configuration for the top focus bar
- colors-top-focus.ini : Color palette used by the bar
- launch-top-focus.sh : Monitor-aware launcher script (uses --config explicitly)
- wrappers/ : adapter scripts that call existing waybar scripts (media, cpu, mic, updates)

Quick start
1. Ensure polybar is installed and available in PATH.
2. Make sure scripts under waybar/bin and polybar/wrappers are executable.
3. Run: /home/thinker/fjordwm/polybar/launch-top-focus.sh
4. Logs: ~/.cache/polybar-top-focus.log

Notes
- Some Waybar features (drawers, advanced json return types) are approximated via scripts.
- If modules don't appear, inspect the log file and ensure $MONITOR or network interface environment variables are set where appropriate.
