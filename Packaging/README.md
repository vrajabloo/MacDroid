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

To create a zip file for GitHub Releases:

```bash
./Packaging/package-release.sh
```

The output is:

```text
Build/MacDroid-<version>-macOS-arm64.zip
Build/MacDroid-<version>-macOS-arm64.zip.sha256
```
