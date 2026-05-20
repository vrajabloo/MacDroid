//
// InputMappingExecutionService.swift
// MacDroid
//
// Executes saved input mappings through ADB. This gives MacDroid a working
// input bridge without pretending to replace the official emulator engine.

import Foundation

@MainActor
final class InputMappingExecutionService {
    private let logService: LogService

    init(logService: LogService) {
        self.logService = logService
    }

    func send(
        mapping: InputMapping,
        fallbackResolution: ResolutionPreset,
        adbURL: URL,
        serial: String?
    ) async throws {
        guard mapping.isEnabled else {
            logService.log("\(mapping.trigger) is disabled, so MacDroid skipped it.", level: .info)
            return
        }

        let screenSize = await androidScreenSize(
            adbURL: adbURL,
            serial: serial,
            fallbackResolution: fallbackResolution
        )
        let firstPoint = pixelPoint(mapping.tapPoint, in: screenSize)
        let secondPoint = pixelPoint(mapping.secondaryPoint ?? mapping.tapPoint, in: screenSize)
        let duration = max(50, min(5_000, mapping.durationMilliseconds))

        let commandArguments: [String]
        let actionDescription: String

        switch mapping.action {
        case .tap:
            commandArguments = ["shell", "input", "tap", "\(firstPoint.x)", "\(firstPoint.y)"]
            actionDescription = "tap"
        case .longPress:
            commandArguments = [
                "shell", "input", "swipe",
                "\(firstPoint.x)", "\(firstPoint.y)",
                "\(firstPoint.x)", "\(firstPoint.y)",
                "\(duration)"
            ]
            actionDescription = "long press"
        case .swipe:
            commandArguments = [
                "shell", "input", "swipe",
                "\(firstPoint.x)", "\(firstPoint.y)",
                "\(secondPoint.x)", "\(secondPoint.y)",
                "\(duration)"
            ]
            actionDescription = "swipe"
        }

        let arguments = targetedArguments(commandArguments, serial: serial)

        logService.log(
            "Running \(mapping.trigger) as an Android \(actionDescription) at \(firstPoint.x), \(firstPoint.y).",
            level: .command,
            command: "adb \(arguments.joined(separator: " "))"
        )

        let result = try await ShellCommandRunner.run(
            executableURL: adbURL,
            arguments: arguments
        )

        if result.succeeded {
            logService.log("\(mapping.trigger) mapping sent successfully.", level: .success)
        } else {
            logService.log(result.combinedOutput, level: .error)
        }
    }

    func sendDirectTap(
        at point: NormalizedPoint,
        fallbackResolution: ResolutionPreset,
        adbURL: URL,
        serial: String?
    ) async throws {
        let mapping = InputMapping(
            inputType: .mouse,
            trigger: "Overlay Click",
            action: .tap,
            tapPoint: point,
            durationMilliseconds: 80,
            note: "Direct overlay click"
        )

        try await send(
            mapping: mapping,
            fallbackResolution: fallbackResolution,
            adbURL: adbURL,
            serial: serial
        )
    }

    private func androidScreenSize(
        adbURL: URL,
        serial: String?,
        fallbackResolution: ResolutionPreset
    ) async -> AndroidScreenSize {
        let fallback = AndroidScreenSize(
            width: fallbackResolution.size.width,
            height: fallbackResolution.size.height
        )
        let arguments = targetedArguments(["shell", "wm", "size"], serial: serial)

        logService.log(
            "Reading Android's real screen size so key mapping taps land in the right place.",
            level: .command,
            command: "adb \(arguments.joined(separator: " "))"
        )

        guard let result = try? await ShellCommandRunner.run(
            executableURL: adbURL,
            arguments: arguments
        ), result.succeeded else {
            return fallback
        }

        return parseScreenSize(from: result.standardOutput) ?? fallback
    }

    private func parseScreenSize(from text: String) -> AndroidScreenSize? {
        guard let range = text.range(
            of: #"([0-9]+)x([0-9]+)"#,
            options: .regularExpression
        ) else {
            return nil
        }

        let sizeText = String(text[range])
        let parts = sizeText.split(separator: "x").compactMap { Int($0) }
        guard parts.count == 2 else {
            return nil
        }

        return AndroidScreenSize(width: parts[0], height: parts[1])
    }

    private func pixelPoint(_ point: NormalizedPoint, in screenSize: AndroidScreenSize) -> (x: Int, y: Int) {
        let clampedPoint = point.clamped
        let x = max(0, min(screenSize.width - 1, Int(Double(screenSize.width) * clampedPoint.x)))
        let y = max(0, min(screenSize.height - 1, Int(Double(screenSize.height) * clampedPoint.y)))
        return (x, y)
    }

    private func targetedArguments(_ arguments: [String], serial: String?) -> [String] {
        guard let serial, !serial.isEmpty else {
            return arguments
        }

        return ["-s", serial] + arguments
    }
}

private struct AndroidScreenSize {
    var width: Int
    var height: Int
}
