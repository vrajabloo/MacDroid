//
// InputMappingExecutionService.swift
// CleanDroid Gaming
//
// Executes a saved tap mapping through ADB. This is not a full live keyboard
// overlay yet, but it proves the clean path for future input injection features.

import Foundation

@MainActor
final class InputMappingExecutionService {
    private let logService: LogService

    init(logService: LogService) {
        self.logService = logService
    }

    func sendTap(
        mapping: InputMapping,
        resolution: ResolutionPreset,
        adbURL: URL,
        serial: String?
    ) async throws {
        let size = resolution.size
        let x = max(0, min(size.width, Int(Double(size.width) * mapping.tapPoint.x)))
        let y = max(0, min(size.height, Int(Double(size.height) * mapping.tapPoint.y)))
        let arguments = targetedArguments(["shell", "input", "tap", "\(x)", "\(y)"], serial: serial)

        logService.log(
            "Testing \(mapping.trigger) by sending a tap to Android at \(x), \(y).",
            level: .command,
            command: "adb \(arguments.joined(separator: " "))"
        )

        let result = try await ShellCommandRunner.run(
            executableURL: adbURL,
            arguments: arguments
        )

        if result.succeeded {
            logService.log("Tap mapping sent successfully.", level: .success)
        } else {
            logService.log(result.combinedOutput, level: .error)
        }
    }

    private func targetedArguments(_ arguments: [String], serial: String?) -> [String] {
        guard let serial, !serial.isEmpty else {
            return arguments
        }

        return ["-s", serial] + arguments
    }
}
