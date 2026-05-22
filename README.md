# MacDroid

Native SwiftUI macOS launcher for Android games on Apple Silicon.

MacDroid is **not** a custom emulator engine. It is a polished gaming wrapper around the official Google Android Emulator, Android SDK, ADB, and AVD tools.

## Highlights

- Dark premium macOS gaming UI
- First-run Setup Wizard
- Health Check screen
- Android SDK / ADB / Emulator detection
- Start, stop, restart, and reboot emulator
- Recommended ARM64 Google Play AVD setup
- APK drag-and-drop installer
- Installed games library
- Recent and favorite games
- Per-game launch profiles
- Play Store launcher
- Boost & Repair tools
- App rotation repair for stubborn portrait apps
- Network Boost with direct DNS launch flag
- Performance profiles
- Official Google Emulator toolbar repair
- Live key mapping overlay through ADB input
- GitHub Release update checker
- Export Diagnostics support report
- DMG release packaging
- Beginner-friendly logs

## Latest Updates

Users can check this section before building or downloading the app.

- macOS `.dmg` packaging was added for a normal drag-to-Applications install.
- Export Diagnostics was added for easier user support and bug reports.
- The app icon was enlarged by cropping the empty transparent border around the neon `M` artwork.
- Setup Wizard, Health Check, per-game Profiles, and GitHub update checking were added.
- Release packaging now creates a zip file for GitHub Releases.
- App rotation repair was added for apps that stay sideways in landscape mode.
- The Boost screen now includes `Fix App Rotation`.
- The UI layout was improved for different window sizes.
- The app name and default AVD name are now `MacDroid`.

Full update history:

- [Changelog](CHANGELOG.md)

## Download

GitHub Releases can contain a ready-to-install DMG:

```text
MacDroid-<version>-macOS-arm64.dmg
```

Open the DMG, drag `MacDroid.app` into Applications, then open it from Applications.

The zip is still available for developers:

```text
MacDroid-<version>-macOS-arm64.zip
```

MacDroid still requires Android Studio or Android SDK tools on the user's Mac.

## Build

```bash
swift build
./Packaging/build-app.sh
```

To create a release zip locally:

```bash
./Packaging/package-release.sh
```

That command creates both `.zip` and `.dmg` release assets.

Then open:

```text
Build/MacDroid.app
```

## Requirements

- macOS 14+
- Apple Silicon Mac recommended
- Swift / Xcode toolchain
- Android SDK
- Android Emulator
- ADB
- AVD Manager
- SDK Manager

For Play Store support, use an ARM64 Google Play system image.

## Project Structure

```text
App/              SwiftUI app entry
Views/            Screens and UI components
ViewModels/       UI state helpers
Models/           Codable data models
Services/         Android SDK / ADB wrappers
Managers/         AppEnvironment coordinator
Utilities/        Storage, shell, color helpers
Documentation/    Full docs and limitations
Packaging/        macOS app bundle scripts
```

## For Developers

MacDroid is a SwiftUI + MVVM macOS app. The UI talks to `AppEnvironment`, and `AppEnvironment` coordinates small services that call the official Android SDK tools through `Process`.

Common entry points:

- `App/MacDroidApp.swift`: app windows
- `Views/RootView.swift`: main shell and sidebar navigation
- `Managers/AppEnvironment.swift`: shared app state and user actions
- `Services/ADBService.swift`: app launch, install, uninstall, navigation, screenshots, logcat
- `Services/EmulatorService.swift`: starts/stops Google Android Emulator
- `Services/AVDManagerService.swift`: lists/creates/configures AVDs
- `Services/InputMappingExecutionService.swift`: sends key mapping input through ADB

Developer guide:

- [Developer Guide](Documentation/DEVELOPER_GUIDE.md)

## Important

MacDroid launches and controls the official Google Android Emulator. It does not bundle Android images, redistribute Play Store, patch Google's emulator binary, or replace the emulator runtime.

## Docs

- [Full Documentation](Documentation/README.md)
- [Developer Guide](Documentation/DEVELOPER_GUIDE.md)
- [Limitations](Documentation/LIMITATIONS.md)
- [Future Features](Documentation/FUTURE_FEATURES.md)
