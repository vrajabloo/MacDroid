# Changelog

This file lists important MacDroid updates so users and developers can quickly understand what changed.

## 2026-05-20

### Added

- Added app rotation repair for Android apps that stay sideways after rotating the emulator.
- Added `Fix App Rotation` to the Boost & Repair screen.
- Added developer documentation for project structure, services, build steps, and contribution guidance.
- Added live key mapping overlay support through ADB input commands.

### Improved

- Improved responsive layouts across Home, Boost, Settings, Library, and Key Mapping screens.
- Renamed the app, UI text, app bundle, default AVD, and GitHub project branding to `MacDroid`.
- Improved official Google Emulator toolbar repair for common controls.
- Improved README content for users and developers.

### Fixed

- Fixed package parsing when APK paths contain `=` characters.
- Fixed sidebar navigation behavior.
- Fixed several layout issues that appeared after resizing the macOS window.
- Fixed Android rotation control so it uses Android Window Manager commands instead of only system settings.

## Notes

MacDroid is still a wrapper around the official Google Android Emulator. It does not include a custom emulator engine.
