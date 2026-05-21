//
// GameProfilesView.swift
// MacDroid
//
// Per-game launch profiles. A profile stores orientation, performance, display,
// and overlay preferences so each game can start with the right setup.

import SwiftUI

struct GameProfilesView: View {
    @EnvironmentObject private var app: AppEnvironment
    @Binding var selectedSection: AppSection?
    @State private var selectedPackageName: String?

    private var selectedGame: AndroidApp? {
        if let selectedPackageName,
           let game = app.games.first(where: { $0.packageName == selectedPackageName }) {
            return game
        }

        return app.games.first
    }

    var body: some View {
        GeometryReader { proxy in
            if proxy.size.width < 1_020 {
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        header
                        compactPicker
                        profileEditor
                    }
                    .padding(24)
                    .frame(maxWidth: 860, alignment: .leading)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            } else {
                HStack(spacing: 0) {
                    gameList
                        .frame(width: 280)
                        .background(Color.black.opacity(0.16))

                    Divider().opacity(0.28)

                    ScrollView {
                        VStack(alignment: .leading, spacing: 22) {
                            header
                            profileEditor
                        }
                        .padding(28)
                        .frame(maxWidth: 860, alignment: .leading)
                        .frame(maxWidth: .infinity, alignment: .center)
                    }
                }
            }
        }
        .onAppear {
            selectedPackageName = selectedGame?.packageName
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Game Profiles")
                .font(.largeTitle.weight(.black))
            Text("Save launch behavior per game: orientation, performance, display, and key mapping overlay.")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var compactPicker: some View {
        Group {
            if !app.games.isEmpty {
                Picker("Game", selection: $selectedPackageName) {
                    ForEach(app.games) { game in
                        Text(game.name).tag(Optional(game.packageName))
                    }
                }
                .labelsHidden()
                .frame(maxWidth: 360, alignment: .leading)
            }
        }
    }

    private var gameList: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Installed apps")
                .font(.title2.weight(.black))

            if app.games.isEmpty {
                EmptyStateView(
                    systemImage: "square.grid.2x2",
                    title: "No apps yet",
                    message: "Boot the emulator and refresh the library."
                )
                Spacer()
            } else {
                List(app.games, selection: $selectedPackageName) { game in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(game.name)
                            .font(.headline)
                        Text(profileStatus(for: game))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .tag(Optional(game.packageName))
                }
                .scrollContentBackground(.hidden)
            }
        }
        .padding(24)
    }

    private var profileEditor: some View {
        Group {
            if let selectedGame {
                let profileIndex = app.gameProfiles.firstIndex(where: { $0.packageName == selectedGame.packageName })

                if let profileIndex {
                    editor(for: selectedGame, profileIndex: profileIndex)
                } else {
                    emptyProfile(for: selectedGame)
                }
            } else {
                EmptyStateView(
                    systemImage: "person.text.rectangle",
                    title: "No game selected",
                    message: "Refresh the library after Android boots."
                )
            }
        }
    }

    private func emptyProfile(for game: AndroidApp) -> some View {
        PanelView {
            VStack(alignment: .leading, spacing: 16) {
                Label(game.name, systemImage: "gamecontroller.fill")
                    .font(.title3.weight(.bold))

                Text("No launch profile exists for this app yet.")
                    .foregroundStyle(.secondary)

                HStack {
                    Button {
                        _ = app.ensureGameProfile(for: game)
                    } label: {
                        Label("Create Profile", systemImage: "plus.circle.fill")
                    }

                    Button {
                        app.createRecommendedGameProfile(for: game)
                    } label: {
                        Label("Recommended Gaming Profile", systemImage: "wand.and.stars")
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(hex: 0x1EEA8A))
                }
            }
        }
    }

    private func editor(for game: AndroidApp, profileIndex: Int) -> some View {
        VStack(alignment: .leading, spacing: 18) {
            PanelView {
                VStack(alignment: .leading, spacing: 16) {
                    editorHeader(for: game)

                    TextField("Profile name", text: profileNameBinding(index: profileIndex))
                        .textFieldStyle(.roundedBorder)

                    Picker("Orientation", selection: orientationBinding(index: profileIndex)) {
                        ForEach(GameOrientationPreference.allCases) { preference in
                            Label(preference.rawValue, systemImage: preference.systemImage).tag(preference)
                        }
                    }

                    Text(app.gameProfiles[profileIndex].orientationPreference.summary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Toggle("Open key mapping overlay when launching", isOn: overlayBinding(index: profileIndex))
                }
            }

            LazyVGrid(columns: adaptiveColumns, spacing: 18) {
                settingsPanel(profileIndex: profileIndex)
                actionsPanel(for: game, profileIndex: profileIndex)
            }
        }
    }

    private func editorHeader(for game: AndroidApp) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(game.name)
                        .font(.title.weight(.black))
                    Text(game.packageName)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .textSelection(.enabled)
                }

                Spacer()

                Button {
                    Task { await app.launch(game) }
                } label: {
                    Label("Launch", systemImage: "play.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: 0x1EEA8A))
            }

            VStack(alignment: .leading, spacing: 12) {
                Text(game.name)
                    .font(.title.weight(.black))
                Text(game.packageName)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Button {
                    Task { await app.launch(game) }
                } label: {
                    Label("Launch", systemImage: "play.fill")
                }
            }
        }
    }

    private func settingsPanel(profileIndex: Int) -> some View {
        PanelView {
            VStack(alignment: .leading, spacing: 16) {
                Label("Performance", systemImage: "speedometer")
                    .font(.title3.weight(.bold))

                Picker("Profile", selection: performanceBinding(index: profileIndex)) {
                    ForEach(PerformanceProfile.allCases) { profile in
                        Text(profile.rawValue).tag(profile)
                    }
                }

                Picker("Resolution", selection: resolutionBinding(index: profileIndex)) {
                    ForEach(ResolutionPreset.allCases) { preset in
                        Text(preset.rawValue).tag(preset)
                    }
                }

                Picker("DPI", selection: dpiBinding(index: profileIndex)) {
                    ForEach(DPIPreset.allCases) { preset in
                        Text(preset.rawValue).tag(preset)
                    }
                }

                Text("Resource changes are written to the selected AVD before the next emulator launch.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func actionsPanel(for game: AndroidApp, profileIndex: Int) -> some View {
        PanelView {
            VStack(alignment: .leading, spacing: 14) {
                Label("Actions", systemImage: "bolt.fill")
                    .font(.title3.weight(.bold))

                Button {
                    app.createRecommendedGameProfile(for: game)
                } label: {
                    Label("Apply Recommended", systemImage: "wand.and.stars")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button {
                    Task { await app.applyOrientationPreference(app.gameProfiles[profileIndex].orientationPreference) }
                } label: {
                    Label("Apply Orientation Now", systemImage: "rectangle.landscape.rotate")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .disabled(app.emulatorState != .running || app.isBusy)

                Button {
                    selectedSection = .controls
                } label: {
                    Label("Edit Key Mapping", systemImage: "keyboard.fill")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button {
                    app.saveGameProfiles()
                } label: {
                    Label("Save Profile", systemImage: "square.and.arrow.down")
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private func profileStatus(for game: AndroidApp) -> String {
        app.gameProfiles.contains(where: { $0.packageName == game.packageName }) ? "Profile saved" : "No profile"
    }

    private func profileNameBinding(index: Int) -> Binding<String> {
        Binding(
            get: { app.gameProfiles[index].displayName },
            set: { value in
                app.gameProfiles[index].displayName = value
                app.gameProfiles[index].updatedAt = .now
            }
        )
    }

    private func orientationBinding(index: Int) -> Binding<GameOrientationPreference> {
        Binding(
            get: { app.gameProfiles[index].orientationPreference },
            set: { value in
                app.gameProfiles[index].orientationPreference = value
                app.gameProfiles[index].updatedAt = .now
                app.saveGameProfiles()
            }
        )
    }

    private func overlayBinding(index: Int) -> Binding<Bool> {
        Binding(
            get: { app.gameProfiles[index].autoOpenKeyMappingOverlay },
            set: { value in
                app.gameProfiles[index].autoOpenKeyMappingOverlay = value
                app.gameProfiles[index].updatedAt = .now
                app.saveGameProfiles()
            }
        )
    }

    private func performanceBinding(index: Int) -> Binding<PerformanceProfile> {
        Binding(
            get: { app.gameProfiles[index].performanceProfile },
            set: { value in
                app.gameProfiles[index].performanceProfile = value
                app.gameProfiles[index].updatedAt = .now
                app.saveGameProfiles()
            }
        )
    }

    private func resolutionBinding(index: Int) -> Binding<ResolutionPreset> {
        Binding(
            get: { app.gameProfiles[index].resolutionPreset },
            set: { value in
                app.gameProfiles[index].resolutionPreset = value
                app.gameProfiles[index].updatedAt = .now
                app.saveGameProfiles()
            }
        )
    }

    private func dpiBinding(index: Int) -> Binding<DPIPreset> {
        Binding(
            get: { app.gameProfiles[index].dpiPreset },
            set: { value in
                app.gameProfiles[index].dpiPreset = value
                app.gameProfiles[index].updatedAt = .now
                app.saveGameProfiles()
            }
        )
    }

    private var adaptiveColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 300, maximum: 520), spacing: 18, alignment: .top)]
    }
}
