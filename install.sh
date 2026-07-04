#!/bin/bash
set -euo pipefail

# BrowserRouter installer
# Run this from the project directory or use the .dmg

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
APP_NAME="BrowserRouter"
APP_SOURCE="$SCRIPT_DIR/build/$APP_NAME.app"
APP_DEST="$HOME/Applications/$APP_NAME.app"
DMG_SOURCE="$SCRIPT_DIR/build/$APP_NAME.dmg"

if [ -d "$APP_SOURCE" ]; then
    echo "Installing from build/$APP_NAME.app ..."
    mkdir -p "$HOME/Applications"
    cp -R "$APP_SOURCE" "$APP_DEST"
    echo "✓ Copied to $APP_DEST"
elif [ -f "$DMG_SOURCE" ]; then
    echo "Mounting DMG to install..."
    hdiutil attach "$DMG_SOURCE" -mountpoint /tmp/browserrouter-install -quiet
    mkdir -p "$HOME/Applications"
    cp -R "/tmp/browserrouter-install/$APP_NAME.app" "$APP_DEST"
    hdiutil detach /tmp/browserrouter-install -quiet
    echo "✓ Installed from DMG"
else
    echo "Error: build/$APP_NAME.app or build/$APP_NAME.dmg not found."
    echo "Run './build.sh' first, or install via the .dmg file."
    exit 1
fi

# Register with Launch Services
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP_DEST" 2>/dev/null

echo ""
echo "BrowserRouter installed!"
echo "→ Launch it from your Applications folder"
echo "→ Click 'Set as Default Browser' in the menubar"
