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
        .frame(maxWidth: 1120, alignment: .leading)
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private var header: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 14) {
                headerTitle
                Spacer(minLength: 12)
                headerControls
            }

            VStack(alignment: .leading, spacing: 14) {
                headerTitle
                headerControls
            }
        }
    }

    private var headerTitle: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Game Library")
                .font(.largeTitle.weight(.black))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text("Installed Android apps discovered through ADB.")
                .foregroundStyle(.secondary)
        }
    }

    private var headerControls: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 12) {
                filterPicker
                searchField
                refreshButton
                playStoreButton
            }

            VStack(alignment: .leading, spacing: 10) {
                filterPicker
                searchField
                HStack(spacing: 10) {
                    refreshButton
                    playStoreButton
                }
            }
        }
    }

    private var filterPicker: some View {
        Picker("Filter", selection: $viewModel.filter) {
            ForEach(LibraryFilter.allCases) { filter in
                Label(filter.rawValue, systemImage: filter.systemImage).tag(filter)
            }
        }
        .pickerStyle(.segmented)
        .frame(width: 280)
    }

    private var searchField: some View {
        TextField("Search games or packages", text: $viewModel.searchText)
            .textFieldStyle(.roundedBorder)
            .frame(width: 260)
    }

    private var refreshButton: some View {
        Button {
            Task { await app.refreshGames() }
        } label: {
            Label("Refresh", systemImage: "arrow.clockwise")
        }
    }

    private var playStoreButton: some View {
        Button {
            Task { await app.openPlayStore() }
        } label: {
            Label("Play Store", systemImage: "play.square.fill")
        }
        .disabled(app.emulatorState != .running)
    }
}
