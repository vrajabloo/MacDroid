#!/bin/zsh

# Builds a clickable macOS .app bundle for MacDroid.
# Opening this app bundle starts the SwiftUI launcher, and the default settings
# auto-start the selected Android emulator like a commercial emulator app.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
APP_NAME="MacDroid"
APP_DIR="$PROJECT_DIR/Build/$APP_NAME.app"
LEGACY_APP_DIR="$PROJECT_DIR/Build/CleanDroid Gaming.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
ICON_PATH="$SCRIPT_DIR/AppIcon.icns"
ENTITLEMENTS_PATH="$SCRIPT_DIR/MacDroid.entitlements"
SIGNING_IDENTITY="${MACDROID_SIGNING_IDENTITY:-}"

echo "Building MacDroid in release mode..."
swift build -c release --package-path "$PROJECT_DIR"

echo "Generating app icon..."
swift "$SCRIPT_DIR/make-icon.swift" "$SCRIPT_DIR"

echo "Creating $APP_NAME.app..."
rm -rf "$APP_DIR"
rm -rf "$LEGACY_APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

cp "$PROJECT_DIR/.build/release/MacDroid" "$MACOS_DIR/MacDroid"
cp "$SCRIPT_DIR/Info.plist" "$CONTENTS_DIR/Info.plist"
cp "$ICON_PATH" "$RESOURCES_DIR/AppIcon.icns"
chmod +x "$MACOS_DIR/MacDroid"

if command -v codesign >/dev/null 2>&1; then
    if [[ -n "$SIGNING_IDENTITY" ]]; then
        echo "Applying Developer ID signature with hardened runtime..."
        codesign \
            --force \
            --deep \
            --options runtime \
            --timestamp \
            --entitlements "$ENTITLEMENTS_PATH" \
            --sign "$SIGNING_IDENTITY" \
            "$APP_DIR" >/dev/null
    else
        echo "Applying local ad-hoc code signature..."
        codesign --force --deep --sign - "$APP_DIR" >/dev/null
    fi
fi

echo "Done: $APP_DIR"
echo "Double-click the app bundle to open MacDroid and auto-start the emulator."
