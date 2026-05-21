//
// HealthCheckService.swift
// MacDroid
//
// Builds a readable health report from the app's current SDK, emulator, network,
// and profile state. It does not mutate anything; repair buttons live in views.

import Foundation

@MainActor
final class HealthCheckService {
    func buildReport(
        sdkInfo: AndroidSDKInfo,
        avds: [AVDDevice],
        emulatorState: EmulatorState,
        deviceInfo: AndroidDeviceInfo,
        games: [AndroidApp],
        settings: GamingSettings,
        gameProfiles: [GameProfile],
        updateInfo: AppUpdateInfo
    ) -> [HealthCheckItem] {
        [
            toolItem(
                id: "adb",
                title: "ADB",
                isReady: sdkInfo.hasADB,
                readyMessage: "ADB is available and MacDroid can talk to Android devices.",
                missingMessage: "ADB was not found. Install Android Studio or select the Android SDK folder.",
                actionTitle: "Open Setup"
            ),
            toolItem(
                id: "emulator",
                title: "Android Emulator",
                isReady: sdkInfo.hasEmulator,
                readyMessage: "The official Google Android Emulator binary was found.",
                missingMessage: "The emulator binary was not found. Install Android Emulator from Android Studio.",
                actionTitle: "Open Setup"
            ),
            toolItem(
                id: "avdmanager",
                title: "AVD Manager",
                isReady: sdkInfo.canManageAVDs,
                readyMessage: "AVD Manager is available for creating and listing virtual devices.",
                missingMessage: "AVD Manager was not found. Install Android command-line tools.",
                actionTitle: "Open Setup"
            ),
            HealthCheckItem(
                id: "avd",
                title: "Gaming AVD",
                message: avds.isEmpty ? "No AVD was detected. Create the recommended MacDroid gaming AVD." : "\(avds.count) AVD profile\(avds.count == 1 ? "" : "s") detected.",
                status: avds.isEmpty ? .warning : .good,
                actionTitle: avds.isEmpty ? "Create AVD" : nil
            ),
            HealthCheckItem(
                id: "playstore",
                title: "Google Play Image",
                message: sdkInfo.playStoreImageAvailable ? "A Google Play ARM64 image appears to be installed." : "Google Play ARM64 image was not detected. Play Store may not work.",
                status: sdkInfo.playStoreImageAvailable ? .good : .warning,
                actionTitle: sdkInfo.playStoreImageAvailable ? nil : "Create AVD"
            ),
            HealthCheckItem(
                id: "emulator-state",
                title: "Emulator Status",
                message: emulatorState == .running ? "Android is running as \(deviceInfo.title)." : "The emulator is \(emulatorState.title.lowercased()).",
                status: emulatorState == .running ? .good : (emulatorState == .error ? .error : .warning),
                actionTitle: emulatorState == .running ? nil : "Start Emulator"
            ),
            HealthCheckItem(
                id: "library",
                title: "Game Library",
                message: games.isEmpty ? "No installed apps are visible yet. Boot the emulator, then refresh the library." : "\(games.count) installed app\(games.count == 1 ? "" : "s") in the library.",
                status: games.isEmpty ? .warning : .good,
                actionTitle: games.isEmpty ? "Refresh Library" : nil
            ),
            HealthCheckItem(
                id: "profiles",
                title: "Game Profiles",
                message: gameProfiles.isEmpty ? "No per-game launch profiles yet." : "\(gameProfiles.count) per-game profile\(gameProfiles.count == 1 ? "" : "s") saved.",
                status: gameProfiles.isEmpty ? .warning : .good,
                actionTitle: gameProfiles.isEmpty ? "Open Profiles" : nil
            ),
            HealthCheckItem(
                id: "updates",
                title: "Updates",
                message: updateInfo.message,
                status: updateInfo.isUpdateAvailable ? .warning : .good,
                actionTitle: "Check Updates"
            ),
            HealthCheckItem(
                id: "setup",
                title: "Setup Wizard",
                message: settings.setupWizardCompleted ? "Setup has been completed." : "Setup is not finished yet.",
                status: settings.setupWizardCompleted ? .good : .warning,
                actionTitle: settings.setupWizardCompleted ? nil : "Open Setup"
            )
        ]
    }

    private func toolItem(
        id: String,
        title: String,
        isReady: Bool,
        readyMessage: String,
        missingMessage: String,
        actionTitle: String
    ) -> HealthCheckItem {
        HealthCheckItem(
            id: id,
            title: title,
            message: isReady ? readyMessage : missingMessage,
            status: isReady ? .good : .error,
            actionTitle: isReady ? nil : actionTitle
        )
    }
}
