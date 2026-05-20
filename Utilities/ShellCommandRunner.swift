//
// ShellCommandRunner.swift
// MacDroid
//
// Runs Android SDK tools with Foundation's Process API. All higher-level
// services explain a command to LogService before calling this runner.

import Foundation

struct ShellCommandResult: Equatable {
    var standardOutput: String
    var standardError: String
    var exitCode: Int32

    var combinedOutput: String {
        [standardOutput, standardError]
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .joined(separator: "\n")
    }

    var succeeded: Bool {
        exitCode == 0
    }
}

enum ShellCommandError: LocalizedError {
    case missingExecutable(URL)
    case failedToLaunch(String)

    var errorDescription: String? {
        switch self {
        case .missingExecutable(let url):
            return "The command could not be found at \(url.path)."
        case .failedToLaunch(let message):
            return message
        }
    }
}

enum ShellCommandRunner {
    static func run(
        executableURL: URL,
        arguments: [String],
        environment: [String: String] = [:],
        standardInput: String? = nil
    ) async throws -> ShellCommandResult {
        guard FileManager.default.isExecutableFile(atPath: executableURL.path) else {
            throw ShellCommandError.missingExecutable(executableURL)
        }

        return try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            let stdoutPipe = Pipe()
            let stderrPipe = Pipe()
            let stdinPipe = Pipe()

            process.executableURL = executableURL
            process.arguments = arguments
            process.standardOutput = stdoutPipe
            process.standardError = stderrPipe
            process.standardInput = stdinPipe

            if !environment.isEmpty {
                process.environment = ProcessInfo.processInfo.environment.merging(environment) { _, new in new }
            }

            process.terminationHandler = { finishedProcess in
                let stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()

                let stdout = String(data: stdoutData, encoding: .utf8) ?? ""
                let stderr = String(data: stderrData, encoding: .utf8) ?? ""

                continuation.resume(
                    returning: ShellCommandResult(
                        standardOutput: stdout,
                        standardError: stderr,
                        exitCode: finishedProcess.terminationStatus
                    )
                )
            }

            do {
                try process.run()

                if let standardInput {
                    stdinPipe.fileHandleForWriting.write(Data(standardInput.utf8))
                }

                try? stdinPipe.fileHandleForWriting.close()
            } catch {
                continuation.resume(
                    throwing: ShellCommandError.failedToLaunch(error.localizedDescription)
                )
            }
        }
    }

    static func runWhich(_ binaryName: String) async -> URL? {
        let envURL = URL(fileURLWithPath: "/usr/bin/env")

        guard let result = try? await run(executableURL: envURL, arguments: ["which", binaryName]),
              result.succeeded else {
            return nil
        }

        let path = result.standardOutput.trimmingCharacters(in: .whitespacesAndNewlines)
        return path.isEmpty ? nil : URL(fileURLWithPath: path)
    }
}
