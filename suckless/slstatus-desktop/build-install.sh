#!/bin/sh

# Build and install slstatus, replacing any existing installation

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

echo "Cleaning old build..."
make clean || true

echo "Uninstalling old slstatus..."
sudo make uninstall || true

echo "Building slstatus..."
make

echo "Installing new slstatus..."
sudo make install

echo "Done! slstatus has been replaced."
