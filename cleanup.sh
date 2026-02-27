#!/bin/bash
echo "Cleaning cloudwm project..."

# Remove build artifacts
echo "Removing object files..."
find . -name "*.o" -delete

# Remove compiled binaries
echo "Removing compiled binaries..."
find . -name "dwm" -delete
find . -name "slock" -delete  
find . -name "slstatus" -delete
find . -name "compiledwm" -delete

# Remove backup files
echo "Removing backup files..."
find . -name "*.orig" -delete
find . -name "*.bk" -delete
find . -name "*.rej" -delete

# Remove temporary files
echo "Removing temporary files..."
rm -f test_powermenu.sh
find . -name "*.swp" -delete
find . -name "*.swo" -delete

echo "Cleanup complete!"
echo "Consider moving personal data:"
echo "  - screenshots/ (13MB)"
echo "  - wallpapers/ (20MB)" 
echo "  - config-backups/"
echo "  - .pnotes/"
