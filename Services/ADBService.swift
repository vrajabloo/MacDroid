//
// ADBService.swift
// MacDroid
//
// Wraps Android Debug Bridge commands. ADB is how the macOS launcher lists,
// installs, launches, and uninstalls Android apps inside the official emulator.

import Foundation

@MainActor
final class ADBService {
    private let logService: LogService

    init(logService: LogService) {
        self.logService = logService
    }

    func connectedDevices(adbURL: URL) async throws -> [String] {
        logService.log(
            "Asking ADB which Android devices are connected.",
            level: .command,
            command: "adb devices"
        )

        let result = try await ShellCommandRunner.run(executableURL: adbURL, arguments: ["devices"])

        guard result.succeeded else {
            logService.log(result.combinedOutput, level: .error)
            return []
        }

        return result.standardOutput
            .components(separatedBy: .newlines)
            .dropFirst()
            .compactMap { line in
                let parts = line.split(whereSeparator: { $0 == "\t" || $0 == " " }).map(String.init)
                guard parts.count == 2, parts[1] == "device" else {
                    return nil
                }
                return parts[0]
            }
    }

    func isAnyDeviceOnline(adbURL: URL) async -> Bool {
        let devices = (try? await connectedDevices(adbURL: adbURL)) ?? []
        return !devices.isEmpty
    }

    func preferredEmulatorSerial(adbURL: URL, preferredSerial: String? = nil) async -> String? {
        let devices = (try? await connectedDevices(adbURL: adbURL)) ?? []

        if let preferredSerial,
           preferredSerial.hasPrefix("emulator-"),
           devices.contains(preferredSerial) {
            return preferredSerial
        }

        if let emulator = devices.first(where: { $0.hasPrefix("emulator-") }) {
            return emulator
        }

        if let preferredSerial,
           devices.contains(preferredSerial) {
            return preferredSerial
        }

        return devices.first
    }

    func bootCompleted(adbURL: URL, serial: String? = nil) async -> Bool {
        let targetSerial = await preferredEmulatorSerial(adbURL: adbURL, preferredSerial: serial)

        logService.log(
            "Checking whether Android has finished booting.",
            level: .command,
            command: readableCommand(["shell", "getprop", "sys.boot_completed"], serial: targetSerial)
        )

        guard let result = try? await ShellCommandRunner.run(
            executableURL: adbURL,
            arguments: targetedArguments(["shell", "getprop", "sys.boot_completed"], serial: targetSerial)
        ) else {
            return false
        }

        return result.standardOutput.trimmingCharacters(in: .whitespacesAndNewlines) == "1"
    }

    func deviceInfo(adbURL: URL) async -> AndroidDeviceInfo {
        let serial = await preferredEmulatorSerial(adbURL: adbURL)

        logService.log(
            "Reading friendly emulator details from Android system properties.",
            level: .command,
            command: readableCommand(["shell", "getprop"], serial: serial)
        )

        let manufacturer = await property("ro.product.manufacturer", adbURL: adbURL, serial: serial)
        let model = await property("ro.product.model", adbURL: adbURL, serial: serial)
        let androidVersion = await property("ro.build.version.release", adbURL: adbURL, serial: serial)
        let apiLevel = await property("ro.build.version.sdk", adbURL: adbURL, serial: serial)
        let abi = await property("ro.product.cpu.abi", adbURL: adbURL, serial: serial)
        let bootValue = await property("sys.boot_completed", adbURL: adbURL, serial: serial)

        return AndroidDeviceInfo(
            serial: serial,
            manufacturer: manufacturer,
            model: model,
            androidVersion: androidVersion,
            apiLevel: apiLevel,
            abi: abi,
            bootCompleted: bootValue == "1"
        )
    }

    func waitForDevice(adbURL: URL) async throws {
        logService.log(
            "Waiting for the emulator to accept ADB commands.",
            level: .command,
            command: "adb wait-for-device"
        )

        _ = try await ShellCommandRunner.run(executableURL: adbURL, arguments: ["wait-for-device"])
    }

