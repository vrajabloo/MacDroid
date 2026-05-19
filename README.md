# CleanDroid Gaming

CleanDroid Gaming is a native SwiftUI macOS app for Apple Silicon Macs. It is a polished, gaming-focused launcher and control center for Android games, built around the official Google Android Emulator, Android SDK, ADB, and AVD tools.

CleanDroid Gaming is not a custom Android emulator engine. It is a premium macOS wrapper and manager for Google's emulator stack, designed to feel closer to commercial Android gaming emulators such as MuMu Player, BlueStacks, or LDPlayer.

## What It Does

CleanDroid Gaming turns the Android Emulator toolchain into a beginner-friendly gaming app:

- Detects Android SDK tools automatically.
- Creates or selects a gaming AVD.
- Starts and stops the official Android Emulator.
- Shows emulator status and connected device details.
- Installs APK files through drag and drop.
- Lists installed Android apps and games through ADB.
- Launches games directly from macOS.
- Provides performance presets for gaming.
- Repairs unreliable Google Emulator toolbar buttons with ADB-backed controls.
- Provides troubleshooting tools for ADB, Play Store, boot, and network issues.
- Saves key mapping profiles for future keyboard, mouse, and gamepad support.

## Current Feature Set

### Premium macOS UI

- Native SwiftUI application.
- Dark graphite gaming interface.
- Neon Android accent color.
- macOS sidebar navigation.
- Home dashboard with large play action.
- Game library cards.
- Recent games and favorite games.
- Polished cards, panels, status badges, and controls.
- Beginner-friendly logs and messages.

### Emulator Management

- Android SDK detection.
- ADB detection.
- Android Emulator binary detection.
- AVD Manager and SDK Manager detection.
- Existing AVD discovery.
- Recommended `CleanDroid_Gaming` AVD creation.
- ARM64 Google Play image preference for Apple Silicon.
- Start, stop, restart, and reboot flows.
- Emulator boot waiting and status detection.
- Connected Android device information:
  - model
  - Android version
  - API level
  - ABI
  - serial

### Game Library

- Installed app discovery through:

```bash
adb shell pm list packages -3 -f
```

- Game cards with generated artwork.
- App name and package name display.
- Version display when available.
- Last played tracking.
- Filters:
  - Installed
  - Recent
  - Favorites
- Search by app name or package name.
- Launch app/game.
- Uninstall app/game.
- Open Android App Info.
- Create key mapping profile.

### APK Installer

- Drag and drop APK installation.
- ADB install using:

```bash
adb install -r <apk>
```

- Install progress state.
- Success and failure logs.
- Library refresh after installation.

### Play Store Support

- Detects whether a Google Play ARM64 system image is available.
- Opens Play Store inside the emulator.
- Warns when the selected system image does not support Play Store.
- Provides a Play Store reset action for stuck or slow downloads.

### Boost & Repair

The Boost screen contains quick fixes for common emulator problems:

- Restart ADB.
- Reboot Android inside the emulator.
- Clear Play Store state.
- Open Play Store.
- Rescan SDK and emulator state.
- Run emulator ping diagnostics.
- Enable Network Boost.

Network Boost launches the official emulator with a direct DNS flag:

```bash
-dns-server 8.8.8.8,1.1.1.1
```

This can help when slow DNS resolution is part of the Play Store download problem.

### Performance Profiles

CleanDroid includes four tuning profiles:

- Balanced
- Performance
- Battery Saver
- Custom

Profiles manage:

- RAM allocation
- CPU core count
- resolution
- DPI
- FPS target preference
- performance mode
- battery-saving mode

Manual options include:

- RAM: 2 GB, 4 GB, 6 GB, 8 GB
- CPU: 2, 4, 6, 8 cores
- Resolution: 720p, 1080p, 1440p
- DPI: 240, 320, 420, 560
- FPS target: 30, 60, 90, 120
- Window size preference
- Fullscreen preference
- Auto-start emulator when the app opens
- Auto-launch last game after boot

### Official Emulator Toolbar Repair

The official Google Android Emulator toolbar stays visible by default. On some macOS setups, the toolbar visually appears but its buttons do not reliably trigger actions. CleanDroid works around this without patching Google's emulator binary.

CleanDroid places transparent helper panels over the common official toolbar buttons and routes those clicks through ADB.

