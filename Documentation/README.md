# CleanDroid Gaming Documentation

CleanDroid Gaming is a native SwiftUI macOS app for Apple Silicon Macs. It provides a premium gaming launcher and manager around the official Google Android Emulator, Android SDK, ADB, and AVD tools.

It does not emulate Android by itself. The Android runtime, virtualization, system images, Play Store support, and device behavior all come from Google's official emulator stack.

## Design Goal

The goal is to make the official Android Emulator feel like a beginner-friendly gaming product:

- one clear app icon
- one dashboard
- one library
- one APK installer
- one repair area
- simple settings
- readable logs

Users should not need to remember Terminal commands for common tasks.

## Screens

### Home

The Home dashboard is the launch center:

- large Start/Play action
- Stop button
- SDK and device status
- installed app count
- ADB status
- Play Store support status
- recent games
- selected AVD
- APK drop zone
- screenshot and logcat shortcuts

### Library

The Library screen reads installed user apps from Android through ADB. It keeps local metadata such as favorites and last-played timestamps.

Library tools:

- search
- installed filter
- recent filter
- favorites filter
- launch game
- uninstall game
- open Android App Info
- create key mapping profile

### APK Installer

The APK Installer accepts files by drag and drop or browse flow. It installs APKs through:

```bash
adb install -r <apk>
```

After installation, the app refreshes the library.

### Boost

The Boost screen provides quick repair actions:

- Restart ADB
- Reboot Android
- Clear Play Store State
- Open Play Store
- Rescan environment
- Run ping diagnostics
- Enable direct DNS launch mode

Network Boost uses:

```bash
emulator -dns-server <servers>
```

### Key Mapping

The Key Mapping screen stores per-game input profiles. The current MVP supports saved mappings and manual tap tests. It prepares the model for:

- live keyboard overlay
- mouse mapping
- gamepad event bridging
- per-game profiles

### Settings

Settings include:

- Android SDK path
- SDK auto-detection
- SDK license acceptance
- performance profile
- RAM preset
- CPU preset
- resolution preset
- DPI preset
- FPS target
- direct DNS mode
- emulator toolbar visibility
- toolbar repair
- auto-start
- auto-launch last game
- fullscreen preference

### Logs

Logs show user-friendly explanations and the command behind each SDK operation. This is intentionally educational, so beginner developers can understand what the wrapper is doing.

## Command Strategy

CleanDroid runs official Android tools through `Process`.

Examples:

```bash
adb devices
adb wait-for-device
adb shell getprop sys.boot_completed
adb shell pm list packages -3 -f
adb shell monkey -p <package> -c android.intent.category.LAUNCHER 1
adb uninstall <package>
adb install -r <apk>
adb shell screencap -p /sdcard/<file>
adb logcat -d -t 200
emulator -avd <name> -netdelay none -netspeed full -gpu host
avdmanager list avd
sdkmanager --install <system-image>
```

Every service logs what it is about to do before running a command.

## Main Services

### AndroidSDKDetector

Finds the Android SDK and required tools. It checks common locations and environment variables.

### ADBService

Wraps ADB behavior:

- connected devices
- boot completion
- installed app listing
- app launch
- app uninstall
- Play Store launch
- screenshot capture
- logcat collection
- navigation key events
- rotation
- ADB restart
- Android reboot
- Play Store reset
- ping diagnostics
- Android App Info launch

### EmulatorService

Starts and stops the official Google Android Emulator. It does not implement emulator internals.

Launch options include:

- no artificial network delay
- full network speed
- host GPU rendering
- no snapshot save
- optional DNS override
- optional skin/no-skin behavior

### AVDManagerService

Lists and creates AVDs. It also writes selected performance settings into the AVD config file.

### APKInstallerService

Installs APK files with ADB.

### GameLibraryService

Merges live app discovery with local cached metadata:

- friendly name
- icon placeholder
- last played
- favorite state
- version
- source directory

### KeyMappingService

Persists saved key mapping profiles.

### InputMappingExecutionService

Sends manual ADB tap tests from saved normalized tap coordinates.

### OfficialEmulatorToolbarRepairService

Keeps the official Google Emulator toolbar visible, but repairs common button clicks with transparent macOS helper panels that route actions through CleanDroid's ADB control layer.

### LogService

Stores visible log entries for the Logs screen.

### SettingsService

Saves `GamingSettings` as local JSON.

## Stored Data

CleanDroid stores local app data in:

```text
~/Library/Application Support/CleanDroid Gaming/
```

Files include:

- `settings.json`
- `game-library.json`
- `key-mappings.json`
- `Screenshots/`

## Recommended Development Flow

1. Build:

```bash
swift build
```

2. Package:

```bash
./Packaging/build-app.sh
```

3. Open:

```text
Build/CleanDroid Gaming.app
```

4. Use Logs to verify commands.

5. Use Boost when ADB, Play Store, or networking becomes unreliable.

## Troubleshooting

### Emulator starts but ADB is offline

Use:

- Boost > Restart ADB
- Boost > Reboot Android
- Home > Scan Again

### Play Store downloads are slow

Try:

- Boost > Network Boost
- Boost > Clear Play Store State
- restart emulator
- disable VPN, proxy, ad blockers, or DNS filters on macOS

### Toolbar buttons do not work

Keep:

- Settings > Keep official Google Emulator toolbar visible
- Settings > Repair official toolbar buttons

CleanDroid's transparent repair layer should route Back, Home, Recents, and other common buttons through ADB.

### No Play Store

Install/select a Google Play ARM64 system image:

```text
system-images;android-35;google_apis_playstore;arm64-v8a
```

### APK install fails

Check:

- emulator is running
- ADB is online
- APK is valid
- Android storage is available
- Logs screen for the raw ADB error
