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

            // Drain stdout and stderr on background queues while the child runs.
            // Reading only after termination (in a terminationHandler) can deadlock:
            // once the child fills the ~64KB pipe buffer it blocks on write and never
            // exits, so the handler that would drain the pipe is never called.
            let outputQueue = DispatchQueue(label: "com.macdroid.shell-output", attributes: .concurrent)
            let readGroup = DispatchGroup()

            var stdoutData = Data()
            var stderrData = Data()

            readGroup.enter()
            outputQueue.async {
                stdoutData = stdoutPipe.fileHandleForReading.readDataToEndOfFile()
                readGroup.leave()
            }

            readGroup.enter()
            outputQueue.async {
                stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
                readGroup.leave()
            }

            do {
                try process.run()

                if let standardInput {
                    stdinPipe.fileHandleForWriting.write(Data(standardInput.utf8))
                }

                try? stdinPipe.fileHandleForWriting.close()
            } catch {
                // The child never launched, so close the write ends to release the
                // pending reads before reporting the failure.
                try? stdoutPipe.fileHandleForWriting.close()
                try? stderrPipe.fileHandleForWriting.close()
                continuation.resume(
                    throwing: ShellCommandError.failedToLaunch(error.localizedDescription)
                )
                return
            }

            // Wait for exit and full drain off the calling thread so the caller's
            // async context is never blocked.
            outputQueue.async {
                process.waitUntilExit()
                readGroup.wait()

                let stdout = String(data: stdoutData, encoding: .utf8) ?? ""
                let stderr = String(data: stderrData, encoding: .utf8) ?? ""

                continuation.resume(
                    returning: ShellCommandResult(
                        standardOutput: stdout,
                        standardError: stderr,
                        exitCode: process.terminationStatus
                    )
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
