//
// AndroidSDKDetector.swift
// CleanDroid Gaming
//
// Finds the official Android SDK tools on the Mac. This app is intentionally a
// wrapper around Google's Android Emulator rather than a custom emulator engine.

import Foundation

@MainActor
final class AndroidSDKDetector {
    private let logService: LogService

    init(logService: LogService) {
        self.logService = logService
    }

    func detect(preferredRoot: URL? = nil) async -> AndroidSDKInfo {
        logService.log("Scanning this Mac for the official Android SDK tools.", level: .info)

        let roots = sdkRootCandidates(preferredRoot: preferredRoot)
        let adbURL = await findTool(named: "adb", relativePaths: ["platform-tools/adb"], roots: roots)
        let emulatorURL = await findTool(named: "emulator", relativePaths: ["emulator/emulator"], roots: roots)
        let avdManagerURL = await findTool(
            named: "avdmanager",
            relativePaths: [
                "cmdline-tools/latest/bin/avdmanager",
                "cmdline-tools/bin/avdmanager",
                "tools/bin/avdmanager"
            ],
            roots: roots
        )
        let sdkManagerURL = await findTool(
            named: "sdkmanager",
            relativePaths: [
                "cmdline-tools/latest/bin/sdkmanager",
                "cmdline-tools/bin/sdkmanager",
                "tools/bin/sdkmanager"
            ],
            roots: roots
        )

        let inferredRoot = inferSDKRoot(from: adbURL)
            ?? inferSDKRoot(from: emulatorURL)
            ?? roots.first(where: { FileManager.default.fileExists(atPath: $0.path) })

        var messages: [String] = []
        messages.append(adbURL == nil ? "ADB was not found." : "ADB found at \(adbURL!.path).")
        messages.append(emulatorURL == nil ? "Emulator binary was not found." : "Emulator found at \(emulatorURL!.path).")
        messages.append(avdManagerURL == nil ? "AVD Manager was not found." : "AVD Manager found at \(avdManagerURL!.path).")
        messages.append(sdkManagerURL == nil ? "SDK Manager was not found." : "SDK Manager found at \(sdkManagerURL!.path).")

        let playStoreImageAvailable = await detectPlayStoreARMImage(sdkManagerURL: sdkManagerURL)

        if playStoreImageAvailable {
            messages.append("A Google Play ARM64 system image appears to be installed.")
        } else {
            messages.append("Google Play ARM64 image not detected. Play Store support may need SDK Manager installation.")
        }

        let info = AndroidSDKInfo(
            sdkRoot: inferredRoot,
            adbURL: adbURL,
            emulatorURL: emulatorURL,
            avdManagerURL: avdManagerURL,
            sdkManagerURL: sdkManagerURL,
            detectedMessages: messages,
            playStoreImageAvailable: playStoreImageAvailable
        )

        if info.isReadyForGaming {
            logService.log("Android SDK tools are ready for launcher features.", level: .success)
        } else {
            logService.log("Some Android SDK tools are missing. Install Android Studio or Android command-line tools.", level: .warning)
        }

        return info
    }

    private func sdkRootCandidates(preferredRoot: URL?) -> [URL] {
        let environment = ProcessInfo.processInfo.environment
        let home = FileManager.default.homeDirectoryForCurrentUser

        var candidates: [URL] = []

        if let preferredRoot {
            candidates.append(preferredRoot)
            logService.log("Using the manually selected Android SDK path first: \(preferredRoot.path)", level: .info)
        }

        if let androidHome = environment["ANDROID_HOME"], !androidHome.isEmpty {
            candidates.append(URL(fileURLWithPath: androidHome))
        }

        if let androidSDKRoot = environment["ANDROID_SDK_ROOT"], !androidSDKRoot.isEmpty {
            candidates.append(URL(fileURLWithPath: androidSDKRoot))
        }

        candidates.append(home.appendingPathComponent("Library/Android/sdk"))
        candidates.append(URL(fileURLWithPath: "/opt/homebrew/share/android-commandlinetools"))
        candidates.append(URL(fileURLWithPath: "/usr/local/share/android-sdk"))

        return Array(NSOrderedSet(array: candidates).array as? [URL] ?? candidates)
    }

    private func findTool(named name: String, relativePaths: [String], roots: [URL]) async -> URL? {
        for root in roots {
            for relativePath in relativePaths {
                let candidate = root.appendingPathComponent(relativePath)
                if FileManager.default.isExecutableFile(atPath: candidate.path) {
                    return candidate
                }
            }
        }

        return await ShellCommandRunner.runWhich(name)
    }

    private func inferSDKRoot(from toolURL: URL?) -> URL? {
        guard let toolURL else {
            return nil
        }

        let pathComponents = toolURL.pathComponents

        if let platformToolsIndex = pathComponents.firstIndex(of: "platform-tools") {
            return URL(fileURLWithPath: pathComponents.prefix(platformToolsIndex).joined(separator: "/"))
        }

        if let emulatorIndex = pathComponents.firstIndex(of: "emulator") {
            return URL(fileURLWithPath: pathComponents.prefix(emulatorIndex).joined(separator: "/"))
        }

        if let cmdlineToolsIndex = pathComponents.firstIndex(of: "cmdline-tools") {
            return URL(fileURLWithPath: pathComponents.prefix(cmdlineToolsIndex).joined(separator: "/"))
        }

        return nil
    }

    private func detectPlayStoreARMImage(sdkManagerURL: URL?) async -> Bool {
        guard let sdkManagerURL else {
            return false
        }

        logService.log(
            "Checking whether a Google Play ARM64 system image is installed.",
            level: .command,
            command: "sdkmanager --list_installed"
        )

        guard let result = try? await ShellCommandRunner.run(
            executableURL: sdkManagerURL,
            arguments: ["--list_installed"]
        ) else {
            return false
        }

        return result.combinedOutput.contains("google_apis_playstore")
            && result.combinedOutput.contains("arm64-v8a")
    }
}
