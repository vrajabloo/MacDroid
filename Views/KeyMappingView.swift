//
// KeyMappingView.swift
// MacDroid
//
// MVP key mapping editor. It saves per-game profiles and normalized tap points;
// actual input injection is intentionally isolated for a future implementation.

import SwiftUI

struct KeyMappingView: View {
    @EnvironmentObject private var app: AppEnvironment
    @StateObject private var viewModel = KeyMappingViewModel()

    private var selectedApp: AndroidApp? {
        if let packageName = viewModel.selectedPackageName {
            return app.games.first(where: { $0.packageName == packageName })
        }

        return app.games.first
    }

    var body: some View {
        HStack(spacing: 0) {
            gameList
                .frame(width: 300)
                .background(Color.black.opacity(0.16))

            Divider()
                .opacity(0.28)

            editor
        }
    }

    private var gameList: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Key Mapping")
                .font(.largeTitle.weight(.black))

            Text("Create per-game control profiles.")
                .foregroundStyle(.secondary)

            if app.games.isEmpty {
                EmptyStateView(
                    systemImage: "keyboard",
                    title: "No games found",
                    message: "Refresh the library after the emulator boots."
                )
                Spacer()
            } else {
                List(app.games, selection: $viewModel.selectedPackageName) { game in
                    VStack(alignment: .leading, spacing: 3) {
                        Text(game.name)
                            .font(.headline)
                        Text(game.packageName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    .tag(Optional(game.packageName))
                }
                .scrollContentBackground(.hidden)
            }
        }
        .padding(24)
        .onAppear {
            viewModel.selectedPackageName = selectedApp?.packageName
        }
    }

    private var editor: some View {
        Group {
            if let selectedApp {
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        editorHeader(for: selectedApp)
                        profileSettings(for: selectedApp)
                        mappingCanvas(for: selectedApp)
                        mappingList(for: selectedApp)
                        limitationPanel
                    }
                    .padding(28)
                }
            } else {
                EmptyStateView(
                    systemImage: "keyboard",
                    title: "Choose a game",
                    message: "Select an installed Android app to create a control profile."
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private func editorHeader(for game: AndroidApp) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(game.name)
                    .font(.largeTitle.weight(.black))
                Text(game.packageName)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }

            Spacer()

            Button {
                app.createDefaultProfile(for: game)
            } label: {
                Label("Create WASD Profile", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(hex: 0x1EEA8A))
        }
    }

