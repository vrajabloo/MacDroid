//
// AppEnvironment.swift
// MacDroid
//
// The central coordinator for the app. It owns services, exposes app-wide state,
// and gives SwiftUI views simple async actions such as Start Emulator or Install APK.

import AppKit
import Foundation

@MainActor
final class AppEnvironment: ObservableObject {
    @Published var sdkInfo: AndroidSDKInfo = .empty
    @Published var emulatorState: EmulatorState = .unknown
    @Published var deviceInfo: AndroidDeviceInfo = .empty
    @Published var avds: [AVDDevice] = []
    @Published var selectedAVDName: String
    @Published var games: [AndroidApp] = []
    @Published var keyProfiles: [KeyMappingProfile] = []
    @Published var gameProfiles: [GameProfile] = []
    @Published var healthCheckItems: [HealthCheckItem] = []
    @Published var updateInfo: AppUpdateInfo = .idle
    @Published var settings: GamingSettings
    @Published var isBusy = false
    @Published var installProgress: Double?
    @Published var latestScreenshotURL: URL?
    @Published var recentLogcatText = ""
    @Published var networkDiagnosticText = ""
    @Published var lastNavigationMessage = ""
    @Published var lastEmulatorControlMessage = ""
    @Published var activeKeyMappingPackageName: String?
    @Published var keyMappingOverlayIsArmed = false
    @Published var keyMappingOverlayMessage = "Open a game profile to start mapping."
    @Published var statusMessage = "Ready"

    let logService: LogService
    let sdkDetector: AndroidSDKDetector
    let adbService: ADBService
    let emulatorService: EmulatorService
    let avdManagerService: AVDManagerService
    let apkInstallerService: APKInstallerService
    let gameLibraryService: GameLibraryService
    let keyMappingService: KeyMappingService
    let gameProfileService: GameProfileService
    let healthCheckService: HealthCheckService
    let updateCheckerService: UpdateCheckerService
    let inputMappingExecutionService: InputMappingExecutionService
    let settingsService: SettingsService
    let officialToolbarRepairService: OfficialEmulatorToolbarRepairService

    private var hasBootstrapped = false
    private var hasHandledIconLaunch = false
    private var emulatorRotation = 0

    init() {
        let logService = LogService()
        let settingsService = SettingsService(logService: logService)
        let gameLibraryService = GameLibraryService(logService: logService)
        let keyMappingService = KeyMappingService(logService: logService)
        let gameProfileService = GameProfileService(logService: logService)
        let avdManagerService = AVDManagerService(logService: logService)

        self.logService = logService
        self.settingsService = settingsService
        self.gameLibraryService = gameLibraryService
        self.keyMappingService = keyMappingService
        self.gameProfileService = gameProfileService
        self.healthCheckService = HealthCheckService()
        self.updateCheckerService = UpdateCheckerService(logService: logService)
        self.avdManagerService = avdManagerService
        self.sdkDetector = AndroidSDKDetector(logService: logService)
        self.adbService = ADBService(logService: logService)
        self.emulatorService = EmulatorService(logService: logService)
        self.apkInstallerService = APKInstallerService(logService: logService)
        self.inputMappingExecutionService = InputMappingExecutionService(logService: logService)
        self.officialToolbarRepairService = OfficialEmulatorToolbarRepairService(logService: logService)
        self.settings = settingsService.loadSettings()
        self.games = gameLibraryService.loadCachedLibrary()
        self.keyProfiles = keyMappingService.loadProfiles()
        self.gameProfiles = gameProfileService.loadProfiles()
        self.selectedAVDName = avdManagerService.recommendedAVDName

        logService.log("MacDroid opened. This app wraps the official Google Android Emulator.", level: .info)
    }

    func bootstrap() async {
        guard !hasBootstrapped else {
            return
        }

        hasBootstrapped = true
        await refreshAll()

        if settings.checkForUpdatesAutomatically {
            await checkForUpdates()
        }

        if settings.setupWizardCompleted {
            await startFromAppIconIfNeeded()
        } else {
            logService.log("Setup Wizard is not complete yet. Finish Setup before using auto-start.", level: .info)
        }
    }

    func refreshAll() async {
        await runBusyTask("Refreshing Android environment...") {
            await refreshSDK()
            await refreshAVDs()
            await refreshEmulatorState()

            if emulatorState == .running {
                await refreshGames()
            }

            refreshHealthChecks()
        }
    }

    func refreshSDK() async {
        let customPath = settings.customSDKRootPath?.trimmingCharacters(in: .whitespacesAndNewlines)
        let customRoot = customPath?.isEmpty == false ? URL(fileURLWithPath: customPath!) : nil
        sdkInfo = await sdkDetector.detect(preferredRoot: customRoot)
    }

