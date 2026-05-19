//
// AVDManagerService.swift
// CleanDroid Gaming
//
// Handles Android Virtual Device discovery and creation. The recommended device
// uses an ARM64 Google Play image for Apple Silicon Macs whenever it is available.

import Foundation

@MainActor
final class AVDManagerService {
    let recommendedAVDName = "CleanDroid_Gaming"
    let recommendedSystemImage = "system-images;android-35;google_apis_playstore;arm64-v8a"

    private let logService: LogService

    init(logService: LogService) {
        self.logService = logService
    }

    func listAVDs(avdManagerURL: URL) async throws -> [AVDDevice] {
        logService.log(
            "Listing Android Virtual Devices available on this Mac.",
            level: .command,
            command: "avdmanager list avd"
        )

        let result = try await ShellCommandRunner.run(
            executableURL: avdManagerURL,
            arguments: ["list", "avd"]
        )

        guard result.succeeded else {
            logService.log(result.combinedOutput, level: .error)
            return []
        }

        return parseAVDs(from: result.standardOutput)
    }

    func createRecommendedAVD(info: AndroidSDKInfo) async throws {
        guard let avdManagerURL = info.avdManagerURL else {
            logService.log("Cannot create an AVD because avdmanager was not found.", level: .error)
            return
        }

        if let sdkManagerURL = info.sdkManagerURL {
            logService.log(
                "Installing the recommended ARM64 Google Play system image if it is missing.",
                level: .command,
                command: "sdkmanager --install \(recommendedSystemImage)"
            )

            let installResult = try await ShellCommandRunner.run(
                executableURL: sdkManagerURL,
                arguments: ["--install", recommendedSystemImage],
                standardInput: "y\n"
            )

            if installResult.succeeded {
                logService.log("Recommended system image is available.", level: .success)
            } else {
                logService.log(
                    "SDK Manager could not install the Play Store image automatically. You may need to accept Android SDK licenses in Android Studio.",
                    level: .warning
                )
            }
        }

        logService.log(
            "Creating the CleanDroid Gaming AVD. The answer 'no' keeps the standard hardware profile.",
            level: .command,
            command: "avdmanager create avd --force --name \(recommendedAVDName) --package \(recommendedSystemImage) --device pixel_7"
        )

        let result = try await ShellCommandRunner.run(
            executableURL: avdManagerURL,
            arguments: [
                "create", "avd",
                "--force",
                "--name", recommendedAVDName,
                "--package", recommendedSystemImage,
                "--device", "pixel_7"
            ],
            standardInput: "no\n"
        )

        if result.succeeded {
            logService.log("Recommended gaming AVD created.", level: .success)
        } else {
            logService.log(result.combinedOutput, level: .error)
        }
    }

    func acceptLicenses(sdkManagerURL: URL) async throws {
        logService.log(
            "Accepting Android SDK licenses so system image installation can continue.",
            level: .command,
            command: "sdkmanager --licenses"
        )

        let yesAnswers = Array(repeating: "y", count: 20).joined(separator: "\n") + "\n"
        let result = try await ShellCommandRunner.run(
            executableURL: sdkManagerURL,
            arguments: ["--licenses"],
            standardInput: yesAnswers
        )

        if result.succeeded {
            logService.log("Android SDK licenses accepted or already up to date.", level: .success)
        } else {
            logService.log(result.combinedOutput, level: .warning)
        }
    }

    func apply(settings: GamingSettings, toAVDNamed avdName: String) {
        let configURL = FileManager.default
            .homeDirectoryForCurrentUser
            .appendingPathComponent(".android/avd/\(avdName).avd/config.ini")

        guard FileManager.default.fileExists(atPath: configURL.path) else {
            logService.log("AVD config file was not found at \(configURL.path). Settings will apply after the AVD exists.", level: .warning)
            return
        }

        do {
            var config = try String(contentsOf: configURL, encoding: .utf8)
            let resolution = settings.resolutionPreset.size

            set("hw.ramSize", to: "\(settings.ramPreset.megabytes)", in: &config)
            set("hw.cpu.ncore", to: "\(settings.cpuPreset.cores)", in: &config)
            set("hw.lcd.width", to: "\(resolution.width)", in: &config)
            set("hw.lcd.height", to: "\(resolution.height)", in: &config)
            set("hw.lcd.density", to: "\(settings.dpiPreset.value)", in: &config)
            set("hw.gpu.enabled", to: "yes", in: &config)
            set("hw.gpu.mode", to: "host", in: &config)
            set("showDeviceFrame", to: settings.hideOfficialEmulatorToolbar ? "no" : "yes", in: &config)
            set("skin.dynamic", to: settings.hideOfficialEmulatorToolbar ? "no" : "yes", in: &config)

            if settings.hideOfficialEmulatorToolbar {
                remove("skin.name", from: &config)
                remove("skin.path", from: &config)
            }

            try config.write(to: configURL, atomically: true, encoding: .utf8)
            logService.log("Performance settings were written to \(avdName).", level: .success)
        } catch {
            logService.log("Could not update AVD settings: \(error.localizedDescription)", level: .error)
        }
    }

    private func parseAVDs(from text: String) -> [AVDDevice] {
        var devices: [AVDDevice] = []
        var current: [String: String] = [:]

        func finishCurrent() {
            guard let name = current["Name"] else {
                return
            }

            devices.append(
                AVDDevice(
                    name: name,
                    device: current["Device"] ?? "Unknown device",
                    path: current["Path"] ?? "",
                    target: current["Target"] ?? "Unknown target",
                    basedOn: current["Based on"] ?? "",
                    isRecommended: name == recommendedAVDName
                )
            )
        }

        for rawLine in text.components(separatedBy: .newlines) {
            let line = rawLine.trimmingCharacters(in: .whitespaces)

            if line.hasPrefix("---------") {
                finishCurrent()
                current.removeAll()
                continue
            }

            let parts = line.split(separator: ":", maxSplits: 1).map(String.init)
            guard parts.count == 2 else {
                continue
            }

            current[parts[0].trimmingCharacters(in: .whitespaces)] = parts[1].trimmingCharacters(in: .whitespaces)
        }

        finishCurrent()
        return devices
    }

    private func set(_ key: String, to value: String, in config: inout String) {
        var lines = config.components(separatedBy: .newlines)

        // Android config files may use either "key=value" or "key = value".
        // Removing old copies first avoids duplicate settings fighting each other.
        lines.removeAll { configKey(from: $0) == key }
        lines.append("\(key)=\(value)")

        config = lines.joined(separator: "\n")
    }

    private func remove(_ key: String, from config: inout String) {
        let lines = config.components(separatedBy: .newlines)
        config = lines
            .filter { configKey(from: $0) != key }
            .joined(separator: "\n")
    }

    private func configKey(from line: String) -> String? {
        let trimmedLine = line.trimmingCharacters(in: .whitespaces)

        guard !trimmedLine.hasPrefix("#"),
              let separatorIndex = trimmedLine.firstIndex(of: "=") else {
            return nil
        }

        return trimmedLine[..<separatorIndex]
            .trimmingCharacters(in: .whitespaces)
    }
}
