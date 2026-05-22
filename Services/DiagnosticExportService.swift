//
// DiagnosticExportService.swift
// MacDroid
//
// Writes a support report that users can share when emulator setup, ADB, Play
// Store, or launch behavior is not working. The report avoids secrets and keeps
// the raw Android command output readable for maintainers.

import Foundation

@MainActor
final class DiagnosticExportService {
    private let logService: LogService

    init(logService: LogService) {
        self.logService = logService
    }

    func exportReport(
        sdkInfo: AndroidSDKInfo,
        avds: [AVDDevice],
        emulatorState: EmulatorState,
        deviceInfo: AndroidDeviceInfo,
        games: [AndroidApp],
        settings: GamingSettings,
        gameProfiles: [GameProfile],
        keyProfiles: [KeyMappingProfile],
        updateInfo: AppUpdateInfo,
        logEntries: [LogEntry]
    ) async -> URL? {
        do {
            try AppPaths.ensureDiagnosticsDirectory()
            let reportURL = AppPaths.diagnosticsDirectory
                .appendingPathComponent("macdroid-diagnostics-\(Self.timestamp()).txt")

            let report = await buildReport(
                sdkInfo: sdkInfo,
                avds: avds,
                emulatorState: emulatorState,
                deviceInfo: deviceInfo,
                games: games,
                settings: settings,
                gameProfiles: gameProfiles,
                keyProfiles: keyProfiles,
                updateInfo: updateInfo,
                logEntries: logEntries
            )

            try report.write(to: reportURL, atomically: true, encoding: .utf8)
            logService.log("Diagnostics exported to \(reportURL.path).", level: .success)
            return reportURL
        } catch {
            logService.log("Could not export diagnostics: \(error.localizedDescription)", level: .error)
            return nil
        }
    }

    private func buildReport(
        sdkInfo: AndroidSDKInfo,
        avds: [AVDDevice],
        emulatorState: EmulatorState,
        deviceInfo: AndroidDeviceInfo,
        games: [AndroidApp],
        settings: GamingSettings,
        gameProfiles: [GameProfile],
        keyProfiles: [KeyMappingProfile],
        updateInfo: AppUpdateInfo,
        logEntries: [LogEntry]
    ) async -> String {
        var sections: [String] = []

        sections.append("""
        # MacDroid Diagnostics

        Generated: \(Date().formatted(date: .complete, time: .standard))
        MacDroid version: \(AppVersion.current)
        macOS: \(ProcessInfo.processInfo.operatingSystemVersionString)
        Host: \(ProcessInfo.processInfo.hostName)
        """)

        sections.append("""
        ## SDK

        SDK root: \(sdkInfo.sdkRoot?.path ?? "Not detected")
        ADB: \(sdkInfo.adbURL?.path ?? "Missing")
        Emulator: \(sdkInfo.emulatorURL?.path ?? "Missing")
        AVD Manager: \(sdkInfo.avdManagerURL?.path ?? "Missing")
        SDK Manager: \(sdkInfo.sdkManagerURL?.path ?? "Missing")
        Play Store ARM64 image: \(sdkInfo.playStoreImageAvailable ? "Detected" : "Missing")

        Messages:
        \(sdkInfo.detectedMessages.map { "- \($0)" }.joined(separator: "\n"))
        """)

        sections.append("""
        ## Emulator

        State: \(emulatorState.title)
        Device: \(deviceInfo.title)
        Serial: \(deviceInfo.serial ?? "None")
        Android: \(deviceInfo.androidVersion ?? "Unknown")
        API: \(deviceInfo.apiLevel ?? "Unknown")
        ABI: \(deviceInfo.abi ?? "Unknown")
        Boot completed: \(deviceInfo.bootCompleted ? "yes" : "no")
        """)

        sections.append("""
        ## AVDs

        \(avds.isEmpty ? "No AVDs detected." : avds.map { "- \($0.name) | \($0.device) | \($0.target) | \($0.path)" }.joined(separator: "\n"))
        """)

        sections.append("""
        ## Library

        Installed apps visible to MacDroid: \(games.count)
        \(games.prefix(80).map { "- \($0.name) | \($0.packageName) | version: \($0.versionName ?? "unknown")" }.joined(separator: "\n"))
        """)

        sections.append("""
        ## Profiles

        Game profiles: \(gameProfiles.count)
        Key mapping profiles: \(keyProfiles.count)
        """)

        sections.append("""
        ## Settings

        Performance: \(settings.performanceProfile.rawValue)
        RAM: \(settings.ramPreset.rawValue)
        CPU: \(settings.cpuPreset.rawValue)
        Resolution: \(settings.resolutionPreset.rawValue)
        DPI: \(settings.dpiPreset.rawValue)
        FPS: \(settings.fpsTarget.rawValue)
        Network boost: \(settings.networkBoostEnabled ? settings.dnsPreset.servers : "off")
        Setup completed: \(settings.setupWizardCompleted ? "yes" : "no")
        """)

        sections.append("""
        ## Updates

        Current: \(updateInfo.currentVersion)
        Latest: \(updateInfo.latestVersion ?? "Unknown")
        Message: \(updateInfo.message)
        URL: \(updateInfo.releaseURL?.absoluteString ?? "None")
        """)

        sections.append(await commandSection(title: "adb devices", executableURL: sdkInfo.adbURL, arguments: ["devices"]))
        sections.append(await commandSection(title: "avdmanager list avd", executableURL: sdkInfo.avdManagerURL, arguments: ["list", "avd"]))
        sections.append(await commandSection(title: "emulator -list-avds", executableURL: sdkInfo.emulatorURL, arguments: ["-list-avds"]))

        sections.append("""
        ## Recent MacDroid Logs

        \(logEntries.prefix(120).map(Self.formatLogEntry).joined(separator: "\n\n"))
        """)

        return sections.joined(separator: "\n\n")
    }

    private func commandSection(title: String, executableURL: URL?, arguments: [String]) async -> String {
        guard let executableURL else {
            return """
            ## \(title)

            Tool missing.
            """
        }

        guard let result = try? await ShellCommandRunner.run(executableURL: executableURL, arguments: arguments) else {
            return """
            ## \(title)

            Command could not run.
            """
        }

        return """
        ## \(title)

        Exit code: \(result.exitCode)

        \(result.combinedOutput.isEmpty ? "(no output)" : result.combinedOutput)
        """
    }

    private static func formatLogEntry(_ entry: LogEntry) -> String {
        var lines = [
            "[\(entry.level.title)] \(entry.date.formatted(date: .abbreviated, time: .standard))",
            entry.message
        ]

        if let command = entry.command {
            lines.append("Command: \(command)")
        }

        return lines.joined(separator: "\n")
    }

    private static func timestamp() -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter.string(from: Date())
    }
}