    func refreshAVDs() async {
        guard let avdManagerURL = sdkInfo.avdManagerURL else {
            avds = []
            return
        }

        do {
            avds = try await avdManagerService.listAVDs(avdManagerURL: avdManagerURL)

            if avds.contains(where: { $0.name == avdManagerService.recommendedAVDName }) {
                selectedAVDName = avdManagerService.recommendedAVDName
            } else if selectedAVDName == avdManagerService.recommendedAVDName,
                      let legacyAVD = avds.first(where: { avdManagerService.legacyRecommendedAVDNames.contains($0.name) }) {
                // Existing users may still have the old AVD. Selecting it preserves installed games after the rename.
                selectedAVDName = legacyAVD.name
                logService.log("Using existing \(legacyAVD.name) AVD until a new MacDroid AVD is created.", level: .info)
            } else if !selectedAVDName.isEmpty,
                      !avds.contains(where: { $0.name == selectedAVDName }),
                      let firstAVD = avds.first {
                selectedAVDName = firstAVD.name
            } else if selectedAVDName.isEmpty, let firstAVD = avds.first {
                selectedAVDName = firstAVD.name
            }
        } catch {
            logService.log("Could not list AVDs: \(error.localizedDescription)", level: .error)
        }
    }

    func createRecommendedAVD() async {
        await runBusyTask("Creating gaming AVD...") {
            do {
                try await avdManagerService.createRecommendedAVD(info: sdkInfo)
                avdManagerService.apply(settings: settings, toAVDNamed: avdManagerService.recommendedAVDName)
                await refreshAVDs()
            } catch {
                logService.log("Could not create the recommended AVD: \(error.localizedDescription)", level: .error)
            }
        }
    }

    func startEmulator() async {
        guard let emulatorURL = sdkInfo.emulatorURL else {
            logService.log("Cannot start the emulator because the emulator binary was not found.", level: .error)
            return
        }

        let avdName = selectedAVDName.isEmpty ? avdManagerService.recommendedAVDName : selectedAVDName

        await runBusyTask("Starting emulator...") {
            do {
                avdManagerService.apply(settings: settings, toAVDNamed: avdName)
                emulatorState = .booting
                try emulatorService.startEmulator(
                    emulatorURL: emulatorURL,
                    avdName: avdName,
                    settings: settings
                )
                updateOfficialToolbarRepair()
                await waitForEmulatorBoot()
            } catch {
                emulatorState = .error
                logService.log("Emulator could not start: \(error.localizedDescription)", level: .error)
            }
        }
    }

    func launchFromEmulatorIcon() async {
        logService.log("Emulator icon clicked. MacDroid will open the gaming emulator experience.", level: .info)

        switch emulatorState {
        case .running:
            await refreshGames()
        case .booting:
            await refreshEmulatorState()
        case .stopped, .unknown, .error:
            await ensureRecommendedAVDIfNeeded()
            let avdName = selectedAVDName.isEmpty ? avdManagerService.recommendedAVDName : selectedAVDName
            guard avdExists(named: avdName) else {
                logService.log("MacDroid could not find a launchable AVD yet. Create the gaming AVD from Home or Settings, then click the emulator icon again.", level: .warning)
                return
            }
            await startEmulator()
        }
    }

    func stopEmulator() async {
        guard let adbURL = sdkInfo.adbURL else {
            logService.log("Cannot stop the emulator because ADB was not found.", level: .error)
            return
        }

        await runBusyTask("Stopping emulator...") {
            do {
                let targetSerial = await adbService.preferredEmulatorSerial(
                    adbURL: adbURL,
                    preferredSerial: deviceInfo.serial
                )
                try await emulatorService.stopEmulator(adbURL: adbURL, serial: targetSerial)
                emulatorState = .stopped
                officialToolbarRepairService.stop()
            } catch {
                emulatorState = .error
                logService.log("Emulator stop failed: \(error.localizedDescription)", level: .error)
            }
        }
    }

    func restartEmulator() async {
        await stopEmulator()
        await startEmulator()
    }

    func refreshEmulatorState() async {
        guard let adbURL = sdkInfo.adbURL else {
            emulatorState = .unknown
            deviceInfo = .empty
            return
        }

        emulatorState = await emulatorService.state(adbURL: adbURL, adbService: adbService)

        if emulatorState == .running || emulatorState == .booting {
            deviceInfo = await adbService.deviceInfo(adbURL: adbURL)
            updateOfficialToolbarRepair()
        } else {
            deviceInfo = .empty
            officialToolbarRepairService.stop()
        }
    }

    func refreshGames() async {
        guard let adbURL = sdkInfo.adbURL else {
            logService.log("Cannot refresh games because ADB was not found.", level: .warning)
            refreshHealthChecks()
            return
        }

        do {
            let discovered = try await adbService.listInstalledUserApps(adbURL: adbURL, serial: deviceInfo.serial)
            games = gameLibraryService.merge(discoveredApps: discovered, cachedApps: games)
            statusMessage = "\(games.count) installed app\(games.count == 1 ? "" : "s") found"
        } catch {
            logService.log("Could not refresh installed games: \(error.localizedDescription)", level: .error)
        }

        refreshHealthChecks()
    }

    func completeSetupWizard() {
        settings.setupWizardCompleted = true
        saveSettings()
        refreshHealthChecks()
        logService.log("Setup Wizard completed. MacDroid is ready to launch Android games.", level: .success)
    }

    func reopenSetupWizard() {
        settings.setupWizardCompleted = false
        saveSettings()
        refreshHealthChecks()
    }

