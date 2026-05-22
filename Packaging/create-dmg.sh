#!/bin/zsh

# Creates a drag-to-Applications DMG for MacDroid.
# The DMG can be ad-hoc signed for local testing or Developer ID signed when
# MACDROID_SIGNING_IDENTITY is set in the environment.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$SCRIPT_DIR/Info.plist")"
APP_PATH="$PROJECT_DIR/Build/MacDroid.app"
DMG_STAGING="$PROJECT_DIR/Build/dmg-staging"
DMG_PATH="$PROJECT_DIR/Build/MacDroid-$VERSION-macOS-arm64.dmg"
CHECKSUM_PATH="$DMG_PATH.sha256"
SKIP_BUILD="${1:-}"
SIGNING_IDENTITY="${MACDROID_SIGNING_IDENTITY:-}"

if [[ "$SKIP_BUILD" != "--skip-build" ]]; then
    "$SCRIPT_DIR/build-app.sh"
fi

if [[ ! -d "$APP_PATH" ]]; then
    echo "Missing $APP_PATH. Run ./Packaging/build-app.sh first." >&2
    exit 1
fi

echo "Creating DMG staging folder..."
rm -rf "$DMG_STAGING" "$DMG_PATH" "$CHECKSUM_PATH"
mkdir -p "$DMG_STAGING"

cp -R "$APP_PATH" "$DMG_STAGING/MacDroid.app"
ln -s /Applications "$DMG_STAGING/Applications"

cat > "$DMG_STAGING/README - Install.txt" <<'EOF'
MacDroid install

1. Drag MacDroid.app into Applications.
2. Open MacDroid from Applications.
3. If macOS blocks the app, right-click MacDroid.app and choose Open.
4. Install Android Studio or Android SDK tools if Setup Wizard asks for them.

MacDroid is a launcher and manager for the official Google Android Emulator.
It is not a custom emulator engine.
EOF

echo "Creating compressed DMG..."
hdiutil create \
    -volname "MacDroid" \
    -srcfolder "$DMG_STAGING" \
    -ov \
    -format UDZO \
    "$DMG_PATH" >/dev/null

if [[ -n "$SIGNING_IDENTITY" ]] && command -v codesign >/dev/null 2>&1; then
    echo "Signing DMG with Developer ID..."
    codesign --force --timestamp --sign "$SIGNING_IDENTITY" "$DMG_PATH" >/dev/null
fi

echo "Writing DMG SHA-256 checksum..."
shasum -a 256 "$DMG_PATH" > "$CHECKSUM_PATH"

echo "Done: $DMG_PATH"
