<img src="fjordwm.png" alt="fjordwm logo" width="100%">

# customized renamed dwm build

fjordwm is a customized version of suckless dwm with patches, themes, and scripts.
Forked from namishh's bedwm.
The repo also includes an optional `dwl` path for Wayland builds.

Requirements
------------
- gcc, make, git
- fzf for interactive setup
- sudo

Installation
------------
    git clone https://github.com/SUDOER1337/fjordwm.git
    cd fjordwm
    ./setup.sh

Minimal Clone Options
---------------------
If you only want part of the repository, use Git sparse checkout. This is optional and client-side; the repo does not force partial clone behavior.

Window manager only (manual build/config work):

    git clone --filter=blob:none --no-checkout https://github.com/SUDOER1337/fjordwm.git
    cd fjordwm
    git sparse-checkout init --cone
    git sparse-checkout set suckless/fjordwm
    git checkout main
    cd suckless/fjordwm
    make clean install

Wayland compositor only (manual build/config work):

    git clone --filter=blob:none --no-checkout https://github.com/SUDOER1337/fjordwm.git
    cd fjordwm
    git sparse-checkout init --cone
    git sparse-checkout set suckless/dwl
    git checkout main
    ./suckless/build-suckless.sh --wm dwl --install-mode local --yes

Window manager + rofi (manual build plus launcher configs):

    git clone --filter=blob:none --no-checkout https://github.com/SUDOER1337/fjordwm.git
    cd fjordwm
    git sparse-checkout init --cone
    git sparse-checkout set suckless/fjordwm rofi
    git checkout main

Full experience minus heavy assets (recommended if you still want `./setup.sh`):

    git clone --filter=blob:none --no-checkout https://github.com/SUDOER1337/fjordwm.git
    cd fjordwm
    git sparse-checkout init --cone
    git sparse-checkout set suckless rofi scripts themes config-backups README.md setup.sh
    git checkout main
    ./setup.sh

Skipping `wallpapers/` and `screenshots/` reduces download size, but you will not get the bundled wallpapers or media assets.

The setup script supports both interactive and flag-driven installs:

    ./setup.sh --task all --profile desktop --yes
    ./setup.sh --task packages --wm dwl --yes
    ./setup.sh --task build --wm dwl --yes
    ./setup.sh --task betterdiscord --yes

Available tasks:
- `all`: packages, build, shell setup, and post-setup tasks
- `packages`: install packages only
- `build`: build the selected window-manager stack
- `shell`: install the fish shell configuration
- `post`: apply GUI-only post-setup tweaks
- `betterdiscord`: install Discord, install/update BetterDiscord, and apply the bundled theme

Available window-manager targets:
- `fjordwm`: current X11 stack (`fjordwm`, `slock`, `slstatus`)
- `dwl`: Wayland compositor only, installed locally by default
- `both`: build both stacks; `--profile` is still required for the `fjordwm` side

Screenshots
----------

| Terminal Setup | Development |
|----------------|-------------|
| ![Terminal Setup](screenshots/terminals.gif) | ![Development](screenshots/fjordwm-vscodium.png) |

| Application Launcher | Lock Screen |
|---------------------|-------------|
| ![Application Launcher](screenshots/rofilauncher.gif) | ![Lock Screen](screenshots/slock.png) |

Configuration
-------------
Edit suckless/fjordwm/config.h for colors, keybindings, layouts, and rules.
Edit suckless/dwl/config.def.h for the baseline `dwl` configuration, and `suckless/dwl/config.mk` for build flags such as XWayland.

Profiles
--------
- Desktop: all status bar modules enabled
- Laptop: optimized settings for battery life

Patches
-------

| Patch | Description |
|-------|-------------|
| ActualFullscreen | Proper fullscreen without decorations |
| AltTagsDecoration | Alternative tag decoration |
| Alwayscenter | Center new windows |
| BarPadding | Padding around status bar |
| BarHeight | Customizable bar height |
| Cfacts | Client factoring for resizing |
| CycleLayouts | Cycle through layouts |
| NoTitle | Remove window titles |
| RainbowTags | Colored tag indicators |
| ScratchPads | Dropdown terminal and music player |
| Status2d | Enhanced status bar graphics |
| StatusButton | Clickable status items |
| StatusPadding | Padding around status text |
| StatusCmd | Custom status commands |
| Swallow | Parent-child window management |
| Systray-Iconsize | Customizable tray icons |
| UnderlineTags | Underline active tags |
| Vanitygaps | Configurable window gaps |

Components
----------
- Window manager: dwm with patches
- Wayland compositor: fjordwl (local dwl fork) with XWayland enabled in `config.mk`
- Status bars: **eww** on fjordwm (X11), Waybar on fjordwl by default (Polybar available as fallback)
- Notifications: dunst on fjordwm, swaync on fjordwl by default
- Application launcher: rofi with custom themes
- GTK theme: Carbon-Square
- BetterDiscord theme: bundled `achromatic24` theme + `custom.css`
- Terminal: kitty
- Compositor: picom
- Lock screen: slock

Recommendations
--------------

| Application | Purpose | Package |
|-------------|---------|---------|
| nwg-look | GTK settings | nwg-look |
| warpd | Vim-style cursor control | warpd |
| nm-applet | Network tray icon | network-manager-applet |
| unclutter | Hide idle cursor | unclutter |
| redshift | Blue light filter | redshift |
| flameshot | Screenshots | flameshot |
| udiskie | USB auto-mount | udiskie |
| rmpc | Rust TUI MPD client | mpd rmpc mpd-mpris |

Build
-----
After config changes to the X11 stack:

    cd suckless/fjordwm
    make clean install

For the Wayland path:

    ./suckless/build-suckless.sh --wm dwl --install-mode local --yes

The `dwl` build installs the compositor into `~/.local/bin` and the session file into `~/.local/share/wayland-sessions` when using local mode.

Troubleshooting
---------------

Build fails with permissions:
    sudo chown -R $USER:$USER ~/fjordwm
    chmod +x ~/fjordwm/scripts/*.sh

Status bar not updating:
    killall eww && ~/.fjordwm/eww/x11-startup.sh &

eww bar issues:
    ~/fjordwm/eww/verify-setup.sh  # Run verification script
    eww --config ~/fjordwm/eww logs  # Check eww logs

Need the old fjordwl widgets:
    ./eww/scripts/start.sh

GTK theme missing:
    cp -r ~/fjordwm/themes/Carbon-Square ~/.themes/

Keybindings not working:
    echo $XDG_CURRENT_DESKTOP
    echo $DESKTOP_SESSION

Files
-----
- suckless/fjordwm/config.h - main configuration (now uses eww bar)
- suckless/dwl/config.def.h - baseline dwl configuration
- suckless/dwl/config.mk - dwl build flags and XWayland toggle
- suckless/install-betterdiscord.sh - BetterDiscord installer and theme sync
- scripts/ - utility scripts
- eww/ - eww bar configuration for X11/dwm with widgets and startup scripts
- rofi/ - application launcher and larger menu configurations
- themes/ - GTK theme files
