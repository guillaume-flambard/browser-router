#!/bin/bash
set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$PROJECT_DIR/build"
APP_NAME="BrowserRouter"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"
DMG_PATH="$BUILD_DIR/$APP_NAME.dmg"
ARCH=${1:-$(uname -m)}

echo "==> BrowserRouter Build"
echo "    Target arch: $ARCH"
echo ""

# --- 1. Compile ---
echo "==> Compiling..."
mkdir -p "$BUILD_DIR"
swiftc \
    -O \
    -o "$BUILD_DIR/$APP_NAME" \
    "$PROJECT_DIR/Sources/"*.swift \
    -framework SwiftUI \
    -framework AppKit \
    -target "${ARCH}-apple-macos13.0"

echo "   ✓ Binary compiled"

# --- 2. Create .app bundle ---
echo "==> Creating .app bundle..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

cp "$BUILD_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
cp "$PROJECT_DIR/Resources/Info.plist" "$APP_BUNDLE/Contents/Info.plist"

# Copy resources
for res in AppIcon.icns MenuBarIcon.png MenuBarIcon@2x.png; do
    if [ -f "$PROJECT_DIR/Resources/$res" ]; then
        cp "$PROJECT_DIR/Resources/$res" "$APP_BUNDLE/Contents/Resources/$res"
    fi
done

echo "   ✓ .app bundle created"

# --- 3. Ad-hoc sign ---
echo "==> Code signing (ad-hoc)..."
codesign --force --deep --sign - "$APP_BUNDLE" 2>/dev/null
echo "   ✓ Signed"

# --- 4. Notarization check ---
echo ""
echo "==> Build complete!"
echo "    App: $APP_BUNDLE"
echo ""
echo "    To install: open $APP_BUNDLE"
echo "    (or run ./make-dmg.sh to create a DMG)"
