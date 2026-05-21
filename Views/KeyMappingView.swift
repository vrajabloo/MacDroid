//
// KeyMappingView.swift
// MacDroid
//
// A practical per-game key mapping editor. Users can place touch points on a
// 16:9 canvas, bind them to keyboard/mouse triggers, and run them through ADB.

import SwiftUI

struct KeyMappingView: View {
    @EnvironmentObject private var app: AppEnvironment
    @Environment(\.openWindow) private var openWindow
    @StateObject private var viewModel = KeyMappingViewModel()
    @State private var newTrigger = "Space"
    @State private var newInputType: InputMappingType = .keyboard
    @State private var newAction: InputMappingAction = .tap

    private var selectedApp: AndroidApp? {
        if let packageName = viewModel.selectedPackageName {
            return app.games.first(where: { $0.packageName == packageName })
        }

        return app.games.first
    }

    var body: some View {
        GeometryReader { proxy in
            if proxy.size.width < 1_040 {
                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        gameList(compact: true)
                        editorContent
                    }
                    .padding(24)
                    .frame(maxWidth: 840, alignment: .leading)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            } else {
                HStack(spacing: 0) {
                    gameList(compact: false)
                        .frame(width: 260)
                        .background(Color.black.opacity(0.16))

                    Divider()
                        .opacity(0.28)

                    editor
                }
            }
        }
    }

    private func gameList(compact: Bool) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Key Mapping")
                        .font(compact ? .title.weight(.black) : .largeTitle.weight(.black))

                    Text("Per-game controls")
                        .foregroundStyle(.secondary)
                }

                if compact {
                    Spacer()
                }
            }

            if app.games.isEmpty {
                EmptyStateView(
                    systemImage: "keyboard",
                    title: "No games found",
                    message: "Refresh the library after the emulator boots."
                )
                Spacer()
            } else if compact {
                Picker("Game", selection: $viewModel.selectedPackageName) {
                    ForEach(app.games) { game in
                        Text(game.name).tag(Optional(game.packageName))
                    }
                }
                .labelsHidden()
                .frame(maxWidth: 320, alignment: .leading)
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
        ScrollView {
            editorContent
                .padding(28)
                .frame(maxWidth: 840, alignment: .leading)
                .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private var editorContent: some View {
        Group {
            if let selectedApp {
                VStack(alignment: .leading, spacing: 22) {
                    editorHeader(for: selectedApp)
                    profileSettings(for: selectedApp)
                    mappingCanvas(for: selectedApp)
                    mappingList(for: selectedApp)
                    adbBridgePanel
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
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: 16) {
                editorTitle(for: game)

                Spacer()

                headerActions(for: game)
            }

            VStack(alignment: .leading, spacing: 12) {
                editorTitle(for: game)
                headerActions(for: game)
            }
        }
    }

    private func editorTitle(for game: AndroidApp) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(game.name)
                .font(.largeTitle.weight(.black))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text(game.packageName)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .truncationMode(.middle)
                .textSelection(.enabled)
        }
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
    }

    private func headerActions(for game: AndroidApp) -> some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) {
                mappingPresetButtons(for: game)
            }

            VStack(alignment: .leading, spacing: 10) {
                mappingPresetButtons(for: game)
            }
        }
    }

    private func mappingPresetButtons(for game: AndroidApp) -> some View {
        Group {
            Button {
                app.createDefaultProfile(for: game)
            } label: {
                Label("WASD", systemImage: "wand.and.stars")
            }

            Button {
                app.createShooterProfile(for: game)
            } label: {
                Label("Shooter", systemImage: "scope")
            }

            Button {
                app.createMOBAMappingProfile(for: game)
            } label: {
                Label("MOBA", systemImage: "sparkles")
            }

            Button {
                app.activateKeyMapping(for: game)
                openWindow(id: "key-mapping-overlay")
            } label: {
                Label("Live Overlay", systemImage: "keyboard.badge.eye")
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(hex: 0x1EEA8A))
        }
    }

    private func profileSettings(for game: AndroidApp) -> some View {
        PanelView {
            VStack(alignment: .leading, spacing: 14) {
                Label("Profile", systemImage: "gamecontroller.fill")
                    .font(.title3.weight(.bold))

                if let index = app.keyProfiles.firstIndex(where: { $0.packageName == game.packageName }) {
                    TextField("Profile name", text: profileNameBinding(index: index))

                    Picker("Mode", selection: inputBridgeBinding(index: index)) {
                        ForEach(InputBridgeMode.allCases) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }

                    Toggle("Gamepad-ready profile", isOn: gamepadBinding(index: index))

                    Text(app.keyProfiles[index].inputBridgeMode.summary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    ViewThatFits(in: .horizontal) {
                        HStack {
                            profileButtons(for: game)
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            profileButtons(for: game)
                        }
                    }
                } else {
                    EmptyStateView(
                        systemImage: "gamecontroller",
                        title: "No profile yet",
                        message: "Create a profile before adding controls."
                    )

                    Button {
                        _ = app.ensureKeyMappingProfile(for: game)
                    } label: {
                        Label("Create Profile", systemImage: "plus.circle.fill")
                    }
                }
            }
        }
    }

    private func profileButtons(for game: AndroidApp) -> some View {
        Group {
            Button {
                addGamepadSample(to: game)
            } label: {
                Label("Add Gamepad A", systemImage: "button.programmable")
            }

            Button {
                app.activateKeyMapping(for: game)
                openWindow(id: "key-mapping-overlay")
            } label: {
                Label("Open Overlay", systemImage: "rectangle.on.rectangle")
            }

            Button {
                app.saveKeyProfiles()
            } label: {
                Label("Save", systemImage: "square.and.arrow.down")
            }

            Button {
                app.exportKeyProfiles()
            } label: {
                Label("Export", systemImage: "square.and.arrow.up")
            }
        }
    }

    private func mappingCanvas(for game: AndroidApp) -> some View {
        let profile = viewModel.profile(for: game, in: app.keyProfiles)
        let mappings = profile?.mappings ?? []

        return PanelView {
            VStack(alignment: .leading, spacing: 16) {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 12) {
                        canvasTitle
                        Spacer()
                        newMappingControls
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        canvasTitle
                        newMappingControls
                    }
                }

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
                        Rectangle()
                            .fill(Color.clear)
                            .contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onEnded { value in
                                        addMapping(
                                            to: game,
                                            at: normalizedPoint(from: value.location, in: proxy.size)
                                        )
                                    }
                            )

                        ForEach(mappings) { mapping in
                            mappingMarker(mapping)
                                .position(
                                    x: proxy.size.width * mapping.tapPoint.clamped.x,
                                    y: proxy.size.height * mapping.tapPoint.clamped.y
                                )
                                .gesture(
                                    DragGesture(minimumDistance: 0)
                                        .onChanged { value in
                                            moveMapping(
                                                mapping,
                                                in: game,
                                                to: normalizedPoint(from: value.location, in: proxy.size)
                                            )
                                        }
                                )
                        }
                    }
                }
                .aspectRatio(16.0 / 9.0, contentMode: .fit)

                ViewThatFits(in: .horizontal) {
                    HStack {
                        Button {
                            addMapping(to: game, at: NormalizedPoint(x: 0.78, y: 0.72))
                        } label: {
                            Label("Add Control", systemImage: "plus")
                        }

                        Button {
                            app.saveKeyProfiles()
                        } label: {
                            Label("Save Profile", systemImage: "square.and.arrow.down")
                        }
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Button {
                            addMapping(to: game, at: NormalizedPoint(x: 0.78, y: 0.72))
                        } label: {
                            Label("Add Control", systemImage: "plus")
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
    }

    private var canvasTitle: some View {
        Text("Tap layout")
            .font(.title3.weight(.bold))
    }

    private var newMappingControls: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) {
                newMappingFields
            }

            VStack(alignment: .leading, spacing: 10) {
                newMappingFields
            }
        }
    }

    private var newMappingFields: some View {
        Group {
            Picker("Type", selection: $newInputType) {
                ForEach(InputMappingType.allCases) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .frame(width: 130)

            Picker("Action", selection: $newAction) {
                ForEach(InputMappingAction.allCases) { action in
                    Text(action.rawValue).tag(action)
                }
            }
            .frame(width: 145)

            TextField("Trigger", text: $newTrigger)
                .textFieldStyle(.roundedBorder)
                .frame(width: 120)
        }
    }

    private func mappingMarker(_ mapping: InputMapping) -> some View {
        VStack(spacing: 4) {
            Text(mapping.trigger.isEmpty ? "?" : mapping.trigger)
                .font(.headline.weight(.bold))
                .foregroundStyle(.black)
                .lineLimit(1)
                .minimumScaleFactor(0.55)
                .frame(width: 46, height: 46)
                .background(mapping.isEnabled ? Color(hex: 0x1EEA8A) : Color.gray, in: Circle())

            HStack(spacing: 4) {
                Image(systemName: mapping.action.systemImage)
                Text(mapping.inputType.rawValue)
            }
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.black.opacity(0.55), in: Capsule())
        }
    }

    private func mappingList(for game: AndroidApp) -> some View {
        guard let profileIndex = app.keyProfiles.firstIndex(where: { $0.packageName == game.packageName }) else {
            return AnyView(
                PanelView {
                    EmptyStateView(
                        systemImage: "keyboard.badge.ellipsis",
                        title: "No controls mapped",
                        message: "Create a profile or click the tap layout to add controls."
                    )
                }
            )
        }

        return AnyView(
            PanelView {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Mappings")
                        .font(.title3.weight(.bold))

                    if app.keyProfiles[profileIndex].mappings.isEmpty {
                        EmptyStateView(
                            systemImage: "keyboard.badge.ellipsis",
                            title: "No controls mapped",
                            message: "Create a WASD preset or click the tap layout."
                        )
                        .frame(maxWidth: .infinity)
                    } else {
                        VStack(spacing: 10) {
                            ForEach(app.keyProfiles[profileIndex].mappings) { mapping in
                                MappingEditorRow(
                                    mapping: mappingBinding(game: game, mapping: mapping),
                                    onTest: { currentMapping in
                                        Task { await app.testMapping(currentMapping) }
                                    },
                                    onDelete: {
                                        deleteMapping(mapping, from: game)
                                    }
                                )
                            }
                        }
                    }
                }
            }
        )
    }

    private var adbBridgePanel: some View {
        PanelView {
            VStack(alignment: .leading, spacing: 10) {
                Label("ADB bridge", systemImage: "bolt.horizontal.circle.fill")
                    .font(.headline)
                    .foregroundStyle(Color(hex: 0xFFD166))

                Text("Live Overlay sends keyboard and mouse mappings through Android's official ADB input commands. It is useful now, but very fast competitive games may still need a future lower-latency input bridge.")
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func addMapping(to game: AndroidApp, at point: NormalizedPoint) {
        let profileIndex = app.ensureKeyMappingProfile(for: game)
        let trigger = newTrigger.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Space" : newTrigger
        let mapping = InputMapping(
            inputType: newInputType,
            trigger: trigger,
            action: newAction,
            tapPoint: point.clamped,
            secondaryPoint: newAction == .swipe ? NormalizedPoint(x: min(1, point.x + 0.12), y: point.y).clamped : nil,
            durationMilliseconds: newAction.defaultDurationMilliseconds,
            note: "\(newAction.rawValue) at \(Int(point.clamped.x * 100))%, \(Int(point.clamped.y * 100))%"
        )

        app.keyProfiles[profileIndex].mappings.append(mapping)
        app.keyProfiles[profileIndex].inputBridgeMode = .liveOverlay
        app.keyProfiles[profileIndex].updatedAt = .now
        app.saveKeyProfiles()
    }

    private func addGamepadSample(to game: AndroidApp) {
        let mapping = InputMapping(
            inputType: .gamepad,
            trigger: "A",
            action: .tap,
            tapPoint: NormalizedPoint(x: 0.82, y: 0.72),
            note: "Gamepad A button tap"
        )

        let profileIndex = app.ensureKeyMappingProfile(for: game)
        app.keyProfiles[profileIndex].gamepadEnabled = true
        app.keyProfiles[profileIndex].inputBridgeMode = .gamepadPlanned
        app.keyProfiles[profileIndex].mappings.append(mapping)
        app.keyProfiles[profileIndex].updatedAt = .now
        app.saveKeyProfiles()
    }

    private func moveMapping(_ mapping: InputMapping, in game: AndroidApp, to point: NormalizedPoint) {
        guard let profileIndex = app.keyProfiles.firstIndex(where: { $0.packageName == game.packageName }),
              let mappingIndex = app.keyProfiles[profileIndex].mappings.firstIndex(where: { $0.id == mapping.id }) else {
            return
        }

        app.keyProfiles[profileIndex].mappings[mappingIndex].tapPoint = point.clamped
        app.keyProfiles[profileIndex].mappings[mappingIndex].updatedNoteForPosition()
        app.keyProfiles[profileIndex].updatedAt = .now
    }

    private func deleteMapping(_ mapping: InputMapping, from game: AndroidApp) {
        guard let profileIndex = app.keyProfiles.firstIndex(where: { $0.packageName == game.packageName }) else {
            return
        }

        app.keyProfiles[profileIndex].mappings.removeAll { $0.id == mapping.id }
        app.keyProfiles[profileIndex].updatedAt = .now
        app.saveKeyProfiles()
    }

    private func normalizedPoint(from location: CGPoint, in size: CGSize) -> NormalizedPoint {
        guard size.width > 0, size.height > 0 else {
            return NormalizedPoint(x: 0.5, y: 0.5)
        }

        return NormalizedPoint(
            x: Double(location.x / size.width),
            y: Double(location.y / size.height)
        ).clamped
    }

    private func mappingBinding(game: AndroidApp, mapping: InputMapping) -> Binding<InputMapping> {
        Binding(
            get: {
                guard let profileIndex = app.keyProfiles.firstIndex(where: { $0.packageName == game.packageName }),
                      let mappingIndex = app.keyProfiles[profileIndex].mappings.firstIndex(where: { $0.id == mapping.id }) else {
                    return mapping
                }

                return app.keyProfiles[profileIndex].mappings[mappingIndex]
            },
            set: { updatedMapping in
                guard let profileIndex = app.keyProfiles.firstIndex(where: { $0.packageName == game.packageName }),
                      let mappingIndex = app.keyProfiles[profileIndex].mappings.firstIndex(where: { $0.id == mapping.id }) else {
                    return
                }

                app.keyProfiles[profileIndex].mappings[mappingIndex] = updatedMapping
                app.keyProfiles[profileIndex].updatedAt = .now
            }
        )
    }

    private func profileNameBinding(index: Int) -> Binding<String> {
        Binding(
            get: { app.keyProfiles[index].name },
            set: { name in
                app.keyProfiles[index].name = name
                app.keyProfiles[index].updatedAt = .now
            }
        )
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

private struct MappingEditorRow: View {
    @Binding var mapping: InputMapping
    let onTest: (InputMapping) -> Void
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) {
                    rowHeaderControls
                }

                VStack(alignment: .leading, spacing: 10) {
                    rowHeaderControls
                }
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 14) {
                    pointSlider(title: "X", value: xBinding)
                    pointSlider(title: "Y", value: yBinding)
                    durationStepper
                }

                VStack(alignment: .leading, spacing: 10) {
                    pointSlider(title: "X", value: xBinding)
                    pointSlider(title: "Y", value: yBinding)
                    durationStepper
                }
            }

            if mapping.action == .swipe {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 14) {
                        pointSlider(title: "End X", value: secondaryXBinding)
                        pointSlider(title: "End Y", value: secondaryYBinding)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        pointSlider(title: "End X", value: secondaryXBinding)
                        pointSlider(title: "End Y", value: secondaryYBinding)
                    }
                }
            }

            TextField("Note", text: $mapping.note)
                .textFieldStyle(.roundedBorder)
        }
        .padding(12)
        .background(Color.white.opacity(0.045), in: RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private var rowHeaderControls: some View {
        Group {
            Toggle("", isOn: $mapping.isEnabled)
                .toggleStyle(.checkbox)
                .labelsHidden()

            TextField("Trigger", text: $mapping.trigger)
                .textFieldStyle(.roundedBorder)
                .frame(width: 120)

            Picker("Type", selection: $mapping.inputType) {
                ForEach(InputMappingType.allCases) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .frame(width: 130)

            Picker("Action", selection: $mapping.action) {
                ForEach(InputMappingAction.allCases) { action in
                    Text(action.rawValue).tag(action)
                }
            }
            .frame(width: 145)

            Button {
                onTest(mapping)
            } label: {
                Image(systemName: "dot.scope")
            }
            .help("Send this mapping through ADB")

            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
            }
            .help("Delete mapping")
        }
    }

    private var durationStepper: some View {
        Stepper("Duration \(mapping.durationMilliseconds) ms", value: $mapping.durationMilliseconds, in: 50...5_000, step: 50)
            .frame(width: 210)
    }

    private var xBinding: Binding<Double> {
        Binding(
            get: { mapping.tapPoint.x },
            set: { mapping.tapPoint.x = $0 }
        )
    }

    private var yBinding: Binding<Double> {
        Binding(
            get: { mapping.tapPoint.y },
            set: { mapping.tapPoint.y = $0 }
        )
    }

    private var secondaryXBinding: Binding<Double> {
        Binding(
            get: { mapping.secondaryPoint?.x ?? mapping.tapPoint.x },
            set: { value in
                var point = mapping.secondaryPoint ?? mapping.tapPoint
                point.x = value
                mapping.secondaryPoint = point.clamped
            }
        )
    }

    private var secondaryYBinding: Binding<Double> {
        Binding(
            get: { mapping.secondaryPoint?.y ?? mapping.tapPoint.y },
            set: { value in
                var point = mapping.secondaryPoint ?? mapping.tapPoint
                point.y = value
                mapping.secondaryPoint = point.clamped
            }
        )
    }

    private func pointSlider(title: String, value: Binding<Double>) -> some View {
        HStack(spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Slider(value: value, in: 0...1)
                .frame(minWidth: 90, maxWidth: 140)
            Text("\(Int(value.wrappedValue * 100))%")
                .font(.caption.monospacedDigit())
                .frame(width: 38, alignment: .trailing)
        }
    }
}

private extension InputMapping {
    mutating func updatedNoteForPosition() {
        if note.hasPrefix("Tap at") || note.hasPrefix("Long Press at") || note.hasPrefix("Swipe at") {
            note = "\(action.rawValue) at \(Int(tapPoint.clamped.x * 100))%, \(Int(tapPoint.clamped.y * 100))%"
        }
    }
}