    func restartServer(adbURL: URL) async throws {
        logService.log(
            "Restarting ADB. This can fix stuck device detection without rebuilding the emulator.",
            level: .command,
            command: "adb kill-server && adb start-server"
        )

        let killResult = try await ShellCommandRunner.run(executableURL: adbURL, arguments: ["kill-server"])
        if !killResult.succeeded {
            logService.log(killResult.combinedOutput, level: .warning)
        }

        let startResult = try await ShellCommandRunner.run(executableURL: adbURL, arguments: ["start-server"])
        guard startResult.succeeded else {
            logService.log(startResult.combinedOutput, level: .error)
            throw ShellCommandError.failedToLaunch(startResult.combinedOutput)
        }

        logService.log("ADB server restarted.", level: .success)
    }

    func listInstalledUserApps(adbURL: URL, serial: String? = nil) async throws -> [AndroidApp] {
        let targetSerial = await preferredEmulatorSerial(adbURL: adbURL, preferredSerial: serial)

        logService.log(
            "Reading installed user apps from Android. MacDroid enriches the list with basic package metadata when available.",
            level: .command,
            command: readableCommand(["shell", "pm", "list", "packages", "-3", "-f"], serial: targetSerial)
        )

        let result = try await ShellCommandRunner.run(
            executableURL: adbURL,
            arguments: targetedArguments(["shell", "pm", "list", "packages", "-3", "-f"], serial: targetSerial)
        )

        guard result.succeeded else {
            logService.log(result.combinedOutput, level: .error)
            return []
        }

        var apps: [AndroidApp] = []

        for line in result.standardOutput.components(separatedBy: .newlines) {
            guard let app = parsePackageListLine(line) else {
                continue
            }

            let metadata = await packageMetadata(packageName: app.packageName, adbURL: adbURL, serial: targetSerial)
            var enrichedApp = app
            enrichedApp.versionName = metadata.versionName
            enrichedApp.installedAt = metadata.firstInstalledAt
            apps.append(enrichedApp)
        }

        return apps.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }

    func captureScreenshot(adbURL: URL, serial: String? = nil) async throws -> URL? {
        try AppPaths.ensureScreenshotsDirectory()

        let targetSerial = await preferredEmulatorSerial(adbURL: adbURL, preferredSerial: serial)
        let fileName = "macdroid-\(Int(Date().timeIntervalSince1970)).png"
        let androidPath = "/sdcard/\(fileName)"
        let localURL = AppPaths.screenshotsDirectory.appendingPathComponent(fileName)

        logService.log(
            "Capturing a screenshot from the running emulator.",
            level: .command,
            command: readableCommand(["shell", "screencap", "-p", androidPath], serial: targetSerial)
        )

        let captureResult = try await ShellCommandRunner.run(
            executableURL: adbURL,
            arguments: targetedArguments(["shell", "screencap", "-p", androidPath], serial: targetSerial)
        )

        guard captureResult.succeeded else {
            logService.log(captureResult.combinedOutput, level: .error)
            return nil
        }

        logService.log(
            "Pulling the screenshot from Android storage to the Mac.",
            level: .command,
            command: readableCommand(["pull", androidPath, localURL.path], serial: targetSerial)
        )

        let pullResult = try await ShellCommandRunner.run(
            executableURL: adbURL,
            arguments: targetedArguments(["pull", androidPath, localURL.path], serial: targetSerial)
        )

        _ = try? await ShellCommandRunner.run(
            executableURL: adbURL,
            arguments: targetedArguments(["shell", "rm", androidPath], serial: targetSerial)
        )

        guard pullResult.succeeded else {
            logService.log(pullResult.combinedOutput, level: .error)
            return nil
        }

        logService.log("Screenshot saved to \(localURL.path).", level: .success)
        return localURL
    }

