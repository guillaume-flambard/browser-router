#!/bin/bash
set -e

# BrowserRouter — URL Router Installer
# Routes local dev URLs (localhost, 192.168.*, *.test, etc.) to Chrome
# and everything else to Safari

APP_NAME="BrowserRouter"
APP_SOURCE="$(cd "$(dirname "$0")" && pwd)/$APP_NAME.app"
APP_DEST="$HOME/Applications/$APP_NAME.app"
BUNDLE_ID="com.user.browserrouter"

echo "==> BrowserRouter Installer"
echo ""

# 1. Copy app to ~/Applications
mkdir -p "$HOME/Applications"
if [ -d "$APP_DEST" ]; then
    echo "   Removing previous installation..."
    rm -rf "$APP_DEST"
fi
cp -R "$APP_SOURCE" "$APP_DEST"
echo "   ✓ Copied $APP_NAME.app → $APP_DEST"

# 2. Register with Launch Services
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$APP_DEST" 2>/dev/null
echo "   ✓ Registered with Launch Services"

# 3. Set as default http/https handler
swift -e '
import Foundation
LSSetDefaultHandlerForURLScheme("http" as CFString, "'$BUNDLE_ID'" as CFString)
LSSetDefaultHandlerForURLScheme("https" as CFString, "'$BUNDLE_ID'" as CFString)
' 2>/dev/null
echo "   ✓ Set as default browser handler"

echo ""
echo "==> Done! BrowserRouter is now your default browser."
echo "    • localhost, *.test, *.local, *.dev, 10.*, 192.168.* → Chrome"
echo "    • Everything else → Safari"
echo ""
echo "    To change this, go to System Settings > Desktop & Dock"
echo "    > Default web browser and select another option."
