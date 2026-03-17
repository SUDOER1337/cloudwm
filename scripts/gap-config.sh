#!/usr/bin/env bash
set -euo pipefail

# FjordWM Gap Configuration Script
# Easily switch between gap presets

CONFIG_FILE="$HOME/fjordwm/suckless/fjordwm/config.def.h"

echo "fjordwm Gap Configuration"
echo "============================"

# Function to update gaps in config
update_gaps() {
    local gappih="$1"
    local gappiv="$2" 
    local gappoh="$3"
    local gappov="$4"
    local preset_name="$5"
    
    echo "Updating gaps to: $preset_name"
    echo "  Inner H: $gappih, Inner V: $gappiv"
    echo "  Outer H: $gappoh, Outer V: $gappov"
    
    # Backup original config
    cp "$CONFIG_FILE" "$CONFIG_FILE.backup.$(date +%s)"
    
    # Update gap values
    sed -i "s/static const unsigned int gappih = [0-9]*/static const unsigned int gappih = $gappih;/" "$CONFIG_FILE"
    sed -i "s/static const unsigned int gappiv = [0-9]*/static const unsigned int gappiv = $gappiv;/" "$CONFIG_FILE"
    sed -i "s/static const unsigned int gappoh = [0-9]*/static const unsigned int gappoh = $gappoh;/" "$CONFIG_FILE"
    sed -i "s/static const unsigned int gappov = [0-9]*/static const unsigned int gappov = $gappov;/" "$CONFIG_FILE"
    
    echo "✅ Configuration updated!"
    echo "🔄 Restart FjordWM to apply changes (Mod+Shift+q)"
}

# Gap presets
presets=(
    "ultrawide:20:25:5:5"
    "wide:15:20:5:5" 
    "medium:10:15:5:5"
    "compact:5:10:2:2"
    "minimal:2:5:0:0"
    "none:0:0:0:0"
)

echo "Available gap presets:"
echo "  1. ultrawide - ULTRAGAPPY (20,25,5,5) - Maximum spacing"
echo "  2. wide       - Wide gaps (15,20,5,5)"
echo "  3. medium     - Medium gaps (10,15,5,5)"
echo " 4. compact    - Compact gaps (5,10,2,2)"
echo "  5. minimal    - Minimal gaps (2,5,0,0)"
echo "  6. none       - No gaps (0,0,0,0)"

if command -v fzf >/dev/null 2>&1; then
    choice=$(printf '%s\n' "${presets[@]}" | fzf \
        --prompt="Select gap preset: " \
        --height=40% \
        --border \
        --header="Use arrow keys or j/k to navigate, Enter to select")
else
    echo ""
    read -p "Enter preset number (1-6): " choice
    
    case "$choice" in
        1) preset="ultrawide:20:25:5:5" ;;
        2) preset="wide:15:20:5:5" ;;
        3) preset="medium:10:15:5:5" ;;
        4) preset="compact:5:10:2:2" ;;
        5) preset="minimal:2:5:0:0" ;;
        6) preset="none:0:0:0:0" ;;
        *) echo "Invalid choice"; exit 1 ;;
    esac
fi

if [[ -n "$choice" || -n "$preset" ]]; then
    # Parse preset values
    IFS=':' read -ra VALUES <<< "$preset"
    update_gaps "${VALUES[1]}" "${VALUES[2]}" "${VALUES[3]}" "${VALUES[4]}" "${VALUES[0]}"
else
    echo "No selection made."
    exit 0
fi

echo ""
echo "Tip: Use keybindings in FjordWM:"
echo "  Mod+g           - Toggle gaps on/off"
echo "  Mod+Shift+g     - Set gappy gaps"  
echo "  Mod+Control+g   - Set ULTRAGAPPY gaps"
echo ""
echo "Manual gap adjustment:"
echo "  Mod+Shift+6/7  - Increase/decrease inner horizontal gaps"
echo "  Mod+Shift+8/9  - Increase/decrease inner vertical gaps" 
echo "  Mod+Control+6/7 - Increase/decrease outer horizontal gaps"
echo "  Mod+Control+8/9 - Increase/decrease outer vertical gaps"
