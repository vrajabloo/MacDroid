# Packaging

# Packaging

Run this script to create a clickable macOS app bundle:

```bash
./Packaging/build-app.sh
```

The output is:

```text
Build/MacDroid.app
```

Double-click that app bundle in Finder. By default, MacDroid starts the selected emulator automatically after detecting the Android SDK tools.

To create release assets for GitHub Releases:

```bash
./Packaging/package-release.sh
```

The output is:

```text
Build/MacDroid-<version>-macOS-arm64.zip
Build/MacDroid-<version>-macOS-arm64.zip.sha256
Build/MacDroid-<version>-macOS-arm64.dmg
Build/MacDroid-<version>-macOS-arm64.dmg.sha256
```

## Developer ID Signing

For local development, the app is ad-hoc signed automatically. For public distribution, set a Developer ID identity before packaging:

```bash
export MACDROID_SIGNING_IDENTITY="Developer ID Application: Your Name (TEAMID)"
./Packaging/package-release.sh
```

When that variable is set, `build-app.sh` signs `MacDroid.app` with hardened runtime and `Packaging/MacDroid.entitlements`.

## Notarization

Create a notarytool profile once:

```bash
xcrun notarytool store-credentials "MacDroidNotary" \
  --apple-id "you@example.com" \
  --team-id "TEAMID" \
  --password "app-specific-password"
```

Then notarize and staple the DMG:

```bash
export MACDROID_NOTARY_PROFILE="MacDroidNotary"
./Packaging/notarize-dmg.sh Build/MacDroid-<version>-macOS-arm64.dmg
```

Notarization requires an Apple Developer account and a real Developer ID certificate.
