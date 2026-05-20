//
// EmulatorService.swift
// MacDroid
//
// Starts and stops the official Google Android Emulator. It does not emulate
// Android itself; it simply launches the SDK emulator process with game-friendly
// options selected in the app.

import Foundation

@MainActor
final class EmulatorService {
    private let logService: LogService
    private var runningProcess: Process?

    init(logService: LogService) {
        self.logService = logService
    }

    func startEmulator(
        emulatorURL: URL,
        avdName: String,
        settings: GamingSettings
    ) throws {
        configureOfficialEmulatorFrame(hidden: settings.hideOfficialEmulatorToolbar)

        var arguments = [
            "-avd", avdName,
            "-netdelay", "none",
            "-netspeed", "full",
            "-gpu", "host",
            "-no-snapshot-save"
        ]

        let resolution = settings.resolutionPreset.size
        if settings.hideOfficialEmulatorToolbar {
            arguments.append(contentsOf: ["-no-skin"])
        } else {
            arguments.append(contentsOf: ["-skin", "\(resolution.width)x\(resolution.height)"])
        }

        if settings.networkBoostEnabled {
            arguments.append(contentsOf: ["-dns-server", settings.dnsPreset.servers])
        }

        logService.log(
            "Starting the official Android Emulator with gaming-oriented launch options.",
            level: .command,
            command: "emulator \(arguments.joined(separator: " "))"
        )

        let process = Process()
        process.executableURL = emulatorURL
        process.arguments = arguments

        try process.run()
        runningProcess = process

        logService.log("Emulator process started. Android may take a minute to finish booting.", level: .success)
    }

    private func configureOfficialEmulatorFrame(hidden: Bool) {
        let defaults = UserDefaults(suiteName: "com.android.Emulator")

        // The official Google Emulator stores its "Show window frame around device"
        // switch in this preference. MacDroid turns it off so users do not have
        // to use Google's unreliable side toolbar for Back, Home, and Recents.
        defaults?.set(!hidden, forKey: "set.frameAlways4")

        if hidden {
            defaults?.set(false, forKey: "set.alwaysOnTop")
        }

        defaults?.synchronize()

        logService.log(
            hidden
                ? "Google Emulator device frame preference was turned off before launch."
                : "Google Emulator device frame preference was left visible.",
            level: .info
        )
    }

    func stopEmulator(adbURL: URL, serial: String? = nil) async throws {
        let arguments = targetedArguments(["emu", "kill"], serial: serial)

        logService.log(
            "Asking the emulator to shut down cleanly through ADB.",
            level: .command,
            command: "adb \(arguments.joined(separator: " "))"
        )

        let result = try await ShellCommandRunner.run(executableURL: adbURL, arguments: arguments)

        if result.succeeded {
            logService.log("Emulator shutdown command sent.", level: .success)
        } else {
            logService.log(result.combinedOutput, level: .warning)
        }

        runningProcess = nil
    }

    private func targetedArguments(_ arguments: [String], serial: String?) -> [String] {
        guard let serial, !serial.isEmpty else {
            return arguments
        }

        return ["-s", serial] + arguments
    }

    func state(adbURL: URL, adbService: ADBService) async -> EmulatorState {
        guard await adbService.isAnyDeviceOnline(adbURL: adbURL) else {
            return .stopped
        }

        return await adbService.bootCompleted(adbURL: adbURL) ? .running : .booting
    }
}
