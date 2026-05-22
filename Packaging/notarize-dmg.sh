#!/bin/zsh

# Submits a Developer ID signed DMG to Apple notarization and staples the ticket.
# Before running, create a notarytool profile, for example:
# xcrun notarytool store-credentials "MacDroidNotary" --apple-id "you@example.com" --team-id "TEAMID" --password "app-specific-password"

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$SCRIPT_DIR/Info.plist")"
DMG_PATH="${1:-$PROJECT_DIR/Build/MacDroid-$VERSION-macOS-arm64.dmg}"
NOTARY_PROFILE="${MACDROID_NOTARY_PROFILE:-MacDroidNotary}"

if [[ ! -f "$DMG_PATH" ]]; then
    echo "Missing DMG: $DMG_PATH" >&2
    exit 1
fi

echo "Submitting $DMG_PATH to Apple notarization..."
xcrun notarytool submit "$DMG_PATH" \
    --keychain-profile "$NOTARY_PROFILE" \
    --wait

echo "Stapling notarization ticket..."
xcrun stapler staple "$DMG_PATH"

echo "Validating stapled DMG..."
xcrun stapler validate "$DMG_PATH"
