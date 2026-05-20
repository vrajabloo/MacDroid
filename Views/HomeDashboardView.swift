//
// HomeDashboardView.swift
// MacDroid
//
// Main landing dashboard. It shows the emulator state, the large Play action,
// recent games, SDK readiness, and quick setup controls.

import SwiftUI

struct HomeDashboardView: View {
    @EnvironmentObject private var app: AppEnvironment
    @Environment(\.openWindow) private var openWindow
    @StateObject private var viewModel = HomeViewModel()

    private var recentGames: [AndroidApp] {
        viewModel.recentGames(from: app.games)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                hero
                metrics

                HStack(alignment: .top, spacing: 18) {
                    recentGamesPanel
                    devicePanel
                }

                HStack(alignment: .top, spacing: 18) {
                    avdPanel
                    APKDropZone()
                }
            }
            .padding(28)
        }
    }

    private var hero: some View {
        PanelView(padding: 24) {
            HStack(alignment: .center, spacing: 26) {
                VStack(alignment: .leading, spacing: 14) {
                    StatusBadge(title: app.emulatorState.title, color: app.emulatorState.color)

                    Text("MacDroid")
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundStyle(.white)

                    Text("A gaming-focused macOS wrapper around the official Google Android Emulator.")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack(spacing: 12) {
                        Button {
                            Task { await primaryAction() }
                        } label: {
                            Label(viewModel.primaryActionTitle(for: app.emulatorState), systemImage: "play.fill")
                                .font(.title3.weight(.bold))
                                .frame(minWidth: 190, minHeight: 54)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color(hex: 0x1EEA8A))
                        .disabled(app.isBusy || app.emulatorState == .booting)

                        Button {
                            Task { await app.stopEmulator() }
                        } label: {
                            Label("Stop", systemImage: "stop.fill")
                                .frame(minHeight: 42)
                        }
                        .disabled(app.emulatorState == .stopped || app.isBusy)

                        Button {
                            Task { await app.refreshAll() }
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .frame(width: 34, height: 34)
                        }
                        .help("Refresh SDK, emulator, and game library")

                        Button {
                            openWindow(id: "emulator-controls")
                        } label: {
                            Label("Controls", systemImage: "rectangle.on.rectangle.circle")
                                .frame(minHeight: 42)
                        }
                        .help("Open the single MacDroid emulator controls toolbar")
                    }
                }

                VStack(spacing: 16) {
                    emulatorLaunchIcon

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "cpu.fill")
                                .foregroundStyle(Color(hex: 0x1EEA8A))
                            Text("Gaming profile")
                                .font(.headline)
                        }

                        settingLine("RAM", app.settings.ramPreset.rawValue)
                        settingLine("CPU", app.settings.cpuPreset.rawValue)
                        settingLine("Resolution", app.settings.resolutionPreset.rawValue)
                        settingLine("DPI", app.settings.dpiPreset.rawValue)
                        settingLine("Target", app.settings.fpsTarget.rawValue)
                    }
                    .frame(width: 260)
                }
            }
        }
    }

    private var emulatorLaunchIcon: some View {
        Button {
            Task { await app.launchFromEmulatorIcon() }
        } label: {
            VStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: 0x1EEA8A), Color(hex: 0x00C2FF)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color(hex: 0x1EEA8A, opacity: 0.28), radius: 18, y: 8)

                    Image(systemName: app.emulatorState == .running ? "play.circle.fill" : "gamecontroller.fill")
                        .font(.system(size: 54, weight: .black))
                        .foregroundStyle(Color.black.opacity(0.82))
                }
                .frame(width: 132, height: 132)

                Text(app.emulatorState == .running ? "Emulator Ready" : "Launch Emulator")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(.white)

                Text("Click icon to start")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 260)
        }
        .buttonStyle(.plain)
        .disabled(app.isBusy || app.emulatorState == .booting)
        .help("Start the selected Android emulator")
    }

    private var metrics: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 14), count: 4), spacing: 14) {
            MetricCard(title: "Installed apps", value: "\(app.games.count)", systemImage: "square.grid.2x2.fill", color: Color(hex: 0x1EEA8A))
            MetricCard(title: "Available AVDs", value: "\(app.avds.count)", systemImage: "iphone.gen3", color: Color(hex: 0x00C2FF))
            MetricCard(title: "ADB", value: app.sdkInfo.hasADB ? "Ready" : "Missing", systemImage: "terminal.fill", color: app.sdkInfo.hasADB ? Color(hex: 0x1EEA8A) : Color(hex: 0xFFD166))
            MetricCard(title: "Play Store", value: app.sdkInfo.playStoreImageAvailable ? "Ready" : "Check", systemImage: "play.square.fill", color: app.sdkInfo.playStoreImageAvailable ? Color(hex: 0x1EEA8A) : Color(hex: 0xFFD166))
        }
    }

    private var recentGamesPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Recent games")
                    .font(.title3.weight(.bold))
                Spacer()
                Button("Refresh") {
                    Task { await app.refreshGames() }
                }
            }

            if recentGames.isEmpty {
                PanelView {
                    EmptyStateView(
                        systemImage: "gamecontroller",
                        title: "No recent games yet",
                        message: "Install an APK or refresh the library after your emulator boots."
                    )
                    .frame(maxWidth: .infinity, minHeight: 180)
                }
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                    ForEach(recentGames) { game in
                        GameCardView(
                            app: game,
                            onPlay: { Task { await app.launch(game) } },
                            onUninstall: { Task { await app.uninstall(game) } },
                            onCreateProfile: { app.createDefaultProfile(for: game) },
                            onToggleFavorite: { app.toggleFavorite(game) },
                            onOpenAppInfo: { Task { await app.openAppInfo(game) } }
                        )
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var devicePanel: some View {
        PanelView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Device detection")
                    .font(.title3.weight(.bold))

                if app.deviceInfo.serial != nil {
                    VStack(alignment: .leading, spacing: 8) {
                        Label(app.deviceInfo.title, systemImage: "iphone.gen3")
                            .font(.headline)
                        deviceLine("Android", app.deviceInfo.androidVersion)
                        deviceLine("API", app.deviceInfo.apiLevel)
                        deviceLine("ABI", app.deviceInfo.abi)
                        deviceLine("Serial", app.deviceInfo.serial)
                    }
                    .padding(.bottom, 4)
                }

                ForEach(app.sdkInfo.detectedMessages, id: \.self) { message in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: message.localizedCaseInsensitiveContains("not") ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                            .foregroundStyle(message.localizedCaseInsensitiveContains("not") ? Color(hex: 0xFFD166) : Color(hex: 0x1EEA8A))
                        Text(message)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Button {
                    Task { await app.refreshAll() }
                } label: {
                    Label("Scan Again", systemImage: "magnifyingglass")
                }

                HStack {
                    Button {
                        Task { await app.captureScreenshot() }
                    } label: {
                        Label("Screenshot", systemImage: "camera.fill")
                    }
                    .disabled(app.emulatorState != .running)

                    Button {
                        Task { await app.loadRecentLogcat() }
                    } label: {
                        Label("Logcat", systemImage: "doc.text.magnifyingglass")
                    }
                    .disabled(app.emulatorState == .stopped || app.emulatorState == .unknown)
                }

                if let latestScreenshotURL = app.latestScreenshotURL {
                    Text("Latest screenshot: \(latestScreenshotURL.lastPathComponent)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .help(latestScreenshotURL.path)
                }
            }
        }
        .frame(width: 390)
    }

    private var avdPanel: some View {
        PanelView {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Emulator")
                        .font(.title3.weight(.bold))
                    Spacer()
                    StatusBadge(title: app.emulatorState.title, color: app.emulatorState.color)
                }

                Picker("Selected AVD", selection: $app.selectedAVDName) {
                    if app.avds.isEmpty {
                        Text("MacDroid").tag(app.avdManagerService.recommendedAVDName)
                    } else {
                        ForEach(app.avds) { avd in
                            Text(avd.name).tag(avd.name)
                        }
                    }
                }

                HStack {
                    Button {
                        Task { await app.createRecommendedAVD() }
                    } label: {
                        Label("Create Gaming AVD", systemImage: "plus.circle.fill")
                    }
                    .disabled(!app.sdkInfo.canManageAVDs || app.isBusy)

                    Button {
                        Task { await app.openPlayStore() }
                    } label: {
                        Label("Play Store", systemImage: "play.square.fill")
                    }
                    .disabled(app.emulatorState != .running)
                }

                Button {
                    openWindow(id: "emulator-controls")
                } label: {
                    Label("Open Emulator Controls", systemImage: "rectangle.on.rectangle.circle")
                }
                .disabled(app.emulatorState == .stopped || app.emulatorState == .unknown)

                Text("Uses ARM64 Google Play system images when available. If Play Store support is missing, install a Google Play ARM64 image through Android Studio's SDK Manager.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func primaryAction() async {
        if app.emulatorState == .running {
            if let game = recentGames.first ?? app.games.first {
                await app.launch(game)
            } else {
                await app.refreshGames()
            }
        } else {
            await app.launchFromEmulatorIcon()
        }
    }

    private func settingLine(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
        .font(.callout)
    }

    private func deviceLine(_ title: String, _ value: String?) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value?.isEmpty == false ? value! : "Unknown")
                .fontWeight(.semibold)
                .lineLimit(1)
        }
        .font(.caption)
    }
}
