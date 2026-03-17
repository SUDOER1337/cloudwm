#!/bin/bash
# eww bar verification and quick-start script

set -e

EWW_DIR="$HOME/fjordwm/eww"
EWW_CMD="eww --config $EWW_DIR"

echo "=== eww Bar Setup Verification ==="
echo

# Check eww installation
if ! command -v eww &>/dev/null; then
    echo "❌ eww is not installed"
    echo "   Install with: sudo pacman -S eww (Arch) or equivalent for your distro"
    exit 1
fi

echo "✓ eww installed: $(eww --version)"
echo

# Check configuration files
echo "Checking configuration files:"
for file in eww.yuck eww.scss x11-startup.sh scripts/workspaces.sh; do
    if [[ -f "$EWW_DIR/$file" ]]; then
        echo "  ✓ $file"
    else
        echo "  ❌ $file (missing)"
        exit 1
    fi
done
echo

# Try to start daemon
echo "Testing eww daemon startup..."
pkill -f "eww daemon" 2>/dev/null || true
sleep 0.5

if timeout 3 $EWW_CMD daemon >/dev/null 2>&1; then
    echo "✓ eww daemon started successfully"
else
    echo "⚠ eww daemon may have issues, checking logs..."
    $EWW_CMD logs || true
fi
sleep 1

# List active windows
echo
echo "Active eww windows:"
$EWW_CMD list-windows || echo "  (no windows open)"

# Check dwm config
echo
echo "Checking dwm configuration:"
if grep -q "eww/x11-startup.sh" "$HOME/fjordwm/suckless/fjordwm/config.h"; then
    echo "✓ dwm is configured to use eww bar"
else
    echo "⚠ dwm may not be configured for eww bar"
fi

echo
echo "=== Setup Verification Complete ==="
echo
echo "To start the eww bar manually:"
echo "  $EWW_DIR/x11-startup.sh"
echo
echo "To open individual windows:"
echo "  $EWW_CMD open bar"
echo "  $EWW_CMD open control-panel"
echo "  $EWW_CMD open power-panel"
echo
echo "To view logs:"
echo "  $EWW_CMD logs"
echo
echo "For more info, see: $EWW_DIR/README.md"
