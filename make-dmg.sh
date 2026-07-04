#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
APP_NAME="BrowserRouter"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
DMG_PATH="$BUILD_DIR/$APP_NAME.dmg"
STAGING_DIR="$BUILD_DIR/.dmg-staging"
VOLUME_NAME="BrowserRouter"
BG_PATH="$PROJECT_DIR/Resources/dmg-bg.png"

if [ ! -d "$APP_BUNDLE" ]; then
    echo "Error: $APP_BUNDLE not found. Run build.sh first."
    exit 1
fi

echo "==> Creating DMG..."
rm -rf "$STAGING_DIR"
mkdir -p "$STAGING_DIR/.background"

cp -R "$APP_BUNDLE" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"

# Copy background into staging so it's embedded from the start
if [ -f "$BG_PATH" ]; then
    cp "$BG_PATH" "$STAGING_DIR/.background/background.png"
fi

TEMP_DMG="$BUILD_DIR/.temp-${APP_NAME}.dmg"
rm -f "$TEMP_DMG"

hdiutil create \
    -volname "$VOLUME_NAME" \
    -srcfolder "$STAGING_DIR" \
    -ov \
    -format UDRW \
    -fs HFS+ \
    "$TEMP_DMG" 2>/dev/null

# Wait for mount
MOUNT_POINT="/Volumes/$VOLUME_NAME"
for i in {1..15}; do
    if [ -d "$MOUNT_POINT" ]; then break; fi
    sleep 0.5
done

# Configure Finder window via AppleScript
if [ -d "$MOUNT_POINT" ]; then
    osascript -e "
tell application \"Finder\"
    tell disk \"$VOLUME_NAME\"
        set current view to icon view
        set toolbar visible to false
        set statusbar visible to false
        set icon size of icon view options to 80
        set background picture of icon view options to file \".background:background.png\"
        set arrangement of icon view options to not arranged
        set position of item \"$APP_NAME.app\" to {170, 200}
        set position of item \"Applications\" to {430, 200}
        close
    end tell
end tell" 2>/dev/null || echo "   (Finder settings optional - continuing)"

    sleep 2
fi

# Detach
for i in {1..10}; do
    if hdiutil detach "$MOUNT_POINT" -quiet 2>/dev/null; then break; fi
    sleep 1
done

# Convert to read-only compressed DMG
rm -f "$DMG_PATH"
hdiutil convert "$TEMP_DMG" \
    -format UDZO \
    -imagekey zlib-level=9 \
    -o "$DMG_PATH" 2>/dev/null

rm -f "$TEMP_DMG"
rm -rf "$STAGING_DIR"

echo "   ✓ DMG created: $DMG_PATH ($(du -h "$DMG_PATH" | cut -f1))"
echo ""
echo "    To distribute, share BrowserRouter.dmg"
echo "    To install: open the DMG then drag BrowserRouter.app to Applications"