    func recentLogcat(adbURL: URL, lineCount: Int = 200, serial: String? = nil) async throws -> String {
        let targetSerial = await preferredEmulatorSerial(adbURL: adbURL, preferredSerial: serial)

        logService.log(
            "Collecting recent Android logcat output for troubleshooting.",
            level: .command,
            command: readableCommand(["logcat", "-d", "-t", "\(lineCount)"], serial: targetSerial)
        )

        let result = try await ShellCommandRunner.run(
            executableURL: adbURL,
            arguments: targetedArguments(["logcat", "-d", "-t", "\(lineCount)"], serial: targetSerial)
        )

        guard result.succeeded else {
            logService.log(result.combinedOutput, level: .error)
            return ""
        }

        logService.log("Recent logcat output loaded into the troubleshooting panel.", level: .success)
        return result.standardOutput
    }

    func rebootDevice(adbURL: URL, serial: String? = nil) async throws {
        let targetSerial = await preferredEmulatorSerial(adbURL: adbURL, preferredSerial: serial)
        let arguments = ["reboot"]

        logService.log(
            "Rebooting Android inside the emulator.",
            level: .command,
            command: readableCommand(arguments, serial: targetSerial)
        )

        let result = try await ShellCommandRunner.run(
            executableURL: adbURL,
            arguments: targetedArguments(arguments, serial: targetSerial)
        )

        guard result.succeeded else {
            logService.log(result.combinedOutput, level: .error)
            throw ShellCommandError.failedToLaunch(result.combinedOutput)
        }

        logService.log("Android reboot command sent.", level: .success)
    }

    func clearPlayStoreData(adbURL: URL, serial: String? = nil) async throws {
        let targetSerial = await preferredEmulatorSerial(adbURL: adbURL, preferredSerial: serial)
        let commands = [
            ["shell", "am", "force-stop", "com.android.vending"],
            ["shell", "pm", "clear", "com.android.vending"],
            ["shell", "cmd", "package", "trim-caches", "4G"]
        ]

        for arguments in commands {
            logService.log(
                "Clearing Play Store download state and cache pressure.",
                level: .command,
                command: readableCommand(arguments, serial: targetSerial)
            )

            let result = try await ShellCommandRunner.run(
                executableURL: adbURL,
                arguments: targetedArguments(arguments, serial: targetSerial)
            )

            if !result.succeeded {
                logService.log(result.combinedOutput, level: .warning)
            }
        }

        logService.log("Play Store cache/data reset completed. Open Play Store and sign in again if Android asks.", level: .success)
    }

    func openAppInfo(packageName: String, adbURL: URL, serial: String? = nil) async throws {
        let targetSerial = await preferredEmulatorSerial(adbURL: adbURL, preferredSerial: serial)
        let arguments = [
            "shell",
            "am",
            "start",
            "-a",
            "android.settings.APPLICATION_DETAILS_SETTINGS",
            "-d",
            "package:\(packageName)"
        ]

        logService.log(
            "Opening Android app details for \(packageName).",
            level: .command,
            command: readableCommand(arguments, serial: targetSerial)
        )

        let result = try await ShellCommandRunner.run(
            executableURL: adbURL,
            arguments: targetedArguments(arguments, serial: targetSerial)
        )

        guard result.succeeded else {
            logService.log(result.combinedOutput, level: .error)
            throw ShellCommandError.failedToLaunch(result.combinedOutput)
        }
    }

    func ping(host: String, adbURL: URL, serial: String? = nil) async throws -> String {
        let targetSerial = await preferredEmulatorSerial(adbURL: adbURL, preferredSerial: serial)
        let arguments = ["shell", "ping", "-c", "4", host]

        logService.log(
            "Testing emulator network latency to \(host).",
            level: .command,
            command: readableCommand(arguments, serial: targetSerial)
        )

        let result = try await ShellCommandRunner.run(
            executableURL: adbURL,
            arguments: targetedArguments(arguments, serial: targetSerial)
        )

        if result.succeeded {
            logService.log("Network test to \(host) completed.", level: .success)
        } else {
            logService.log(result.combinedOutput, level: .warning)
        }

        return result.combinedOutput
    }

