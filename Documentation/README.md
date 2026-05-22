# MacDroid Documentation

MacDroid is a native SwiftUI macOS app for Apple Silicon Macs. It provides a premium gaming launcher and manager around the official Google Android Emulator, Android SDK, ADB, and AVD tools.

It does not emulate Android by itself. The Android runtime, virtualization, system images, Play Store support, and device behavior all come from Google's official emulator stack.

## Design Goal

The goal is to make the official Android Emulator feel like a beginner-friendly gaming product:

- one clear app icon
- one dashboard
- one library
- one APK installer
- one repair area
- setup wizard
- health check report
- per-game launch profiles
- update checker
- export diagnostics
- DMG installer packaging
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
- Fix App Rotation
- Portrait / Landscape / Force Landscape / Reset rotation controls
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

The Key Mapping screen stores per-game input profiles and includes a live floating overlay. Keyboard and mouse triggers can run tap, long-press, and swipe actions through ADB.

- per-game profiles
- click-to-place tap points
- editable keyboard, mouse, and gamepad-ready triggers
- live overlay window
- ADB tap, long-press, and swipe execution
- WASD, Shooter, and MOBA presets
- JSON export for saved mappings

### Game Profiles

The Profiles screen stores launch preferences per app:

- orientation mode
- performance profile
- resolution
- DPI
- automatic key mapping overlay preference

These profiles make repeat launches feel closer to a commercial Android emulator launcher.

### Health Check

The Health screen checks the common failure points:

- ADB
- Emulator
- AVD Manager
- recommended AVD
- Play Store image
- emulator state
- game library
- game profiles
- update status

It also has `Export Diagnostics`, which writes a support report with SDK paths, ADB device output, AVD output, library state, settings, update status, and recent MacDroid logs.

### Updates

MacDroid can check the public GitHub Releases API and show whether a newer release is available. It does not install updates automatically.

## Install For Users

The recommended public download is:

```text
MacDroid-<version>-macOS-arm64.dmg
```

Users should open the DMG, drag `MacDroid.app` into Applications, then open MacDroid from Applications.

If macOS blocks an unsigned local build, right-click the app and choose Open. Public builds should be Developer ID signed and notarized before broad distribution.

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

MacDroid runs official Android tools through `Process`.

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

Converts saved normalized tap coordinates into the emulator's current Android screen size and sends ADB input commands for tap, long-press, swipe, and overlay clicks.

### OfficialEmulatorToolbarRepairService

Keeps the official Google Emulator toolbar visible, but repairs common button clicks with transparent macOS helper panels that route actions through MacDroid's ADB control layer.

### LogService

Stores visible log entries for the Logs screen.

### SettingsService

Saves `GamingSettings` as local JSON.

## Stored Data

MacDroid stores local app data in:

```text
~/Library/Application Support/MacDroid/
```

Files include:

- `settings.json`
- `game-library.json`
- `key-mappings.json`
- `Screenshots/`

## Recommended Development Flow

For a focused code-level overview, read:

- [Developer Guide](DEVELOPER_GUIDE.md)

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
Build/MacDroid.app
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

MacDroid's transparent repair layer should route Back, Home, Recents, and other common buttons through ADB.

### Apps stay sideways after rotating

Use:

- Boost > Fix App Rotation
- press the toolbar Rotate button once
- close and reopen the Android app if it still keeps its old layout

MacDroid uses Android Window Manager commands through ADB to ignore app orientation locks where the official emulator allows it.

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