    func runSetupAutoFix() async {
        await runBusyTask("Running setup repair...") {
            await refreshSDK()

            if sdkInfo.canManageAVDs {
                await refreshAVDs()

                if !avdExists(named: avdManagerService.recommendedAVDName) {
                    await createRecommendedAVD()
                }
            }

            await refreshAll()
        }
    }

    func refreshHealthChecks() {
        healthCheckItems = healthCheckService.buildReport(
            sdkInfo: sdkInfo,
            avds: avds,
            emulatorState: emulatorState,
            deviceInfo: deviceInfo,
            games: games,
            settings: settings,
            gameProfiles: gameProfiles,
            updateInfo: updateInfo
        )
    }

    func checkForUpdates() async {
        updateInfo = await updateCheckerService.checkForUpdates()
        refreshHealthChecks()
    }

    func openLatestReleasePage() {
        guard let url = updateInfo.releaseURL ?? URL(string: "https://github.com/\(AppVersion.repositoryOwner)/\(AppVersion.repositoryName)/releases") else {
            return
        }

        NSWorkspace.shared.open(url)
    }

    func installAPK(from apkURL: URL) async {
        guard let adbURL = sdkInfo.adbURL else {
            logService.log("Cannot install APK because ADB was not found.", level: .error)
            return
        }

        await runBusyTask("Installing APK...") {
            do {
                let targetSerial = await adbService.preferredEmulatorSerial(
                    adbURL: adbURL,
                    preferredSerial: deviceInfo.serial
                )
                installProgress = 0.15
                let didInstall = try await apkInstallerService.install(
                    apkURL: apkURL,
                    adbURL: adbURL,
                    serial: targetSerial
                )
                installProgress = didInstall ? 1.0 : nil

                if didInstall {
                    await refreshGames()
                }
            } catch {
                logService.log("APK install failed: \(error.localizedDescription)", level: .error)
            }

            installProgress = nil
        }
    }

    func launch(_ app: AndroidApp) async {
        guard let adbURL = sdkInfo.adbURL else {
            logService.log("Cannot launch \(app.name) because ADB was not found.", level: .error)
            return
        }

        await runBusyTask("Launching \(app.name)...") {
            do {
                applyStoredGameProfileBeforeLaunch(for: app)

                if let profile = keyProfiles.first(where: { $0.packageName == app.packageName }) {
                    activeKeyMappingPackageName = app.packageName
                    keyMappingOverlayIsArmed = true
                    keyMappingOverlayMessage = "\(profile.name) is armed. Open the Key Mapping Overlay to use keyboard controls."
                    logService.log("Loaded key mapping profile for \(app.name). Open the overlay window to send mapped controls through ADB.", level: .info)
                }

                try await adbService.launch(
                    packageName: app.packageName,
                    adbURL: adbURL,
                    serial: deviceInfo.serial
                )

                if let gameProfile = gameProfiles.first(where: { $0.packageName == app.packageName }) {
                    await applyOrientationPreference(gameProfile.orientationPreference)
                }

                games = gameLibraryService.markPlayed(app, in: games)
            } catch {
                logService.log("Could not launch \(app.name): \(error.localizedDescription)", level: .error)
            }
        }
    }

    func toggleFavorite(_ app: AndroidApp) {
        games = gameLibraryService.toggleFavorite(app, in: games)
        logService.log(
            app.isFavorite ? "\(app.name) removed from favorites." : "\(app.name) added to favorites.",
            level: .info
        )
    }

    func openAppInfo(_ app: AndroidApp) async {
        guard let adbURL = sdkInfo.adbURL else {
            logService.log("Cannot open Android app info because ADB was not found.", level: .error)
            return
        }

        guard emulatorState == .running else {
            logService.log("Start the emulator before opening app info.", level: .warning)
            return
        }

        do {
            try await adbService.openAppInfo(
                packageName: app.packageName,
                adbURL: adbURL,
                serial: deviceInfo.serial
            )
        } catch {
            logService.log("Could not open app info for \(app.name): \(error.localizedDescription)", level: .error)
        }
    }

    func uninstall(_ app: AndroidApp) async {
        guard let adbURL = sdkInfo.adbURL else {
            logService.log("Cannot uninstall \(app.name) because ADB was not found.", level: .error)
            return
        }

        await runBusyTask("Uninstalling \(app.name)...") {
            do {
                try await adbService.uninstall(
                    packageName: app.packageName,
                    adbURL: adbURL,
                    serial: deviceInfo.serial
                )
                await refreshGames()
            } catch {
                logService.log("Could not uninstall \(app.name): \(error.localizedDescription)", level: .error)
            }
        }
    }

    func openPlayStore() async {
        guard sdkInfo.playStoreImageAvailable else {
            logService.log("Play Store needs a Google Play system image. Create or select a Google Play ARM64 AVD first.", level: .warning)
            return
        }

        guard let adbURL = sdkInfo.adbURL else {
            logService.log("Cannot open Play Store because ADB was not found.", level: .error)
            return
        }

        do {
            try await adbService.openPlayStore(adbURL: adbURL, serial: deviceInfo.serial)
        } catch {
            logService.log("Could not open Play Store: \(error.localizedDescription)", level: .error)
        }
    }