Supported repaired toolbar actions:

- Power
- Volume Up
- Volume Down
- Screenshot
- Rotate Left
- Rotate Right
- Back
- Home
- Recents

The user sees the familiar Google toolbar, while CleanDroid provides reliable actions behind it.

### Key Mapping MVP

The key mapping system is currently a profile and architecture MVP:

- Per-game mapping profiles.
- Keyboard, mouse, and gamepad mapping types.
- Normalized tap positions.
- Visual tap layout.
- WASD sample profile creation.
- Manual test taps through:

```bash
adb shell input tap <x> <y>
```

- Input bridge mode fields:
  - ADB Tap
  - Overlay Planned
  - Gamepad Planned
- Gamepad-ready profile fields.

Live real-time keyboard/mouse/gamepad injection is planned for a later version.

### Logs & Troubleshooting

The Logs screen shows beginner-friendly explanations before commands run. It tracks:

- SDK detection messages.
- ADB commands.
- Emulator start and stop commands.
- AVD creation messages.
- APK install errors.
- Play Store errors.
- Logcat output.
- Network diagnostics.

## Requirements

- macOS 14 or newer.
- Apple Silicon Mac recommended.
- Xcode or Swift toolchain.
- Android SDK installed.
- Android Emulator installed.
- Android SDK command-line tools installed.

Required Android tools:

- `adb`
- `emulator`
- `avdmanager`
- `sdkmanager`

CleanDroid looks in:

- `$ANDROID_HOME`
- `$ANDROID_SDK_ROOT`
- `~/Library/Android/sdk`
- tools available on `PATH`

For Play Store support, install an ARM64 Google Play system image, for example:

```text
system-images;android-35;google_apis_playstore;arm64-v8a
```

## Build

From the project folder:

```bash
swift build
```

To create a clickable macOS app bundle:

```bash
./Packaging/build-app.sh
```

Then open:

```text
Build/CleanDroid Gaming.app
```

The app is locally ad-hoc signed by the packaging script.

## Project Structure

```text
CleanDroidGaming/
  App/
  Views/
  ViewModels/
  Models/
  Services/
  Managers/
  Utilities/
  Resources/
  Documentation/
  Packaging/
```

## Architecture

The codebase intentionally stays beginner-friendly:

- SwiftUI for UI.
- ObservableObject for app state.
- async/await for command flows.
- Process for Android SDK commands.
- Codable JSON for local settings, library cache, and key profiles.
- FileManager for local config storage.
- MVVM-style separation without excessive abstraction.

Main services:

- `AndroidSDKDetector`: finds Android SDK paths and tool availability.
- `ADBService`: wraps ADB commands for apps, navigation, repair, diagnostics, and Play Store.
- `EmulatorService`: starts and stops the official Google Android Emulator.
- `AVDManagerService`: lists, creates, and configures AVDs.
- `APKInstallerService`: installs APK files.
- `GameLibraryService`: merges live ADB app data with local metadata.
- `KeyMappingService`: saves and loads input profiles.
- `InputMappingExecutionService`: sends manual tap tests.
- `OfficialEmulatorToolbarRepairService`: keeps Google's toolbar visible while repairing actions.
- `LogService`: stores beginner-readable logs.
- `SettingsService`: persists gaming settings.

## Important Limitations

CleanDroid Gaming does not include:

- custom Android emulator engine
- custom hypervisor
- custom Android runtime
- bundled Android system images
- Play Store redistribution
- guaranteed FPS control for every emulator version
- full real-time key injection in the MVP
- binary patching of Google's emulator

CleanDroid is a gaming-focused wrapper around the official Google Android Emulator.

## Roadmap

Planned next steps:

- Live keyboard/mouse overlay injection.
- Real gamepad event bridge.
- Per-game performance profiles.
- Screen recording.
- Screenshot gallery.
- Macro recorder.
- Multi-instance management.
- Cloud save integration.
- APK icon and artwork extraction.
- Better streaming progress for APK installs.
- Native fullscreen orchestration for emulator windows.

## Documentation

More details:

- [Documentation/README.md](Documentation/README.md)
- [Documentation/LIMITATIONS.md](Documentation/LIMITATIONS.md)
- [Documentation/FUTURE_FEATURES.md](Documentation/FUTURE_FEATURES.md)
