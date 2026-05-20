//
// SettingsView.swift
// MacDroid
//
// Performance preferences for the recommended gaming AVD. The app writes
// supported settings into the AVD config file before launching the emulator.

import AppKit
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var app: AppEnvironment
    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 18) {
                    sdkPanel
                    performancePanel
                    displayPanel
                    networkPanel
                    modesPanel
                    avdPanel
                }
            }
            .padding(28)
        }
        .onChange(of: app.settings) { _, _ in
            viewModel.markChanged()
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Gaming Settings")
                    .font(.largeTitle.weight(.black))
                Text("Tune the official emulator for Android games on Apple Silicon.")
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                app.saveSettings()
                viewModel.markSaved()
            } label: {
                Label(viewModel.hasUnsavedChanges ? "Save Changes" : "Saved", systemImage: "checkmark.circle.fill")
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(hex: 0x1EEA8A))
        }
    }

    private var performancePanel: some View {
        PanelView {
            VStack(alignment: .leading, spacing: 16) {
                Label("Performance", systemImage: "speedometer")
                    .font(.title3.weight(.bold))

                Picker("Profile", selection: performanceProfileBinding) {
                    ForEach(PerformanceProfile.allCases) { profile in
                        Label(profile.rawValue, systemImage: profile.systemImage).tag(profile)
                    }
                }

                Picker("RAM", selection: $app.settings.ramPreset) {
                    ForEach(RAMPreset.allCases) { preset in
                        Text(preset.rawValue).tag(preset)
                    }
                }

                Picker("CPU cores", selection: $app.settings.cpuPreset) {
                    ForEach(CPUPreset.allCases) { preset in
                        Text(preset.rawValue).tag(preset)
                    }
                }

                Picker("FPS target", selection: $app.settings.fpsTarget) {
                    ForEach(FPSTarget.allCases) { preset in
                        Text(preset.rawValue).tag(preset)
                    }
                }

                Text("FPS depends on emulator and game support. MacDroid stores the preference now so later builds can apply supported flags or overlays.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var networkPanel: some View {
        PanelView {
            VStack(alignment: .leading, spacing: 16) {
                Label("Network Boost", systemImage: "wifi.router.fill")
                    .font(.title3.weight(.bold))

                Toggle("Use direct emulator DNS", isOn: $app.settings.networkBoostEnabled)

                Picker("DNS", selection: $app.settings.dnsPreset) {
                    ForEach(DNSPreset.allCases) { preset in
                        Text(preset.rawValue).tag(preset)
                    }
                }
                .disabled(!app.settings.networkBoostEnabled)

                Text("Network Boost launches the official emulator with `-dns-server \(app.settings.dnsPreset.servers)`. Restart the emulator after saving to apply it.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var sdkPanel: some View {
        PanelView {
            VStack(alignment: .leading, spacing: 16) {
                Label("Android SDK", systemImage: "shippingbox.fill")
                    .font(.title3.weight(.bold))

                TextField("Use auto-detection", text: sdkPathBinding)
                    .textFieldStyle(.roundedBorder)

                HStack {
                    Button {
                        chooseSDKFolder()
                    } label: {
                        Label("Browse", systemImage: "folder.fill")
                    }

                    Button {
                        app.settings.customSDKRootPath = nil
                        app.saveSettings()
                        Task { await app.refreshAll() }
                    } label: {
                        Label("Auto Detect", systemImage: "wand.and.stars")
                    }

                    Button {
                        Task { await app.acceptSDKLicenses() }
                    } label: {
                        Label("Accept Licenses", systemImage: "checkmark.seal.fill")
                    }
                    .disabled(!app.sdkInfo.canInstallSystemImages)
                }

                Text("Current SDK: \(app.sdkInfo.sdkRoot?.path ?? "Not detected")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var displayPanel: some View {
        PanelView {
            VStack(alignment: .leading, spacing: 16) {
                Label("Display", systemImage: "display")
                    .font(.title3.weight(.bold))

                Picker("Resolution", selection: $app.settings.resolutionPreset) {
                    ForEach(ResolutionPreset.allCases) { preset in
                        Text(preset.rawValue).tag(preset)
                    }
                }

                Picker("DPI", selection: $app.settings.dpiPreset) {
                    ForEach(DPIPreset.allCases) { preset in
                        Text(preset.rawValue).tag(preset)
                    }
                }

                Picker("Window size", selection: $app.settings.windowSizePreset) {
                    ForEach(WindowSizePreset.allCases) { preset in
                        Text(preset.rawValue).tag(preset)
                    }
                }

                Toggle("Keep official Google Emulator toolbar visible", isOn: officialToolbarVisibleBinding)

                Toggle("Repair official toolbar buttons", isOn: $app.settings.repairOfficialEmulatorToolbar)
                    .disabled(app.settings.hideOfficialEmulatorToolbar)

                Toggle("Fullscreen mode preference", isOn: $app.settings.fullscreenEnabled)

                Text("Toolbar repair keeps Google's toolbar on screen, but captures its common buttons and sends reliable ADB actions for Back, Home, Recents, volume, rotation, screenshot, and power.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var modesPanel: some View {
        PanelView {
            VStack(alignment: .leading, spacing: 16) {
                Label("Modes", systemImage: "bolt.fill")
                    .font(.title3.weight(.bold))

                Toggle("Performance mode", isOn: $app.settings.performanceModeEnabled)
                Toggle("Battery-saving mode", isOn: $app.settings.batterySavingEnabled)
                Toggle("Start emulator when app opens", isOn: $app.settings.launchEmulatorWhenAppOpens)
                Toggle("Auto-launch last game after boot", isOn: $app.settings.autoLaunchLastGameAfterBoot)

                Text("Performance mode prefers GPU host rendering and higher AVD resources. Battery-saving mode is stored for future throttling support.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var avdPanel: some View {
        PanelView {
            VStack(alignment: .leading, spacing: 16) {
                Label("Selected AVD", systemImage: "iphone.gen3")
                    .font(.title3.weight(.bold))

                Picker("AVD", selection: $app.selectedAVDName) {
                    if app.avds.isEmpty {
                        Text(app.avdManagerService.recommendedAVDName).tag(app.avdManagerService.recommendedAVDName)
                    } else {
                        ForEach(app.avds) { avd in
                            Text(avd.name).tag(avd.name)
                        }
                    }
                }

                Button {
                    Task { await app.createRecommendedAVD() }
                } label: {
                    Label("Create Recommended Gaming AVD", systemImage: "plus.circle.fill")
                }
                .disabled(!app.sdkInfo.canManageAVDs || app.isBusy)

                Text("Recommended image: \(app.avdManagerService.recommendedSystemImage)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var sdkPathBinding: Binding<String> {
        Binding(
            get: { app.settings.customSDKRootPath ?? "" },
            set: { newValue in
                app.settings.customSDKRootPath = newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : newValue
            }
        )
    }

    private var performanceProfileBinding: Binding<PerformanceProfile> {
        Binding(
            get: { app.settings.performanceProfile },
            set: { profile in
                app.applyPerformanceProfile(profile)
                viewModel.markChanged()
            }
        )
    }

    private var officialToolbarVisibleBinding: Binding<Bool> {
        Binding(
            get: { !app.settings.hideOfficialEmulatorToolbar },
            set: { isVisible in
                app.settings.hideOfficialEmulatorToolbar = !isVisible
            }
        )
    }

    private func chooseSDKFolder() {
        let panel = NSOpenPanel()
        panel.title = "Choose Android SDK Folder"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Use SDK"

        if panel.runModal() == .OK, let url = panel.url {
            app.settings.customSDKRootPath = url.path
            app.saveSettings()
            Task { await app.refreshAll() }
        }
    }
}