    func sendNavigationKey(
        _ key: AndroidNavigationKey,
        adbURL: URL,
        serial: String?
    ) async throws -> String {
        let targetSerial = await preferredEmulatorSerial(adbURL: adbURL, preferredSerial: serial)
        let commandGroups = key.commandGroups

        logService.log(
            "Sending Android \(key.title) through ADB.",
            level: .command,
            command: readableCommand(commandGroups.first ?? [], serial: targetSerial)
        )

        var lastOutput = ""

        for arguments in commandGroups {
            let result = try await ShellCommandRunner.run(
                executableURL: adbURL,
                arguments: targetedArguments(arguments, serial: targetSerial)
            )

            lastOutput = result.combinedOutput

            if result.succeeded {
                logService.log(
                    "Android \(key.title) command sent to \(targetSerial ?? "the active ADB device").",
                    level: .success,
                    command: readableCommand(arguments, serial: targetSerial)
                )

                return targetSerial ?? "active ADB device"
            }

            logService.log(
                "Navigation command did not succeed, trying fallback if available: \(result.combinedOutput)",
                level: .warning,
                command: readableCommand(arguments, serial: targetSerial)
            )
        }

        throw ShellCommandError.failedToLaunch(lastOutput.isEmpty ? "ADB navigation command failed." : lastOutput)
    }

    func sendKeyEvent(
        title: String,
        keyCode: String,
        adbURL: URL,
        serial: String?
    ) async throws -> String {
        let targetSerial = await preferredEmulatorSerial(adbURL: adbURL, preferredSerial: serial)
        let arguments = ["shell", "input", "keyevent", keyCode]

        logService.log(
            "Sending emulator \(title) through ADB.",
            level: .command,
            command: readableCommand(arguments, serial: targetSerial)
        )

        let result = try await ShellCommandRunner.run(
            executableURL: adbURL,
            arguments: targetedArguments(arguments, serial: targetSerial)
        )

        guard result.succeeded else {
            logService.log(result.combinedOutput, level: .error)
            throw ShellCommandError.failedToLaunch(result.combinedOutput)
        }

        logService.log("\(title) sent to \(targetSerial ?? "the active ADB device").", level: .success)
        return targetSerial ?? "active ADB device"
    }

    func setRotation(
        _ rotation: Int,
        adbURL: URL,
        serial: String?
    ) async throws -> String {
        let targetSerial = await preferredEmulatorSerial(adbURL: adbURL, preferredSerial: serial)
        let normalizedRotation = ((rotation % 4) + 4) % 4

        await applyRotationCompatibility(adbURL: adbURL, serial: targetSerial)

        let commands: [(message: String, arguments: [String])] = [
            (
                "Locking Android to the selected emulator rotation.",
                ["shell", "wm", "user-rotation", "lock", "\(normalizedRotation)"]
            ),
            (
                "Saving the selected rotation for older Android images.",
                ["shell", "settings", "put", "system", "user_rotation", "\(normalizedRotation)"]
            )
        ]
        var didSetRotation = false
        var lastError = ""

        for command in commands {
            logService.log(
                command.message,
                level: .command,
                command: readableCommand(command.arguments, serial: targetSerial)
            )

            let result = try await ShellCommandRunner.run(
                executableURL: adbURL,
                arguments: targetedArguments(command.arguments, serial: targetSerial)
            )

            if result.succeeded {
                didSetRotation = true
            } else {
                lastError = result.combinedOutput
                logService.log(result.combinedOutput, level: .warning)
            }
        }

        guard didSetRotation else {
            logService.log(lastError, level: .error)
            throw ShellCommandError.failedToLaunch(lastError)
        }

        logService.log("Rotation set on \(targetSerial ?? "the active ADB device").", level: .success)
        return targetSerial ?? "active ADB device"
    }

