//
// APKInstallerService.swift
// CleanDroid Gaming
//
// Installs APK files into the running emulator with `adb install -r`. Drag and
// drop and browse actions both call this service.

import Foundation

@MainActor
final class APKInstallerService {
    private let logService: LogService

    init(logService: LogService) {
        self.logService = logService
    }

    func install(apkURL: URL, adbURL: URL, serial: String?) async throws -> Bool {
        guard apkURL.pathExtension.lowercased() == "apk" else {
            logService.log("Only .apk files can be installed.", level: .warning)
            return false
        }

        let arguments = targetedArguments(["install", "-r", apkURL.path], serial: serial)

        logService.log(
            "Installing APK into the emulator. The -r flag allows updating an existing app.",
            level: .command,
            command: "adb \(arguments.joined(separator: " "))"
        )

        let result = try await ShellCommandRunner.run(
            executableURL: adbURL,
            arguments: arguments
        )

        if result.succeeded && result.combinedOutput.localizedCaseInsensitiveContains("success") {
            logService.log("APK installed successfully.", level: .success)
            return true
        }

        logService.log(result.combinedOutput.isEmpty ? "APK install failed." : result.combinedOutput, level: .error)
        return false
    }

    private func targetedArguments(_ arguments: [String], serial: String?) -> [String] {
        guard let serial, !serial.isEmpty else {
            return arguments
        }

        return ["-s", serial] + arguments
    }
}
