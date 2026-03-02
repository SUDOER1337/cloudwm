# === Environment ===
set -gx TERM screen-256color
set -gx EDITOR nvim
set -gx VISUAL nvim

fish_vi_key_bindings
# Faster mode switching (less delay after pressing Esc)
set -g fish_escape_delay_ms 10

# Show your current mode in the prompt (fish already supports this variable)
function fish_mode_prompt
    switch $fish_bind_mode
        case default
            echo -n 'NORMAL'
        case insert
            echo -n 'INSERT'
        case replace_one
            echo -n 'REPLACE'
        case visual
            echo -n 'VISUAL'
    end
end

# pnpm
set -gx PNPM_HOME "/home/thinker/.local/share/pnpm"
if not string match -q -- $PNPM_HOME $PATH
    set -gx PATH "$PNPM_HOME" $PATH
end
# pnpm end

# === Greeting (disable default fish greeting) ===
set -g fish_greeting ""

# === Gruvbox Colors ===
set -U fish_color_normal EBDBB2
set -U fish_color_command B8BB26
set -U fish_color_param FABD2F
set -U fish_color_keyword FB4934
set -U fish_color_quote 83A598
set -U fish_color_redirection D3869B
set -U fish_color_end A89984
set -U fish_color_error CC241D
set -U fish_color_comment 928374
set -U fish_color_search_match --background=3C3836
set -U fish_color_selection --background=504945
set -U fish_color_operator FE8019
set -U fish_color_escape B16286
set -U fish_color_autosuggestion 7C6F64

# === Aliases ===
alias ls "exa --icons --group-directories-first"
alias ll "exa -lh --icons"
alias la "exa -lha --icons"
alias cat bat
alias vim nvim
alias cls clear
alias sudo doas

# === Git Quick ===
alias gs "git status"
alias ga "git add"
alias gc "git commit"
alias gp "git push"

# === Better cd ===
function ..
    cd ..
end

function ...
    cd ../..
end

# ─── Fish Interactive Setup ───────────────────────────────────────────────
if status is-interactive
    fastfetch

    # Auto-start tmux (but don't nest). Skip TTY1 so startx block can run.
    if not set -q TMUX; and not set -q DISPLAY; and test (tty) != /dev/tty1
        tmux attach -t main 2>/dev/null; or tmux new -s main
    end
end

function demucs-wrapper --wraps ~/.local/bin/demucs-wrapper
    command bash ~/.local/bin/demucs-wrapper $argv
end

function ardour-helper --wraps ~/.local/bin/ardour-helper
    command bash ~/.local/bin/ardour-helper $argv
end

# ─── Autostart X on TTY1 ─────────────────────────────────────────────
if test (tty) = /dev/tty1
    # Prevent infinite loops when X exits
    if not set -q DISPLAY
        fastfetch
        exec startx
    end
end

# OpenClaw Completion
source "/home/thinker/.openclaw/completions/openclaw.fish"