    func acceptSDKLicenses() async {
        guard let sdkManagerURL = sdkInfo.sdkManagerURL else {
            logService.log("Cannot accept licenses because SDK Manager was not found.", level: .error)
            return
        }

        await runBusyTask("Accepting SDK licenses...") {
            do {
                try await avdManagerService.acceptLicenses(sdkManagerURL: sdkManagerURL)
            } catch {
                logService.log("SDK license command failed: \(error.localizedDescription)", level: .error)
            }
        }
    }

    func captureScreenshot() async {
        guard let adbURL = sdkInfo.adbURL else {
            logService.log("Cannot capture a screenshot because ADB was not found.", level: .error)
            return
        }

        await runBusyTask("Capturing screenshot...") {
            do {
                latestScreenshotURL = try await adbService.captureScreenshot(
                    adbURL: adbURL,
                    serial: deviceInfo.serial
                )
            } catch {
                logService.log("Screenshot capture failed: \(error.localizedDescription)", level: .error)
            }
        }
    }

    func loadRecentLogcat() async {
        guard let adbURL = sdkInfo.adbURL else {
            logService.log("Cannot read logcat because ADB was not found.", level: .error)
            return
        }

        await runBusyTask("Loading logcat...") {
            do {
                recentLogcatText = try await adbService.recentLogcat(
                    adbURL: adbURL,
                    serial: deviceInfo.serial
                )
            } catch {
                logService.log("Logcat failed: \(error.localizedDescription)", level: .error)
            }
        }
    }

    func restartADBServer() async {
        guard let adbURL = sdkInfo.adbURL else {
            logService.log("Cannot restart ADB because adb was not found.", level: .error)
            return
        }

        await runBusyTask("Restarting ADB...") {
            do {
                try await adbService.restartServer(adbURL: adbURL)
                await refreshAll()
            } catch {
                logService.log("ADB restart failed: \(error.localizedDescription)", level: .error)
            }
        }
    }

    func rebootAndroid() async {
        guard let adbURL = sdkInfo.adbURL else {
            logService.log("Cannot reboot Android because adb was not found.", level: .error)
            return
        }

        await runBusyTask("Rebooting Android...") {
            do {
                try await adbService.rebootDevice(adbURL: adbURL, serial: deviceInfo.serial)
                emulatorState = .booting
                await waitForEmulatorBoot()
            } catch {
                logService.log("Android reboot failed: \(error.localizedDescription)", level: .error)
            }
        }
    }

    func repairAppRotation() async {
        guard let adbURL = sdkInfo.adbURL else {
            lastEmulatorControlMessage = "ADB not found"
            logService.log("Cannot repair app rotation because adb was not found.", level: .error)
            return
        }

        guard emulatorState == .running || emulatorState == .booting else {
            lastEmulatorControlMessage = "Emulator is not running"
            logService.log("Start the emulator before repairing app rotation.", level: .warning)
            return
        }

        await runBusyTask("Fixing app rotation...") {
            do {
                _ = try await adbService.repairAppRotation(
                    adbURL: adbURL,
                    serial: deviceInfo.serial
                )

                let rotatedTarget = try await adbService.setRotation(
                    emulatorRotation,
                    adbURL: adbURL,
                    serial: deviceInfo.serial
                )

                lastEmulatorControlMessage = "App rotation fixed on \(rotatedTarget)"
                logService.log("App rotation repair is active. If the open app is still sideways, press Rotate once or close and reopen the app.", level: .success)
            } catch {
                lastEmulatorControlMessage = "App rotation repair failed"
                logService.log("App rotation repair failed: \(error.localizedDescription)", level: .error)
            }
        }
    }

    func clearPlayStoreData() async {
        guard let adbURL = sdkInfo.adbURL else {
            logService.log("Cannot clear Play Store because adb was not found.", level: .error)
            return
        }

        guard emulatorState == .running else {
            logService.log("Start the emulator before clearing Play Store data.", level: .warning)
            return
        }

        await runBusyTask("Clearing Play Store...") {
            do {
                try await adbService.clearPlayStoreData(adbURL: adbURL, serial: deviceInfo.serial)
            } catch {
                logService.log("Play Store reset failed: \(error.localizedDescription)", level: .error)
            }
        }
    }

    func runNetworkDiagnostics() async {
        guard let adbURL = sdkInfo.adbURL else {
            logService.log("Cannot test emulator network because adb was not found.", level: .error)
            return
        }

        await runBusyTask("Testing emulator network...") {
            var output: [String] = []

            for host in ["8.8.8.8", "play.googleapis.com"] {
                do {
                    let result = try await adbService.ping(
                        host: host,
                        adbURL: adbURL,
                        serial: deviceInfo.serial
                    )
                    output.append("== \(host) ==\n\(result)")
                } catch {
                    output.append("== \(host) ==\n\(error.localizedDescription)")
                }
            }

            networkDiagnosticText = output.joined(separator: "\n\n")
        }
    }

