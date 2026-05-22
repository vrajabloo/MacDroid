# Changelog

This file lists important MacDroid updates so users and developers can quickly understand what changed.

## 2026-05-22 - 0.3.1

### Fixed

- Fixed the GitHub Actions release build by removing an unsafe Swift concurrency capture in the official emulator toolbar repair timer.
- Added release workflow write permissions so tag builds can publish release assets.

## 2026-05-22 - 0.3.0

### Added

- Added macOS DMG packaging with drag-to-Applications layout.
- Added Developer ID signing path with hardened runtime support.
- Added notarization helper script for signed DMG releases.
- Added Export Diagnostics from Health and Logs.
- Added DMG assets to the GitHub release workflow.

## 2026-05-21 - 0.2.2

### Fixed

- Cropped the MacDroid app icon source so the icon fills the macOS icon canvas with much less empty transparent margin.

## 2026-05-21 - 0.2.1

### Changed

- Replaced the MacDroid app icon with the new neon `M` artwork.
- Updated icon generation so release builds always use `Packaging/AppIconSource.png`.

## 2026-05-21

### Added

- Added first-run Setup Wizard for SDK, ADB, Emulator, AVD, and Play Store readiness.
- Added Health Check screen with beginner-friendly status cards and repair actions.
- Added per-game launch profiles for orientation, performance, resolution, DPI, and key mapping overlay preference.
- Added GitHub Release update checker inside the app.
- Added advanced rotation controls: Portrait, Landscape, Force Landscape, and Reset.
- Added Shooter and MOBA key mapping presets.
- Added key mapping JSON export.
- Added local release zip packaging script.
- Added GitHub Actions workflow for release artifacts and tag-based release publishing.

### Improved

- Home dashboard now shows setup/update status and health metrics.
- Settings now includes update preferences and setup completion state.
- Boost & Repair now has a dedicated Rotation Control card.

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
