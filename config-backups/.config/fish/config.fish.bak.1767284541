# ─── Fish Interactive Setup ───────────────────────────────────────────────
if status is-interactive
    fastfetch
end

function demucs-wrapper --wraps ~/.local/bin/demucs-wrapper
    command bash ~/.local/bin/demucs-wrapper $argv
end

function ardour-helper --wraps ~/.local/bin/ardour-helper
    command bash ~/.local/bin/ardour-helper $argv
end


# ─── Autostart X on TTY1 ──────────────────────────────────────────────────
if test (tty) = /dev/tty1
     Prevent infinite loops when X exits
        if not set -q DISPLAY
         fastfetch
        exec startx
    end
 end


# pnpm
set -gx PNPM_HOME "/home/thinker/.local/share/pnpm"
if not string match -q -- $PNPM_HOME $PATH
  set -gx PATH "$PNPM_HOME" $PATH
end
# pnpm end