    func sendAndroidNavigation(_ key: AndroidNavigationKey) async {
        guard let adbURL = sdkInfo.adbURL else {
            logService.log("Cannot send Android \(key.title) because ADB was not found.", level: .error)
            return
        }

        guard emulatorState == .running || emulatorState == .booting else {
            logService.log("Start the emulator before using Android navigation buttons.", level: .warning)
            return
        }

        do {
            let target = try await adbService.sendNavigationKey(
                key,
                adbURL: adbURL,
                serial: deviceInfo.serial
            )
            lastNavigationMessage = "\(key.title) sent to \(target)"
        } catch {
            lastNavigationMessage = "\(key.title) failed"
            logService.log("Android \(key.title) failed: \(error.localizedDescription)", level: .error)
        }
    }

    func sendEmulatorControl(_ action: EmulatorControlAction) async {
        guard let adbURL = sdkInfo.adbURL else {
            lastEmulatorControlMessage = "ADB not found"
            logService.log("Cannot send \(action.title) because ADB was not found.", level: .error)
            return
        }

        guard emulatorState == .running || emulatorState == .booting else {
            lastEmulatorControlMessage = "Emulator is not running"
            logService.log("Start the emulator before using \(action.title).", level: .warning)
            return
        }

        do {
            switch action {
            case .screenshot:
                await captureScreenshot()
                lastEmulatorControlMessage = latestScreenshotURL == nil ? "Screenshot failed" : "Screenshot saved"
            case .rotateLeft:
                emulatorRotation = (emulatorRotation + 3) % 4
                let target = try await adbService.setRotation(
                    emulatorRotation,
                    adbURL: adbURL,
                    serial: deviceInfo.serial
                )
                lastEmulatorControlMessage = "Rotate sent to \(target)"
            case .rotateRight:
                emulatorRotation = (emulatorRotation + 1) % 4
                let target = try await adbService.setRotation(
                    emulatorRotation,
                    adbURL: adbURL,
                    serial: deviceInfo.serial
                )
                lastEmulatorControlMessage = "Rotate sent to \(target)"
            case .back:
                await sendAndroidNavigation(.back)
                lastEmulatorControlMessage = lastNavigationMessage
            case .home:
                await sendAndroidNavigation(.home)
                lastEmulatorControlMessage = lastNavigationMessage
            case .recents:
                await sendAndroidNavigation(.recents)
                lastEmulatorControlMessage = lastNavigationMessage
            case .power, .volumeUp, .volumeDown:
                guard let keyCode = action.keyCode else {
                    return
                }

                let target = try await adbService.sendKeyEvent(
                    title: action.title,
                    keyCode: keyCode,
                    adbURL: adbURL,
                    serial: deviceInfo.serial
                )
                lastEmulatorControlMessage = "\(action.title) sent to \(target)"
            }
        } catch {
            lastEmulatorControlMessage = "\(action.title) failed"
            logService.log("\(action.title) failed: \(error.localizedDescription)", level: .error)
        }
    }

    func applyOrientationPreference(_ preference: GameOrientationPreference) async {
        guard preference != .system else {
            logService.log("Using system orientation. MacDroid did not change Android rotation.", level: .info)
            return
        }

        guard let adbURL = sdkInfo.adbURL else {
            lastEmulatorControlMessage = "ADB not found"
            logService.log("Cannot apply \(preference.rawValue) because ADB was not found.", level: .error)
            return
        }

        guard emulatorState == .running || emulatorState == .booting else {
            lastEmulatorControlMessage = "Emulator is not running"
            logService.log("Start the emulator before changing orientation.", level: .warning)
            return
        }

        do {
            let target: String

            switch preference {
            case .system:
                return
            case .reset:
                target = try await adbService.resetRotation(adbURL: adbURL, serial: deviceInfo.serial)
                emulatorRotation = 0
            case .forceLandscape:
                _ = try await adbService.repairAppRotation(adbURL: adbURL, serial: deviceInfo.serial)
                emulatorRotation = preference.adbRotation ?? 0
                target = try await adbService.setRotation(emulatorRotation, adbURL: adbURL, serial: deviceInfo.serial)
            case .landscape, .portrait:
                emulatorRotation = preference.adbRotation ?? emulatorRotation
                target = try await adbService.setRotation(emulatorRotation, adbURL: adbURL, serial: deviceInfo.serial)
            }

            lastEmulatorControlMessage = "\(preference.rawValue) applied to \(target)"
        } catch {
            lastEmulatorControlMessage = "\(preference.rawValue) failed"
            logService.log("Orientation change failed: \(error.localizedDescription)", level: .error)
        }
    }

    func saveSettings() {
        settingsService.saveSettings(settings)
        avdManagerService.apply(settings: settings, toAVDNamed: selectedAVDName)
        updateOfficialToolbarRepair()
        refreshHealthChecks()
    }

    func saveGameProfiles() {
        gameProfileService.saveProfiles(gameProfiles)
        refreshHealthChecks()
    }

    @discardableResult
    func ensureGameProfile(for app: AndroidApp) -> Int {
        if let index = gameProfiles.firstIndex(where: { $0.packageName == app.packageName }) {
            return index
        }

        let keyProfileIndex = ensureKeyMappingProfile(for: app)
        let profile = GameProfile.default(
            for: app,
            keyMappingProfileID: keyProfiles.indices.contains(keyProfileIndex) ? keyProfiles[keyProfileIndex].id : nil
        )
        gameProfiles.append(profile)
        saveGameProfiles()
        return gameProfiles.count - 1
    }

