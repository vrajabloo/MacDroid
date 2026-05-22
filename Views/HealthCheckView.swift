//
// HealthCheckView.swift
// MacDroid
//
// Shows a beginner-friendly health report for SDK tools, emulator state, Play
// Store readiness, game library, profiles, and updates.

import SwiftUI

struct HealthCheckView: View {
    @EnvironmentObject private var app: AppEnvironment
    @Binding var selectedSection: AppSection?

    private var goodCount: Int {
        app.healthCheckItems.filter { $0.status == .good }.count
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header

                LazyVGrid(columns: adaptiveColumns, spacing: 18) {
                    ForEach(app.healthCheckItems) { item in
                        healthCard(item)
                    }
                }
            }
            .padding(28)
            .frame(maxWidth: 1080, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .task {
            app.refreshHealthChecks()
        }
    }

    private var header: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: 18) {
                titleBlock
                Spacer()
                diagnosticButtons
                healthScore
            }

            VStack(alignment: .leading, spacing: 12) {
                titleBlock
                HStack {
                    healthScore
                    diagnosticButtons
                }
            }
        }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Health Check")
                .font(.largeTitle.weight(.black))
            Text("A quick report for SDK, emulator, Play Store, profiles, library, and updates.")
                .foregroundStyle(.secondary)
        }
    }

    private var healthScore: some View {
        StatusBadge(
            title: "\(goodCount)/\(max(app.healthCheckItems.count, 1)) Ready",
            color: goodCount == app.healthCheckItems.count ? Color(hex: 0x1EEA8A) : Color(hex: 0xFFD166)
        )
    }

    private var diagnosticButtons: some View {
        HStack(spacing: 10) {
            Button {
                Task { await app.exportDiagnostics() }
            } label: {
                Label("Export Diagnostics", systemImage: "square.and.arrow.up")
            }
            .disabled(app.isBusy)

            if app.latestDiagnosticURL != nil {
                Button {
                    app.revealLatestDiagnostics()
                } label: {
                    Image(systemName: "folder.fill")
                }
                .help("Show the latest diagnostics file in Finder")
            }
        }
    }

    private func healthCard(_ item: HealthCheckItem) -> some View {
        PanelView {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: item.status.systemImage)
                        .font(.title2)
                        .foregroundStyle(item.status.color)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .font(.headline.weight(.bold))
                        Text(item.status.rawValue)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(item.status.color)
                    }

                    Spacer()
                }

                Text(item.message)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                if let actionTitle = item.actionTitle {
                    Button {
                        handleAction(actionTitle)
                    } label: {
                        Text(actionTitle)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    private func handleAction(_ title: String) {
        switch title {
        case "Open Setup":
            selectedSection = .setup
        case "Create AVD":
            Task { await app.createRecommendedAVD() }
        case "Start Emulator":
            Task { await app.startEmulator() }
        case "Refresh Library":
            Task { await app.refreshGames() }
        case "Open Profiles":
            selectedSection = .profiles
        case "Check Updates":
            Task { await app.checkForUpdates() }
        default:
            break
        }
    }

    private var adaptiveColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 300, maximum: 520), spacing: 18, alignment: .top)]
    }
}
