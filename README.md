# CleanDroid Gaming

Native SwiftUI macOS launcher for Android games on Apple Silicon.

CleanDroid Gaming is **not** a custom emulator engine. It is a polished gaming wrapper around the official Google Android Emulator, Android SDK, ADB, and AVD tools.

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
- Network Boost with direct DNS launch flag
- Performance profiles
- Official Google Emulator toolbar repair
- Key mapping MVP with gamepad-ready profile fields
- Beginner-friendly logs

## Build

```bash
swift build
./Packaging/build-app.sh
```

Then open:

```text
Build/CleanDroid Gaming.app
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

## Important

CleanDroid Gaming launches and controls the official Google Android Emulator. It does not bundle Android images, redistribute Play Store, patch Google's emulator binary, or replace the emulator runtime.

## Docs

- [Full Documentation](Documentation/README.md)
- [Limitations](Documentation/LIMITATIONS.md)
- [Future Features](Documentation/FUTURE_FEATURES.md)