    func createRecommendedGameProfile(for app: AndroidApp) {
        let index = ensureGameProfile(for: app)
        gameProfiles[index].displayName = app.name
        gameProfiles[index].orientationPreference = .forceLandscape
        gameProfiles[index].performanceProfile = .performance
        gameProfiles[index].resolutionPreset = .p1080
        gameProfiles[index].dpiPreset = .dpi320
        gameProfiles[index].autoOpenKeyMappingOverlay = true
        gameProfiles[index].updatedAt = .now
        createDefaultProfile(for: app)
        saveGameProfiles()
    }

    private func applyStoredGameProfileBeforeLaunch(for app: AndroidApp) {
        guard let gameProfile = gameProfiles.first(where: { $0.packageName == app.packageName }) else {
            return
        }

        settings.performanceProfile = gameProfile.performanceProfile
        settings.resolutionPreset = gameProfile.resolutionPreset
        settings.dpiPreset = gameProfile.dpiPreset

        if gameProfile.autoOpenKeyMappingOverlay {
            activeKeyMappingPackageName = app.packageName
            keyMappingOverlayIsArmed = true
        }

        logService.log("Loaded game profile for \(app.name). Display and resource changes apply fully after the next emulator restart.", level: .info)
    }

    func applyPerformanceProfile(_ profile: PerformanceProfile) {
        settings.performanceProfile = profile

        switch profile {
        case .balanced:
            settings.ramPreset = .gb4
            settings.cpuPreset = .four
            settings.resolutionPreset = .p1080
            settings.dpiPreset = .dpi320
            settings.fpsTarget = .fps60
            settings.performanceModeEnabled = true
            settings.batterySavingEnabled = false
        case .performance:
            settings.ramPreset = .gb6
            settings.cpuPreset = .six
            settings.resolutionPreset = .p1080
            settings.dpiPreset = .dpi320
            settings.fpsTarget = .fps90
            settings.performanceModeEnabled = true
            settings.batterySavingEnabled = false
        case .batterySaver:
            settings.ramPreset = .gb2
            settings.cpuPreset = .two
            settings.resolutionPreset = .p720
            settings.dpiPreset = .dpi240
            settings.fpsTarget = .fps30
            settings.performanceModeEnabled = false
            settings.batterySavingEnabled = true
        case .custom:
            break
        }

        saveSettings()
        logService.log("\(profile.rawValue) performance profile applied.", level: .success)
    }

    private func updateOfficialToolbarRepair() {
        guard settings.repairOfficialEmulatorToolbar,
              !settings.hideOfficialEmulatorToolbar,
              emulatorState == .running || emulatorState == .booting else {
            officialToolbarRepairService.stop()
            return
        }

        officialToolbarRepairService.start { [weak self] action in
            Task { @MainActor in
                await self?.sendEmulatorControl(action)
            }
        }
    }

    func saveKeyProfiles() {
        if let activeKeyMappingPackageName,
           !keyProfiles.contains(where: { $0.packageName == activeKeyMappingPackageName }) {
            self.activeKeyMappingPackageName = nil
            keyMappingOverlayIsArmed = false
        }

        keyMappingService.saveProfiles(keyProfiles)
    }

    @discardableResult
    func ensureKeyMappingProfile(for app: AndroidApp) -> Int {
        if let index = keyProfiles.firstIndex(where: { $0.packageName == app.packageName }) {
            return index
        }

        let profile = KeyMappingProfile.empty(for: app)
        keyProfiles.append(profile)
        saveKeyProfiles()
        return keyProfiles.count - 1
    }

    func createDefaultProfile(for app: AndroidApp) {
        let profileIndex = ensureKeyMappingProfile(for: app)

        keyProfiles[profileIndex].mappings = [
            .sample(trigger: "W", x: 0.50, y: 0.35),
            .sample(trigger: "A", x: 0.38, y: 0.55),
            .sample(trigger: "S", x: 0.50, y: 0.65),
            .sample(trigger: "D", x: 0.62, y: 0.55),
            InputMapping(
                inputType: .keyboard,
                trigger: "Space",
                action: .tap,
                tapPoint: NormalizedPoint(x: 0.80, y: 0.72),
                note: "Jump / main action"
            ),
            InputMapping(
                inputType: .mouse,
                trigger: "Left Click",
                action: .tap,
                tapPoint: NormalizedPoint(x: 0.86, y: 0.58),
                note: "Fire / primary action"
            )
        ]
        keyProfiles[profileIndex].inputBridgeMode = .liveOverlay
        keyProfiles[profileIndex].updatedAt = .now
        activateKeyMapping(for: app)
        saveKeyProfiles()
    }

