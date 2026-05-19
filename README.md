# CleanDroid Gaming

Native SwiftUI macOS MVP for a premium Android gaming launcher on Apple Silicon.

CleanDroid Gaming is a commercial-emulator-style control center around the official Google Android Emulator, Android SDK, ADB, and AVD tools. It does not implement a custom emulator engine.

## Quick start

```bash
cd CleanDroidGaming
swift build
```

Open the folder in Xcode to run the SwiftUI app.

To build a clickable macOS app bundle:

```bash
./Packaging/build-app.sh
```

Then double-click `Build/CleanDroid Gaming.app`. The default setting starts the selected emulator automatically when the app opens.

Current MVP highlights:

- SDK/ADB/emulator detection
- Manual SDK path selection
- Recommended ARM64 Google Play AVD creation
- APK drag-and-drop install
- Installed app launch and uninstall
- Library filters for installed, recent, and favorite games
- Emulator screenshot and logcat tools
- Boost & Repair screen for Network Boost, ADB restart, Android reboot, Play Store reset, and ping diagnostics
- Performance profiles for Balanced, Performance, Battery Saver, and Custom tuning
- Official Google Emulator toolbar stays visible by default
- Transparent toolbar repair layer that routes Google toolbar clicks through reliable ADB actions
- Optional manual CleanDroid controls window for troubleshooting
- Key mapping profiles with manual ADB tap tests and gamepad-ready profile fields
- Beginner-friendly logs

Detailed documentation lives in `Documentation/`.
