# Limitations

CleanDroid Gaming is intentionally designed as a wrapper around the official Google Android Emulator. This keeps the project practical, maintainable, and aligned with Google's supported Android tooling.

## What CleanDroid Is Not

CleanDroid is not:

- a custom Android emulator engine
- a custom hypervisor
- a custom Android runtime
- a replacement for Google's system images
- a Play Store distributor
- a modified Google Emulator binary

The app launches and controls the official emulator. All Android execution comes from Google's tooling.

## System Images

CleanDroid does not bundle Android system images. Users need Android SDK system images installed through Android Studio or `sdkmanager`.

For Play Store support, use a Google Play ARM64 image:

```text
system-images;android-35;google_apis_playstore;arm64-v8a
```

If the selected AVD uses a plain Google APIs or AOSP image, Play Store will not be available.

## Play Store

CleanDroid can launch Play Store and reset Play Store state, but it cannot:

- redistribute Play Store
- bypass Google account requirements
- bypass regional restrictions
- bypass Google Play download throttling
- guarantee download speed

Slow Play Store downloads can be caused by:

- Google Play throttling
- VPN or proxy configuration
- DNS filters
- ISP congestion
- macOS network responsiveness
- first-run Google Play Services updates

## Network Boost

Network Boost uses the official Emulator `-dns-server` launch flag. It can help when DNS resolution is slow or unreliable.

It cannot fix:

- a slow internet connection
- Play Store server-side throttling
- VPN congestion
- firewall rules outside the emulator
- Google account or region restrictions

## FPS Control

CleanDroid stores FPS preferences and uses performance-oriented emulator settings. Exact FPS behavior still depends on:

- Android Emulator version
- system image
- host GPU
- game engine
- Android display pipeline
- game settings

The app does not promise guaranteed FPS across all games.

## Key Mapping

The current key mapping implementation is an MVP:

- profiles are saved per game
- normalized tap coordinates are stored
- manual ADB tap tests work
- input bridge and gamepad fields are prepared

Live real-time keyboard/mouse/gamepad injection is future work.

Possible future approaches:

- `adb shell input tap x y`
- `adb shell input keyevent`
- transparent macOS overlay
- native gamepad event bridge
- per-game input service

## Official Emulator Toolbar

CleanDroid does not patch Google's Emulator binary. The official toolbar stays visible by default.

If Google's toolbar ignores clicks on a specific macOS setup, CleanDroid places transparent helper panels over common toolbar buttons and sends the matching ADB command.

This repairs common actions while keeping the familiar Google toolbar UI.

## Multi-Instance

The current version focuses on one selected AVD at a time. Multi-instance management is planned.

## Distribution

The local packaging script creates an ad-hoc signed macOS app bundle. Public distribution would need:

- Developer ID signing
- notarization
- hardened runtime review
- release build workflow