    func createShooterProfile(for app: AndroidApp) {
        let profileIndex = ensureKeyMappingProfile(for: app)

        keyProfiles[profileIndex].mappings = [
            .sample(trigger: "W", x: 0.18, y: 0.62),
            .sample(trigger: "A", x: 0.10, y: 0.72),
            .sample(trigger: "S", x: 0.18, y: 0.82),
            .sample(trigger: "D", x: 0.26, y: 0.72),
            InputMapping(inputType: .mouse, trigger: "Left Click", action: .tap, tapPoint: NormalizedPoint(x: 0.86, y: 0.54), note: "Fire"),
            InputMapping(inputType: .keyboard, trigger: "Space", action: .tap, tapPoint: NormalizedPoint(x: 0.76, y: 0.78), note: "Jump"),
            InputMapping(inputType: .keyboard, trigger: "R", action: .tap, tapPoint: NormalizedPoint(x: 0.70, y: 0.82), note: "Reload"),
            InputMapping(inputType: .keyboard, trigger: "Shift", action: .longPress, tapPoint: NormalizedPoint(x: 0.32, y: 0.84), durationMilliseconds: 650, note: "Sprint")
        ]
        keyProfiles[profileIndex].inputBridgeMode = .liveOverlay
        keyProfiles[profileIndex].updatedAt = .now
        saveKeyProfiles()
    }

    func createMOBAMappingProfile(for app: AndroidApp) {
        let profileIndex = ensureKeyMappingProfile(for: app)

        keyProfiles[profileIndex].mappings = [
            .sample(trigger: "W", x: 0.18, y: 0.62),
            .sample(trigger: "A", x: 0.10, y: 0.72),
            .sample(trigger: "S", x: 0.18, y: 0.82),
            .sample(trigger: "D", x: 0.26, y: 0.72),
            InputMapping(inputType: .keyboard, trigger: "Q", action: .tap, tapPoint: NormalizedPoint(x: 0.68, y: 0.80), note: "Skill 1"),
            InputMapping(inputType: .keyboard, trigger: "E", action: .tap, tapPoint: NormalizedPoint(x: 0.78, y: 0.72), note: "Skill 2"),
            InputMapping(inputType: .keyboard, trigger: "R", action: .tap, tapPoint: NormalizedPoint(x: 0.88, y: 0.64), note: "Ultimate"),
            InputMapping(inputType: .mouse, trigger: "Left Click", action: .tap, tapPoint: NormalizedPoint(x: 0.90, y: 0.82), note: "Basic attack")
        ]
        keyProfiles[profileIndex].inputBridgeMode = .liveOverlay
        keyProfiles[profileIndex].updatedAt = .now
        saveKeyProfiles()
    }

    func exportKeyProfiles() {
        _ = keyMappingService.exportProfiles(keyProfiles)
    }

    func activateKeyMapping(for app: AndroidApp) {
        let profileIndex = ensureKeyMappingProfile(for: app)
        keyProfiles[profileIndex].inputBridgeMode = .liveOverlay
        keyProfiles[profileIndex].updatedAt = .now
        activeKeyMappingPackageName = app.packageName
        keyMappingOverlayIsArmed = true
        keyMappingOverlayMessage = "\(app.name) controls are active."
        logService.log("Key mapping overlay armed for \(app.name). Keep the overlay focused while playing.", level: .success)
        saveKeyProfiles()
    }

    func stopKeyMappingOverlay() {
        keyMappingOverlayIsArmed = false
        keyMappingOverlayMessage = "Key mapping overlay paused."
        logService.log("Key mapping overlay paused.", level: .info)
    }

    func testMapping(_ mapping: InputMapping) async {
        guard let adbURL = sdkInfo.adbURL else {
            logService.log("Cannot test key mapping because ADB was not found.", level: .error)
            return
        }

        guard emulatorState == .running else {
            logService.log("Start the emulator before testing a key mapping.", level: .warning)
            return
        }

        do {
            try await inputMappingExecutionService.send(
                mapping: mapping,
                fallbackResolution: settings.resolutionPreset,
                adbURL: adbURL,
                serial: await adbService.preferredEmulatorSerial(
                    adbURL: adbURL,
                    preferredSerial: deviceInfo.serial
                )
            )
        } catch {
            logService.log("Key mapping test failed: \(error.localizedDescription)", level: .error)
        }
    }

    func runKeyMappingTrigger(_ trigger: String) async {
        guard keyMappingOverlayIsArmed else {
            keyMappingOverlayMessage = "Overlay is paused."
            return
        }

        guard let activeKeyMappingPackageName,
              let profile = keyProfiles.first(where: { $0.packageName == activeKeyMappingPackageName }) else {
            keyMappingOverlayMessage = "No active profile."
            return
        }

        guard let mapping = profile.mappings.first(where: { mapping in
            mapping.isEnabled && normalizedTrigger(mapping.trigger) == normalizedTrigger(trigger)
        }) else {
            keyMappingOverlayMessage = "No mapping for \(trigger)."
            return
        }

        await runKeyMapping(mapping, source: trigger)
    }