    func repairAppRotation(
        adbURL: URL,
        serial: String?
    ) async throws -> String {
        let targetSerial = await preferredEmulatorSerial(adbURL: adbURL, preferredSerial: serial)

        let didApplyRepair = await applyRotationCompatibility(adbURL: adbURL, serial: targetSerial)

        guard didApplyRepair else {
            let message = "MacDroid could not apply Android rotation repair commands. Check that the emulator is running and reachable through ADB."
            logService.log(message, level: .error)
            throw ShellCommandError.failedToLaunch(message)
        }

        logService.log(
            "Checking whether Android is ignoring app orientation locks.",
            level: .command,
            command: readableCommand(["shell", "wm", "get-ignore-orientation-request"], serial: targetSerial)
        )
        let result = try await ShellCommandRunner.run(
            executableURL: adbURL,
            arguments: targetedArguments(["shell", "wm", "get-ignore-orientation-request"], serial: targetSerial)
        )

        if result.succeeded {
            logService.log("App rotation repair is active: \(result.standardOutput.trimmingCharacters(in: .whitespacesAndNewlines))", level: .success)
        } else {
            logService.log(result.combinedOutput, level: .warning)
        }

        return targetSerial ?? "active ADB device"
    }

    @discardableResult
    private func applyRotationCompatibility(adbURL: URL, serial: String?) async -> Bool {
        let commands: [(message: String, arguments: [String])] = [
            (
                "Asking Android to ignore apps that lock themselves to portrait or landscape.",
                ["shell", "wm", "set-ignore-orientation-request", "true"]
            ),
            (
                "Making Android keep apps aligned with the user's emulator rotation.",
                ["shell", "wm", "fixed-to-user-rotation", "enabled"]
            ),
            (
                "Turning off automatic rotation so the emulator toolbar controls orientation.",
                ["shell", "settings", "put", "system", "accelerometer_rotation", "0"]
            ),
            (
                "Allowing more Android apps to resize when the emulator is in landscape.",
                ["shell", "settings", "put", "global", "force_resizable_activities", "1"]
            ),
            (
                "Enabling Android sandbox display compatibility for apps that read display size directly.",
                ["shell", "wm", "set-sandbox-display-apis", "true"]
            )
        ]
        var successfulCommands = 0

        for command in commands {
            logService.log(
                command.message,
                level: .command,
                command: readableCommand(command.arguments, serial: serial)
            )

            do {
                let result = try await ShellCommandRunner.run(
                    executableURL: adbURL,
                    arguments: targetedArguments(command.arguments, serial: serial)
                )

                if result.succeeded {
                    successfulCommands += 1
                } else {
                    logService.log(result.combinedOutput, level: .warning)
                }
            } catch {
                logService.log("Rotation repair command failed: \(error.localizedDescription)", level: .warning)
            }
        }

        return successfulCommands > 0
    }

    private func parsePackageListLine(_ line: String) -> AndroidApp? {
        let cleaned = line.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else {
            return nil
        }

        let withoutPrefix = cleaned.replacingOccurrences(of: "package:", with: "")

        let sourceDir: String?
        let packageName: String

        // ADB prints "apkPath=packageName". Some APK paths also contain "=",
        // so splitting at the first "=" produces broken package labels.
        if let separatorIndex = withoutPrefix.lastIndex(of: "=") {
            sourceDir = String(withoutPrefix[..<separatorIndex])
            packageName = String(withoutPrefix[withoutPrefix.index(after: separatorIndex)...])
        } else {
            sourceDir = nil
            packageName = withoutPrefix
        }

        guard !packageName.isEmpty else {
            return nil
        }

        return AndroidApp(
            name: Self.readableName(from: packageName),
            packageName: packageName,
            iconData: nil,
            lastPlayed: nil,
            installedAt: nil,
            versionName: nil,
            sourceDir: sourceDir,
            artworkSeed: Self.stableSeed(from: packageName)
        )
    }

    private func property(_ key: String, adbURL: URL, serial: String?) async -> String? {
        guard let result = try? await ShellCommandRunner.run(
            executableURL: adbURL,
            arguments: targetedArguments(["shell", "getprop", key], serial: serial)
        ) else {
            return nil
        }

        let value = result.standardOutput.trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }

    private func targetedArguments(_ arguments: [String], serial: String?) -> [String] {
        guard let serial, !serial.isEmpty else {
            return arguments
        }

        return ["-s", serial] + arguments
    }

