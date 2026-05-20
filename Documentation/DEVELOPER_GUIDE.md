# MacDroid Developer Guide

This guide explains how the project is organized and where to start when changing code.

## What MacDroid Is

MacDroid is a native macOS launcher and control center for Android games. It does not contain a custom emulator engine. It wraps the official Google Android Emulator, Android SDK, ADB, `avdmanager`, and `sdkmanager`.

The app is written in SwiftUI with a simple MVVM-style structure.

## Build And Run

```bash
swift build
./Packaging/build-app.sh
open Build/MacDroid.app
```

The packaging script creates a clickable macOS app bundle and applies a local ad-hoc signature.

## Architecture

```text
SwiftUI Views
    -> user actions
AppEnvironment
    -> coordinates app state
Services
    -> run official Android SDK commands
Android Emulator / ADB / AVD tools
```

`AppEnvironment` is the central coordinator. Views should stay mostly declarative and call methods on `AppEnvironment` instead of running Android commands directly.

## Important Files

```text
App/MacDroidApp.swift
```

Creates the main window, emulator controls window, and key mapping overlay window.

```text
Views/RootView.swift
Views/SidebarView.swift
```

Define the main app layout and sidebar navigation.

```text
Managers/AppEnvironment.swift
```

Owns shared state such as SDK detection, emulator status, installed games, settings, key profiles, logs, and active device information.

```text
Services/ADBService.swift
```

Wraps ADB commands for device detection, app listing, app launch, APK install support, uninstall, Play Store launch, screenshots, logcat, navigation keys, rotation, ping diagnostics, and repair commands.

```text
Services/EmulatorService.swift
```

Starts and stops the official Android Emulator. Launch flags are assembled here.

```text
Services/AVDManagerService.swift
```

Lists, creates, and configures Android Virtual Devices. Performance settings are written into the AVD `config.ini`.

```text
Services/InputMappingExecutionService.swift
```

Converts normalized key mapping positions into Android screen pixels and sends ADB input commands.

```text
Utilities/ShellCommandRunner.swift
```

Runs shell commands using Swift `Process`.

## Main User Flows

### Detect Android Tools

1. `AppEnvironment.refreshSDK()`
2. `AndroidSDKDetector.detect(...)`
3. Result is stored in `AndroidSDKInfo`
4. UI reads `app.sdkInfo`

### Start Emulator

1. User clicks Play or the MacDroid icon
2. `AppEnvironment.launchFromEmulatorIcon()`
3. AVD is created if needed
4. `AVDManagerService.apply(settings:toAVDNamed:)`
5. `EmulatorService.startEmulator(...)`
6. `ADBService.waitForDevice(...)`
7. `ADBService.bootCompleted(...)`

### Refresh Game Library

1. `AppEnvironment.refreshGames()`
2. `ADBService.listInstalledUserApps(...)`
3. `GameLibraryService.merge(...)`
4. UI updates from `app.games`

### Launch Game

1. User clicks Play on a game card
2. `AppEnvironment.launch(_:)`
3. `ADBService.launch(packageName:adbURL:serial:)`
4. Last-played metadata is saved
5. Key mapping profile is armed if one exists

### Install APK

1. User drops or browses an APK
2. `APKInstallerService.install(...)`
3. Runs `adb install -r <apk>`
4. Library refreshes after success

### Key Mapping

1. User creates a profile in `KeyMappingView`
2. Profile is saved by `KeyMappingService`
3. Overlay window opens from `MacDroidApp`
4. `KeyMappingOverlayWindowView` captures focused keyboard input
5. `AppEnvironment.runKeyMappingTrigger(...)`
6. `InputMappingExecutionService.send(...)`
7. ADB runs `input tap` or `input swipe`

## Data Storage

Local app data is stored in:

```text
~/Library/Application Support/MacDroid/
```

Files:

```text
settings.json
game-library.json
key-mappings.json
Screenshots/
```

Models use `Codable` so saved data stays readable and easy to migrate.

## Adding A Feature

Use this pattern:

1. Add or update a model in `Models/`
2. Add command logic in a small service under `Services/`
3. Expose one user-facing method on `AppEnvironment`
4. Call that method from a SwiftUI view
5. Log the command before running it
6. Run `swift build`
7. Run `./Packaging/build-app.sh`

Avoid putting Android command logic directly inside SwiftUI views.

## Command Logging Rule

Every Android SDK command should be logged before it runs. This keeps the Logs screen useful for beginners and helps developers debug the app.

Example:

```swift
logService.log(
    "Reading installed user apps from Android.",
    level: .command,
    command: "adb shell pm list packages -3 -f"
)
```

## Safety Rules

- Do not build or claim a custom emulator engine.
- Do not bundle Android system images.
- Do not redistribute Google Play.
- Do not patch Google's emulator binary.
- Prefer official Android SDK tools and ADB commands.
- Keep features understandable and modular.

## Verification Checklist

Before pushing a change:

```bash
swift build
./Packaging/build-app.sh
codesign --verify --deep --strict "Build/MacDroid.app"
plutil -lint "Build/MacDroid.app/Contents/Info.plist"
```

Then open the app and test the changed screen manually.