    func runOverlayMouseTap(at point: NormalizedPoint) async {
        guard keyMappingOverlayIsArmed else {
            keyMappingOverlayMessage = "Overlay is paused."
            return
        }

        if let activeKeyMappingPackageName,
           let profile = keyProfiles.first(where: { $0.packageName == activeKeyMappingPackageName }),
           let clickMapping = profile.mappings.first(where: { mapping in
               mapping.isEnabled && normalizedTrigger(mapping.trigger) == normalizedTrigger("Left Click")
           }) {
            await runKeyMapping(clickMapping, source: "Left Click")
            return
        }

        guard let adbURL = sdkInfo.adbURL else {
            keyMappingOverlayMessage = "ADB not found."
            logService.log("Cannot send overlay mouse tap because ADB was not found.", level: .error)
            return
        }

        guard emulatorState == .running else {
            keyMappingOverlayMessage = "Start emulator first."
            logService.log("Start the emulator before using the key mapping overlay.", level: .warning)
            return
        }

        do {
            try await inputMappingExecutionService.sendDirectTap(
                at: point,
                fallbackResolution: settings.resolutionPreset,
                adbURL: adbURL,
                serial: await adbService.preferredEmulatorSerial(
                    adbURL: adbURL,
                    preferredSerial: deviceInfo.serial
                )
            )
            keyMappingOverlayMessage = "Overlay tap sent."
        } catch {
            keyMappingOverlayMessage = "Overlay tap failed."
            logService.log("Overlay tap failed: \(error.localizedDescription)", level: .error)
        }
    }

    private func runKeyMapping(_ mapping: InputMapping, source: String) async {
        guard let adbURL = sdkInfo.adbURL else {
            keyMappingOverlayMessage = "ADB not found."
            logService.log("Cannot run \(source) because ADB was not found.", level: .error)
            return
        }

        guard emulatorState == .running else {
            keyMappingOverlayMessage = "Start emulator first."
            logService.log("Start the emulator before using key mapping.", level: .warning)
            return
        }

        do {
            try await inputMappingExecutionService.send(
                mapping: mapping,
                fallbackResolution: settings.resolutionPreset,
                adbURL: adbURL,
                serial: await adbService.preferredEmulatorSerial(
                    adbURL: adbURL,
                    preferredSerial: deviceInfo.serial
                )
            )
            keyMappingOverlayMessage = "\(source) sent."
        } catch {
            keyMappingOverlayMessage = "\(source) failed."
            logService.log("Key mapping \(source) failed: \(error.localizedDescription)", level: .error)
        }
    }

    private func normalizedTrigger(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    }

    private func runBusyTask(_ message: String, operation: () async -> Void) async {
        isBusy = true
        statusMessage = message
        await operation()
        isBusy = false
    }

    private func startFromAppIconIfNeeded() async {
        guard settings.launchEmulatorWhenAppOpens else {
            logService.log("Auto-start is off. The emulator will wait for the Play button or emulator icon.", level: .info)
            return
        }

        guard !hasHandledIconLaunch else {
            return
        }

        hasHandledIconLaunch = true
        logService.log("Auto-start is on, so opening the app icon will start the selected emulator.", level: .info)
        await launchFromEmulatorIcon()
    }

    private func ensureRecommendedAVDIfNeeded() async {
        let avdName = selectedAVDName.isEmpty ? avdManagerService.recommendedAVDName : selectedAVDName

        if avdExists(named: avdName) {
            return
        }

        guard sdkInfo.canManageAVDs else {
            logService.log("No launchable AVD was found, and AVD Manager is missing.", level: .warning)
            return
        }

        logService.log("No launchable AVD was found, so MacDroid will create the recommended gaming AVD before starting.", level: .info)
        await createRecommendedAVD()
    }

    private func avdExists(named avdName: String) -> Bool {
        if avds.contains(where: { $0.name == avdName }) {
            return true
        }

        let configURL = FileManager.default
            .homeDirectoryForCurrentUser
            .appendingPathComponent(".android/avd/\(avdName).avd/config.ini")

        return FileManager.default.fileExists(atPath: configURL.path)
    }

    private func waitForEmulatorBoot() async {
        guard let adbURL = sdkInfo.adbURL else {
            return
        }

        do {
            try await adbService.waitForDevice(adbURL: adbURL)
        } catch {
            logService.log("ADB did not see the emulator yet: \(error.localizedDescription)", level: .warning)
        }

        for attempt in 1...45 {
            statusMessage = "Booting Android... \(attempt)/45"

            if await adbService.bootCompleted(adbURL: adbURL, serial: deviceInfo.serial) {
                emulatorState = .running
                deviceInfo = await adbService.deviceInfo(adbURL: adbURL)
                logService.log("Android finished booting and is ready for games.", level: .success)
                await refreshGames()
                await autoLaunchLastGameIfNeeded()
                return
            }

            try? await Task.sleep(nanoseconds: 2_000_000_000)
        }

        emulatorState = .booting
        logService.log("The emulator started, but Android is still booting. Refresh status in a moment.", level: .warning)
    }

    private func autoLaunchLastGameIfNeeded() async {
        guard settings.autoLaunchLastGameAfterBoot,
              let game = games
                .filter({ $0.lastPlayed != nil })
                .sorted(by: { ($0.lastPlayed ?? .distantPast) > ($1.lastPlayed ?? .distantPast) })
                .first else {
            return
        }

        logService.log("Auto-launching last played game: \(game.name).", level: .info)
        await launch(game)
    }
}
