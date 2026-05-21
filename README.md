# MacDroid

Native SwiftUI macOS launcher for Android games on Apple Silicon.

MacDroid is **not** a custom emulator engine. It is a polished gaming wrapper around the official Google Android Emulator, Android SDK, ADB, and AVD tools.

## Highlights

- Dark premium macOS gaming UI
- Android SDK / ADB / Emulator detection
- Start, stop, restart, and reboot emulator
- Recommended ARM64 Google Play AVD setup
- APK drag-and-drop installer
- Installed games library
- Recent and favorite games
- Play Store launcher
- Boost & Repair tools
- App rotation repair for stubborn portrait apps
- Network Boost with direct DNS launch flag
- Performance profiles
- Official Google Emulator toolbar repair
- Live key mapping overlay through ADB input
- Beginner-friendly logs

## Build

```bash
swift build
./Packaging/build-app.sh
```

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
