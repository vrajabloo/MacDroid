//
// BoostView.swift
// MacDroid
//
// Beginner-friendly repair center for the problems users hit most often:
// slow Play Store downloads, stale ADB state, boot issues, and network latency.

import SwiftUI

struct BoostView: View {
    @EnvironmentObject private var app: AppEnvironment

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header

                LazyVGrid(columns: adaptiveColumns, spacing: 18) {
                    networkCard
                    repairCard
                    playStoreCard
                    diagnosticsCard
                }
            }
            .padding(28)
            .frame(maxWidth: 1080, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Boost & Repair")
                    .font(.largeTitle.weight(.black))
                Text("Fast fixes for Play Store, ADB, network, and emulator startup problems.")
                    .foregroundStyle(.secondary)
            }

            Spacer()

            StatusBadge(title: app.emulatorState.title, color: app.emulatorState.color)
        }
    }

    private var networkCard: some View {
        PanelView {
            VStack(alignment: .leading, spacing: 16) {
                Label("Network Boost", systemImage: "wifi.router.fill")
                    .font(.title3.weight(.bold))

                Toggle("Direct DNS on next launch", isOn: $app.settings.networkBoostEnabled)

                Picker("DNS preset", selection: $app.settings.dnsPreset) {
                    ForEach(DNSPreset.allCases) { preset in
                        Text(preset.rawValue).tag(preset)
                    }
                }
                .disabled(!app.settings.networkBoostEnabled)

                HStack {
                    Button {
                        app.saveSettings()
                    } label: {
                        Label("Save", systemImage: "checkmark.circle.fill")
                    }

                    Button {
                        Task { await app.restartEmulator() }
                    } label: {
                        Label("Restart Emulator", systemImage: "arrow.triangle.2.circlepath")
                    }
                    .disabled(app.emulatorState == .stopped || app.isBusy)
                }

                Text("Current DNS flag: \(app.settings.networkBoostEnabled ? app.settings.dnsPreset.servers : "system default")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
        }
    }

    private var repairCard: some View {
        PanelView {
            VStack(alignment: .leading, spacing: 16) {
                Label("Quick Repair", systemImage: "cross.case.fill")
                    .font(.title3.weight(.bold))

                Button {
                    Task { await app.restartADBServer() }
                } label: {
                    Label("Restart ADB", systemImage: "terminal.fill")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .disabled(!app.sdkInfo.hasADB || app.isBusy)

                Button {
                    Task { await app.rebootAndroid() }
                } label: {
                    Label("Reboot Android", systemImage: "power.circle.fill")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .disabled(app.emulatorState != .running || app.isBusy)

                Button {
                    Task { await app.refreshAll() }
                } label: {
                    Label("Rescan Environment", systemImage: "magnifyingglass")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private var playStoreCard: some View {
        PanelView {
            VStack(alignment: .leading, spacing: 16) {
                Label("Play Store Fixes", systemImage: "play.square.fill")
                    .font(.title3.weight(.bold))

                Button {
                    Task { await app.clearPlayStoreData() }
                } label: {
                    Label("Clear Play Store State", systemImage: "trash.circle.fill")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .disabled(app.emulatorState != .running || app.isBusy)

                Button {
                    Task { await app.openPlayStore() }
                } label: {
                    Label("Open Play Store", systemImage: "arrow.up.right.square.fill")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .disabled(app.emulatorState != .running)

                Text("Clearing Play Store state can fix stuck downloads, but Android may ask you to accept Play Store setup again.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private var diagnosticsCard: some View {
        PanelView {
            VStack(alignment: .leading, spacing: 16) {
                Label("Network Diagnostics", systemImage: "waveform.path.ecg")
                    .font(.title3.weight(.bold))

                Button {
                    Task { await app.runNetworkDiagnostics() }
                } label: {
                    Label("Run Ping Test", systemImage: "dot.radiowaves.left.and.right")
                }
                .disabled(app.emulatorState == .stopped || app.isBusy)

                if app.networkDiagnosticText.isEmpty {
                    Text("Run a ping test to compare basic emulator latency against Google Play endpoints.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    ScrollView {
                        Text(app.networkDiagnosticText)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(minHeight: 180)
                }
            }
        }
    }

    private var adaptiveColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 340, maximum: 520), spacing: 18, alignment: .top)]
    }
}
