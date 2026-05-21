//
// RootView.swift
// MacDroid
//
// Hosts the main app shell. The sidebar uses explicit buttons so navigation
// stays predictable even when macOS NavigationSplitView styling changes.

import SwiftUI

struct RootView: View {
    @EnvironmentObject private var app: AppEnvironment
    @State private var selectedSection: AppSection? = .home

    var body: some View {
        HStack(spacing: 0) {
            SidebarView(selectedSection: $selectedSection)
                .frame(width: 236)

            Divider()
                .opacity(0.35)

            ZStack {
                AppBackgroundView()

                switch selectedSection ?? .home {
                case .home:
                    HomeDashboardView()
                case .setup:
                    SetupWizardView(selectedSection: $selectedSection)
                case .library:
                    LibraryView()
                case .profiles:
                    GameProfilesView(selectedSection: $selectedSection)
                case .installer:
                    APKInstallerView()
                case .health:
                    HealthCheckView(selectedSection: $selectedSection)
                case .boost:
                    BoostView()
                case .controls:
                    KeyMappingView()
                case .settings:
                    SettingsView()
                case .logs:
                    LogsView()
                }
            }
            .frame(minWidth: 0, maxWidth: .infinity, maxHeight: .infinity)
        }
        .task {
            await app.bootstrap()
        }
    }
}
