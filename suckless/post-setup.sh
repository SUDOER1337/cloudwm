#!/usr/bin/env bash
set -euo pipefail

usage() {
    cat <<'EOF'
Usage: ./suckless/post-setup.sh

Applies desktop-session settings that require an active GUI session.
EOF
}

apply_nemo_thumbnail_settings() {
    if ! command -v gsettings >/dev/null 2>&1; then
        echo "Skipping Nemo thumbnail settings: gsettings not found."
        return
    fi

    if gsettings set org.nemo.preferences show-image-thumbnails 'always' >/dev/null 2>&1 &&
        gsettings set org.nemo.preferences thumbnail-limit 10737418240 >/dev/null 2>&1; then
        echo "Applied Nemo thumbnail settings."
    else
        echo "Skipping Nemo thumbnail settings: no active GUI session detected."
    fi
}

case "${1:-}" in
    --help|-h)
        usage
        exit 0
        ;;
    "")
        ;;
    *)
        echo "Unknown argument: $1"
        usage
        exit 1
        ;;
esac

echo "Running post-setup tasks..."
apply_nemo_thumbnail_settings
echo "Post-setup tasks complete."
