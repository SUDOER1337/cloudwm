#!/bin/bash

# === Config ===
dir="$HOME/cloudwm/rofi/controlcenter/"
theme='controlcenter'

# Common .desktop directories
desktop_paths=(
    "$HOME/.local/share/applications"
    "/usr/share/applications"
    "/usr/local/share/applications"
)

# === Rofi wrapper ===
rofi_cc() {
    printf "%b" "$1" | rofi -dmenu -p "$2" -theme "${dir}/${theme}.rasi"
}

# === Dunst toggle (with notifications) ===
toggle_dunst() {
    if pgrep -x "dunst" >/dev/null; then
        notify-send "Dunst" "Disabling notifications"
        sleep 1
        pkill dunst
    else
        dunst &
        disown
        sleep 0.5
        notify-send "Dunst" "Notifications Enabled"
    fi
}

# === Xautolock toggle (with notifications) ===
toggle_xautolock() {
    if pgrep -x "xautolock" >/dev/null; then
        notify-send "Autolock" "Disabling xautolock"
        sleep 1
        pkill xautolock
    else
        # Start your autolock script
        "$HOME/cloudwm/scripts/autolock.sh" &
        disown
        sleep 0.5
        notify-send "Autolock" "xautolock Enabled"
    fi
}

manage_desktop_files() {
    # Select a directory
    chosen_dir=$(printf "%s\n" "${desktop_paths[@]}" | \
                 rofi -dmenu -p "Select .desktop folder" -theme "${dir}/${theme}.rasi")
    [ -z "$chosen_dir" ] && return

    # Get all .desktop files
    desktop_files=$(ls "$chosen_dir"/*.desktop 2>/dev/null)
    if [ -z "$desktop_files" ]; then
        notify-send "Rofi Desktop Manager" "No .desktop files found in $chosen_dir"
        return
    fi

    # Pick a file
    chosen_file=$(printf "%s\n" $desktop_files | xargs -n1 basename | \
                  rofi -dmenu -p "  Edit Desktop Entry" -theme "${dir}/${theme}.rasi")
    [ -z "$chosen_file" ] && return

    # Action menu
    action=$(rofi_cc "Edit\nDelete\nCancel" "  Manage $chosen_file")
    case "$action" in
        "Edit")
            kitty -e nvim "$chosen_dir/$chosen_file"
            ;;
        "Delete")
            if [[ "$chosen_dir" == /usr/* ]]; then
                # System directory → needs root
                if command -v pkexec >/dev/null 2>&1; then
                    pkexec rm -i "$chosen_dir/$chosen_file"
                else
                    kitty -e sudo rm -i "$chosen_dir/$chosen_file"
                fi
            else
                # Local directory → normal delete
                rm -i "$chosen_dir/$chosen_file"
            fi

            if [ $? -eq 0 ]; then
                notify-send "Rofi Desktop Manager" "$chosen_file deleted."
            else
                notify-send "Rofi Desktop Manager" "Failed to delete $chosen_file."
            fi
            ;;
        *)
            return
            ;;
    esac
}

# === Show Dunst & Xautolock status in menu ===
if pgrep -x "dunst" >/dev/null; then
    dunst_status="   Dunst [Currently On]"
else
    dunst_status="   Dunst [Currently Off]"
fi

if pgrep -x "xautolock" >/dev/null; then
    xautolock_status="   Autolock [Currently On]"
else
    xautolock_status="   Autolock [Currently Off]"
fi

# === Main Menu ===
options=" 󰚰  Update System\n$dunst_status\n$xautolock_status\n 󰄄  Manage .desktop Files"

choice=$(rofi_cc "$options" "  Control Center")

case "$choice" in
    " 󰚰  Update System") "$HOME/cloudwm/scripts/updatecheck.sh" --update ;;
    "$dunst_status")    toggle_dunst ;;
    "$xautolock_status") toggle_xautolock ;;
    " 󰄄  Manage .desktop Files") manage_desktop_files ;;
esac

