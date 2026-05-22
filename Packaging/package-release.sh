#!/bin/zsh

# Creates zip and dmg files that can be uploaded to GitHub Releases.
# This keeps release packaging repeatable for local builds and CI.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$SCRIPT_DIR/Info.plist")"
APP_PATH="$PROJECT_DIR/Build/MacDroid.app"
ZIP_PATH="$PROJECT_DIR/Build/MacDroid-$VERSION-macOS-arm64.zip"
CHECKSUM_PATH="$ZIP_PATH.sha256"
DMG_PATH="$PROJECT_DIR/Build/MacDroid-$VERSION-macOS-arm64.dmg"
DMG_CHECKSUM_PATH="$DMG_PATH.sha256"

"$SCRIPT_DIR/build-app.sh"

echo "Creating release zip..."
rm -f "$ZIP_PATH" "$CHECKSUM_PATH"
ditto -c -k --keepParent "$APP_PATH" "$ZIP_PATH"

echo "Writing ZIP SHA-256 checksum..."
shasum -a 256 "$ZIP_PATH" > "$CHECKSUM_PATH"

"$SCRIPT_DIR/create-dmg.sh" --skip-build

echo "Done: $ZIP_PATH"
echo "Checksum: $CHECKSUM_PATH"
echo "Done: $DMG_PATH"
echo "Checksum: $DMG_CHECKSUM_PATH"
