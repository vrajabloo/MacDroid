# MVP Limitations

CleanDroid Gaming is intentionally designed as a wrapper around the official Google Android Emulator.

## Not included

- No custom Android emulator engine
- No custom hypervisor or Android runtime
- No bundled Android system images
- No Play Store redistribution
- No guaranteed FPS control for every emulator version
- No direct keyboard/mouse injection in the MVP
- No binary patching of Google's own Emulator toolbar

## Key mapping status

The app includes:

- Codable key mapping profiles
- Per-game mapping storage
- Normalized tap positions
- A visual editor UI
- Automatic profile lookup when a game launches
- Manual test taps through `adb shell input tap`
- Future input bridge and gamepad-ready fields in each saved profile

Live input injection is future work. Good implementation options include:

- `adb shell input tap x y` for simple tap actions
- `adb shell input keyevent` for Android key events
- A transparent macOS overlay that translates keyboard and mouse events
- Gamepad event bridging where supported

The profile model is intentionally clean so any of those approaches can be added behind a future input service.

## Official Emulator toolbar

CleanDroid does not patch Google's Emulator binary. The official toolbar stays visible by default. To handle emulator builds where toolbar clicks are unreliable, CleanDroid places transparent helper panels over the common toolbar buttons and sends the matching ADB command.

This keeps the familiar Google toolbar UI while avoiding dependence on the toolbar's native Qt click handling.

## Play Store support

Play Store support requires a Google Play system image. If the selected AVD uses a plain Google APIs image or an AOSP image, the app will warn the user instead of pretending Play Store is available.

## Network Boost

Network Boost uses the official Emulator `-dns-server` launch flag. It can help with slow DNS or regional resolver problems, but it cannot bypass Google Play throttling, ISP congestion, VPN issues, or Play Store account-side limits.