    private func mappingCanvas(for game: AndroidApp) -> some View {
        let profile = viewModel.profile(for: game, in: app.keyProfiles)
        let mappings = profile?.mappings ?? []

        return PanelView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Tap layout")
                    .font(.title3.weight(.bold))

                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: 0x171C1B), Color(hex: 0x101214)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(hex: 0x1EEA8A, opacity: 0.24), lineWidth: 1)
                        )

                    GeometryReader { proxy in
                        ForEach(mappings) { mapping in
                            mappingMarker(mapping)
                                .position(
                                    x: proxy.size.width * mapping.tapPoint.x,
                                    y: proxy.size.height * mapping.tapPoint.y
                                )
                        }
                    }
                }
                .aspectRatio(16.0 / 9.0, contentMode: .fit)

                HStack {
                    Button {
                        addSampleMapping(to: game)
                    } label: {
                        Label("Add Tap", systemImage: "plus")
                    }

                    Button {
                        app.saveKeyProfiles()
                    } label: {
                        Label("Save Profile", systemImage: "square.and.arrow.down")
                    }
                }
            }
        }
    }

    private func profileSettings(for game: AndroidApp) -> some View {
        PanelView {
            VStack(alignment: .leading, spacing: 14) {
                Label("Input bridge", systemImage: "gamecontroller.fill")
                    .font(.title3.weight(.bold))

                if let index = app.keyProfiles.firstIndex(where: { $0.packageName == game.packageName }) {
                    Picker("Mode", selection: inputBridgeBinding(index: index)) {
                        ForEach(InputBridgeMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }

                    Toggle("Prepare gamepad profile", isOn: gamepadBinding(index: index))

                    Text(app.keyProfiles[index].inputBridgeMode.summary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    HStack {
                        Button {
                            addGamepadSample(to: game)
                        } label: {
                            Label("Add Gamepad A", systemImage: "button.programmable")
                        }

                        Button {
                            app.saveKeyProfiles()
                        } label: {
                            Label("Save Input Profile", systemImage: "square.and.arrow.down")
                        }
                    }
                } else {
                    EmptyStateView(
                        systemImage: "gamecontroller",
                        title: "No profile yet",
                        message: "Create a profile before enabling future gamepad or overlay input."
                    )

                    Button {
                        app.createDefaultProfile(for: game)
                    } label: {
                        Label("Create Profile", systemImage: "plus.circle.fill")
                    }
                }
            }
        }
    }

    private func mappingMarker(_ mapping: InputMapping) -> some View {
        VStack(spacing: 4) {
            Text(mapping.trigger)
                .font(.headline.weight(.bold))
                .foregroundStyle(.black)
                .frame(width: 42, height: 42)
                .background(Color(hex: 0x1EEA8A), in: Circle())

            Text(mapping.inputType.rawValue)
                .font(.caption2.weight(.semibold))
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.black.opacity(0.5), in: Capsule())
        }
    }

    private func mappingList(for game: AndroidApp) -> some View {
        let profile = viewModel.profile(for: game, in: app.keyProfiles)
        let mappings = profile?.mappings ?? []

        return PanelView {
            VStack(alignment: .leading, spacing: 14) {
                Text("Mappings")
                    .font(.title3.weight(.bold))

                if mappings.isEmpty {
                    EmptyStateView(
                        systemImage: "keyboard.badge.ellipsis",
                        title: "No controls mapped",
                        message: "Create a WASD profile or add a tap mapping."
                    )
                    .frame(maxWidth: .infinity)
                } else {
                    Grid(alignment: .leading, horizontalSpacing: 18, verticalSpacing: 10) {
                        GridRow {
                            Text("Input").foregroundStyle(.secondary)
                            Text("Type").foregroundStyle(.secondary)
                            Text("Tap position").foregroundStyle(.secondary)
                            Text("Note").foregroundStyle(.secondary)
                            Text("Test").foregroundStyle(.secondary)
                        }

                        ForEach(mappings) { mapping in
                            GridRow {
                                Text(mapping.trigger).fontWeight(.semibold)
                                Text(mapping.inputType.rawValue)
                                Text("\(Int(mapping.tapPoint.x * 100))%, \(Int(mapping.tapPoint.y * 100))%")
                                Text(mapping.note).foregroundStyle(.secondary)
                                Button {
                                    Task { await app.testMapping(mapping) }
                                } label: {
                                    Image(systemName: "dot.scope")
                                }
                                .help("Send this tap through ADB")
                                .disabled(app.emulatorState != .running)
                            }
                        }
                    }
                    .font(.callout)
                }
            }
        }
    }

    private var limitationPanel: some View {
        PanelView {
            VStack(alignment: .leading, spacing: 10) {
                Label("MVP limitation", systemImage: "info.circle.fill")
                    .font(.headline)
                    .foregroundStyle(Color(hex: 0xFFD166))

                Text("This version saves key mapping profiles and loads them when a game launches. Direct input injection is intentionally left behind a clean service boundary for a future build using ADB input commands, a transparent overlay, or a gamepad event bridge.")
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func addSampleMapping(to game: AndroidApp) {
        if let index = app.keyProfiles.firstIndex(where: { $0.packageName == game.packageName }) {
            app.keyProfiles[index].mappings.append(
                InputMapping.sample(trigger: "Space", x: 0.78, y: 0.72)
            )
            app.keyProfiles[index].updatedAt = .now
        } else {
            var profile = KeyMappingProfile.empty(for: game)
            profile.mappings.append(InputMapping.sample(trigger: "Space", x: 0.78, y: 0.72))
            app.keyProfiles.append(profile)
        }

        app.saveKeyProfiles()
    }

    private func addGamepadSample(to game: AndroidApp) {
        let mapping = InputMapping(
            id: UUID(),
            inputType: .gamepad,
            trigger: "A",
            tapPoint: NormalizedPoint(x: 0.82, y: 0.72),
            note: "Future gamepad button tap"
        )

        if let index = app.keyProfiles.firstIndex(where: { $0.packageName == game.packageName }) {
            app.keyProfiles[index].gamepadEnabled = true
            app.keyProfiles[index].inputBridgeMode = .gamepadPlanned
            app.keyProfiles[index].mappings.append(mapping)
            app.keyProfiles[index].updatedAt = .now
        } else {
            var profile = KeyMappingProfile.empty(for: game)
            profile.gamepadEnabled = true
            profile.inputBridgeMode = .gamepadPlanned
            profile.mappings.append(mapping)
            app.keyProfiles.append(profile)
        }

        app.saveKeyProfiles()
    }

    private func inputBridgeBinding(index: Int) -> Binding<InputBridgeMode> {
        Binding(
            get: { app.keyProfiles[index].inputBridgeMode },
            set: { mode in
                app.keyProfiles[index].inputBridgeMode = mode
                app.keyProfiles[index].updatedAt = .now
                app.saveKeyProfiles()
            }
        )
    }

    private func gamepadBinding(index: Int) -> Binding<Bool> {
        Binding(
            get: { app.keyProfiles[index].gamepadEnabled },
            set: { isEnabled in
                app.keyProfiles[index].gamepadEnabled = isEnabled
                app.keyProfiles[index].updatedAt = .now
                app.saveKeyProfiles()
            }
        )
    }
}
