//
// RootView.swift
// CleanDroid Gaming
//
// Hosts the macOS NavigationSplitView shell. The detail area changes based on the
// selected sidebar section.

import SwiftUI

struct RootView: View {
    @EnvironmentObject private var app: AppEnvironment
    @State private var selectedSection: AppSection? = .home

    var body: some View {
        NavigationSplitView {
            SidebarView(selectedSection: $selectedSection)
                .navigationSplitViewColumnWidth(min: 230, ideal: 260, max: 320)
        } detail: {
            ZStack {
                AppBackgroundView()

                switch selectedSection ?? .home {
                case .home:
                    HomeDashboardView()
                case .library:
                    LibraryView()
                case .installer:
                    APKInstallerView()
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
        }
        .task {
            await app.bootstrap()
        }
    }
}
