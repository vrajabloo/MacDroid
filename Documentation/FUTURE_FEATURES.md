# Future Features

MacDroid already has the foundation for a commercial-emulator-style Android gaming control center. The next features should build on the existing service boundaries instead of replacing the official Google Emulator.

## Input & Controls

- Lower-latency input bridge beyond ADB commands.
- Mouse drag camera mapping.
- Gamepad event bridge using native macOS controller APIs.
- Sensitivity profiles for shooter and MOBA-style games.
- Import/export key mapping profiles.
- Automatic overlay alignment with the emulator window.

## Gaming Tools

- Screen recording.
- Screenshot gallery.
- Macro recorder.
- One-click game booster mode.
- Per-game launch profiles.
- Per-game resolution and DPI profiles.
- Per-game network and DNS profiles.
- Play time tracking.

## Library Improvements

- Extract real app icons from APK metadata.
- Extract game labels from Android package manager metadata.
- Custom artwork assignment.
- Game categories.
- Recently installed section.
- App cache clear action per game.
- App data clear action with confirmation.
- Batch uninstall.

## Emulator Management

- Multi-instance support.
- Clone AVD.
- Delete AVD.
- Cold boot / quick boot switch.
- Snapshot management.
- Fullscreen orchestration for emulator windows.
- Automatic emulator window positioning.
- Better boot progress detection.

## Play Store & Network

- More detailed Play Store diagnostics.
- Google Play Services version checks.
- Download speed estimates.
- Network quality dashboard.
- Proxy configuration UI.
- Regional DNS presets.

## Cloud & Sync

- Cloud save backup helpers where games expose files.
- Export/import MacDroid settings.
- Export/import game library metadata.
- Sync key mapping profiles across Macs.

## Developer Experience

- Unit tests for parsers and settings migrations.
- UI previews for each screen.
- Localized strings.
- Release packaging workflow.
- Signed and notarized distribution build.
