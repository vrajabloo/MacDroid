# CleanDroid Gaming

CleanDroid Gaming is a native SwiftUI macOS app for Apple Silicon Macs. It is a premium, gaming-focused launcher and manager for Android games using the official Google Android Emulator, Android SDK, ADB, and AVD tooling in the background.

It is not a custom emulator engine. The app provides a commercial-emulator-style control center around Google's emulator tools.

## What the MVP includes

- Dark graphite SwiftUI interface with neon Android accent styling
- macOS sidebar navigation
- Home dashboard with a large Play action
- Android SDK, ADB, emulator, SDK Manager, and AVD Manager detection
- Existing AVD detection
- Recommended `CleanDroid_Gaming` AVD creation using an ARM64 Google Play system image when available
- Start and stop emulator actions
- Installed app discovery through `adb shell pm list packages -3`
- App launch through `adb shell monkey`
- App uninstall through `adb uninstall`
- Favorite, recent, and installed filters in the game library
- Android app-info launch from each game card
- APK drag-and-drop installation through `adb install -r`
- Manual Android SDK path selection
- Android SDK license acceptance from the Settings screen
- Emulator boot waiting and readiness checks
- Connected emulator details such as model, Android version, API level, ABI, and serial
- Android Back, Home, and Recents buttons through targeted numeric `adb shell input keyevent`
- Home uses Android's launcher intent fallback first for more reliable behavior
- Official Google Emulator toolbar remains visible by default
- Transparent repair panels over the official toolbar for power, volume, rotate, screenshot, Back, Home, and Recents
- Manual CleanDroid controls window remains available from the Home dashboard
- Emulator serial preference when multiple ADB devices are connected
- Screenshot capture through `adb shell screencap`
- Recent logcat collection through `adb logcat`
- Clickable emulator icon in the sidebar and home dashboard
- Optional auto-start when the macOS app opens
- Optional auto-launch of the last played game after boot
- Boost & Repair screen for ADB restart, Android reboot, Play Store reset, and emulator network diagnostics
- Network Boost launch flag using `-dns-server`
- Balanced, Performance, Battery Saver, and Custom performance profiles
- Basic RAM, CPU, resolution, DPI, FPS, fullscreen, toolbar, and mode settings
- Key mapping profile UI and Codable data model with future input bridge and gamepad fields
- Manual test taps for saved key mappings through `adb shell input tap`
- Logs and troubleshooting screen with beginner-friendly command explanations

## Running the project

1. Open the `CleanDroidGaming` folder in Xcode.
2. Select the `CleanDroidGaming` executable scheme.
3. Run the app on macOS.

You can also verify compilation from Terminal:

```bash
cd CleanDroidGaming
swift build
```

To create a clickable macOS app bundle:

```bash
./Packaging/build-app.sh
```

Open `Build/CleanDroid Gaming.app` from Finder. Auto-start is enabled by default, so opening the app starts the selected emulator after SDK detection.

## Android SDK expectations

CleanDroid Gaming looks for tools in common locations:

- `$ANDROID_HOME`
- `$ANDROID_SDK_ROOT`
- `~/Library/Android/sdk`
- Tools available on `PATH`

Required tools:

- `adb`
- `emulator`
- `avdmanager`
- `sdkmanager`

For Play Store support, use an ARM64 Google Play system image, for example:

```text
system-images;android-35;google_apis_playstore;arm64-v8a
```

## Architecture

The project uses a simple MVVM-friendly shape:

- `App/` contains the SwiftUI app entry point.
- `Views/` contains SwiftUI screens and reusable view components.
- `ViewModels/` contains presentation state and view helpers.
- `Models/` contains Codable app, emulator, settings, log, and key mapping models.
- `Services/` wraps Android SDK commands and local persistence.
- `Managers/` contains `AppEnvironment`, the app-wide coordinator.
- `Utilities/` contains shell, JSON, path, and design helpers.
- `Documentation/` explains limitations and future features.

## Main services

- `AndroidSDKDetector`: finds Android SDK tools.
- `ADBService`: lists, launches, repairs, diagnoses, and uninstalls Android apps.
- `InputMappingExecutionService`: sends manual test taps for saved control mappings.
- `EmulatorService`: starts and stops the official emulator.
- `AVDManagerService`: lists and creates Android Virtual Devices, and writes no-frame gaming display settings.
- `OfficialEmulatorToolbarRepairService`: keeps Google's toolbar visible while routing its common buttons through ADB.
- `APKInstallerService`: installs APK files through ADB.
- `GameLibraryService`: merges live ADB data with saved local metadata.
- `KeyMappingService`: saves per-game control profiles.
- `LogService`: stores visible troubleshooting messages.
- `SettingsService`: saves gaming settings as JSON.