    private func readableCommand(_ arguments: [String], serial: String?) -> String {
        let allArguments = targetedArguments(arguments, serial: serial)
        return "adb " + allArguments.joined(separator: " ")
    }

    private func packageMetadata(
        packageName: String,
        adbURL: URL,
        serial: String?
    ) async -> (versionName: String?, firstInstalledAt: Date?) {
        guard let result = try? await ShellCommandRunner.run(
            executableURL: adbURL,
            arguments: targetedArguments(["shell", "dumpsys", "package", packageName], serial: serial)
        ), result.succeeded else {
            return (nil, nil)
        }

        let versionName = result.standardOutput
            .components(separatedBy: .newlines)
            .first { $0.trimmingCharacters(in: .whitespaces).hasPrefix("versionName=") }?
            .replacingOccurrences(of: "versionName=", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let firstInstallText = result.standardOutput
            .components(separatedBy: .newlines)
            .first { $0.trimmingCharacters(in: .whitespaces).hasPrefix("firstInstallTime=") }?
            .replacingOccurrences(of: "firstInstallTime=", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return (versionName?.isEmpty == false ? versionName : nil, parseAndroidDate(firstInstallText))
    }

    private func parseAndroidDate(_ text: String?) -> Date? {
        guard let text, !text.isEmpty else {
            return nil
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

        if let date = formatter.date(from: text) {
            return date
        }

        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter.date(from: text)
    }

    func launch(packageName: String, adbURL: URL, serial: String? = nil) async throws {
        let targetSerial = await preferredEmulatorSerial(adbURL: adbURL, preferredSerial: serial)
        let arguments = ["shell", "monkey", "-p", packageName, "-c", "android.intent.category.LAUNCHER", "1"]

        logService.log(
            "Launching \(packageName) with Android's launcher intent.",
            level: .command,
            command: readableCommand(arguments, serial: targetSerial)
        )

        let result = try await ShellCommandRunner.run(
            executableURL: adbURL,
            arguments: targetedArguments(arguments, serial: targetSerial)
        )

        if result.succeeded {
            logService.log("Launch command sent for \(packageName).", level: .success)
        } else {
            logService.log(result.combinedOutput, level: .error)
        }
    }

    func uninstall(packageName: String, adbURL: URL, serial: String? = nil) async throws {
        let targetSerial = await preferredEmulatorSerial(adbURL: adbURL, preferredSerial: serial)
        let arguments = ["uninstall", packageName]

        logService.log(
            "Uninstalling \(packageName) from the emulator.",
            level: .command,
            command: readableCommand(arguments, serial: targetSerial)
        )

        let result = try await ShellCommandRunner.run(
            executableURL: adbURL,
            arguments: targetedArguments(arguments, serial: targetSerial)
        )

        if result.succeeded {
            logService.log("\(packageName) was uninstalled.", level: .success)
        } else {
            logService.log(result.combinedOutput, level: .error)
        }
    }

    func openPlayStore(adbURL: URL, serial: String? = nil) async throws {
        let targetSerial = await preferredEmulatorSerial(adbURL: adbURL, preferredSerial: serial)
        let arguments = ["shell", "monkey", "-p", "com.android.vending", "-c", "android.intent.category.LAUNCHER", "1"]

        logService.log(
            "Opening Google Play Store inside the emulator.",
            level: .command,
            command: readableCommand(arguments, serial: targetSerial)
        )

        let result = try await ShellCommandRunner.run(
            executableURL: adbURL,
            arguments: targetedArguments(arguments, serial: targetSerial)
        )

        if result.succeeded {
            logService.log("Play Store launch command sent.", level: .success)
        } else {
            logService.log("Play Store could not be opened. Use a Google Play system image for this feature.", level: .warning)
        }
    }

    private static func readableName(from packageName: String) -> String {
        let lastComponent = packageName.components(separatedBy: ".").last ?? packageName
        let separated = lastComponent
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")

        return separated.capitalized
    }

    private static func stableSeed(from text: String) -> Int {
        text.unicodeScalars.reduce(0) { partialResult, scalar in
            partialResult &* 31 &+ Int(scalar.value)
        }
    }
}
