#!/bin/zsh

# Builds a clickable macOS .app bundle for CleanDroid Gaming.
# Opening this app bundle starts the SwiftUI launcher, and the default settings
# auto-start the selected Android emulator like a commercial emulator app.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
APP_NAME="CleanDroid Gaming"
APP_DIR="$PROJECT_DIR/Build/$APP_NAME.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"
RESOURCES_DIR="$CONTENTS_DIR/Resources"
ICON_PATH="$SCRIPT_DIR/AppIcon.icns"

echo "Building CleanDroid Gaming in release mode..."
swift build -c release --package-path "$PROJECT_DIR"

echo "Generating app icon..."
swift "$SCRIPT_DIR/make-icon.swift" "$SCRIPT_DIR"

echo "Creating $APP_NAME.app..."
rm -rf "$APP_DIR"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"

cp "$PROJECT_DIR/.build/release/CleanDroidGaming" "$MACOS_DIR/CleanDroidGaming"
cp "$SCRIPT_DIR/Info.plist" "$CONTENTS_DIR/Info.plist"
cp "$ICON_PATH" "$RESOURCES_DIR/AppIcon.icns"
chmod +x "$MACOS_DIR/CleanDroidGaming"

if command -v codesign >/dev/null 2>&1; then
    echo "Applying local ad-hoc code signature..."
    codesign --force --deep --sign - "$APP_DIR" >/dev/null
fi

echo "Done: $APP_DIR"
echo "Double-click the app bundle to open CleanDroid Gaming and auto-start the emulator."
