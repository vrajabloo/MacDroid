//
// LibraryView.swift
// MacDroid
//
// Shows installed Android apps in a commercial-emulator-style game grid with
// launch, uninstall, and key profile actions.

import SwiftUI

struct LibraryView: View {
    @EnvironmentObject private var app: AppEnvironment
    @StateObject private var viewModel = LibraryViewModel()

    private var filteredGames: [AndroidApp] {
        viewModel.filteredGames(app.games)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header

            if filteredGames.isEmpty {
                PanelView {
                    EmptyStateView(
                        systemImage: "square.grid.2x2",
                        title: "Library is empty",
                        message: "Start the emulator, install an APK, then refresh installed apps."
                    )
                    .frame(maxWidth: .infinity, minHeight: 360)
                }
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 230), spacing: 16)], spacing: 16) {
                        ForEach(filteredGames) { game in
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
                    .padding(.bottom, 20)
                }
            }
        }
        .padding(28)
    }

    private var header: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Game Library")
                    .font(.largeTitle.weight(.black))
                Text("Installed Android apps discovered through ADB.")
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Picker("Filter", selection: $viewModel.filter) {
                ForEach(LibraryFilter.allCases) { filter in
                    Label(filter.rawValue, systemImage: filter.systemImage).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 280)

            TextField("Search games or packages", text: $viewModel.searchText)
                .textFieldStyle(.roundedBorder)
                .frame(width: 260)

            Button {
                Task { await app.refreshGames() }
            } label: {
                Label("Refresh", systemImage: "arrow.clockwise")
            }

            Button {
                Task { await app.openPlayStore() }
            } label: {
                Label("Play Store", systemImage: "play.square.fill")
            }
            .disabled(app.emulatorState != .running)
        }
    }
}
