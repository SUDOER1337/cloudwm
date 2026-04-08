# fjordwl

`fjordwl` is the Wayland compositor in this repo. It is a local `dwl` fork
rebranded around the FjordWM stack and configured to reuse as much of the
existing FjordWM workflow as makes sense on Wayland.

## What Changed

- Installs as `fjordwl` and ships a `fjordwl.desktop` session entry.
- Keeps the upstream `dwl` core while exposing `dwl` IPC v2 for Waybar tags
  and window/layout state, plus the local JSON window status helper.
- Keeps the bundled Waybar `dwl/tags` module compatible with `fjordwl`
  without requiring a custom workspace script.
- Uses FjordWM-inspired colors, app rules, launcher bindings, and session
  helpers, with Waybar and swaync started by default.
- Starts the existing FjordWM Wayland userland from
  `~/fjordwm/scripts/fjordwl-session.sh`.

## Build

Use the repo helper:

```sh
./suckless/build-suckless.sh --wm fjordwl --install-mode local --yes
```

Or build directly:

```sh
cd suckless/fjordwl
make
sudo make install
```

When `wlroots` is rebuilt locally, this repo's `config.mk` prefers:

- `~/.local/wlroots-0.19/lib/pkgconfig`
- `~/.local/wlroots-0.19/share/pkgconfig`

and embeds `RUNPATH` for `~/.local/wlroots-0.19/lib`.

Verify linkage after install:

```sh
ldd ~/.local/bin/fjordwl | rg 'wlroots|display-info|not found'
readelf -d ~/.local/bin/fjordwl | rg 'RUNPATH|RPATH'
```

## Config

- `config.def.h`: compositor defaults, rules, keybindings
- `config.mk`: build flags and XWayland toggle
- `~/fjordwm/scripts/fjordwl-session.sh`: session startup

## Upstream

Upstream `dwl` source and patches remain here:

- https://codeberg.org/dwl/dwl
- https://codeberg.org/dwl/dwl-patches
