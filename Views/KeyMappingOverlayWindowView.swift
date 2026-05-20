//
// KeyMappingOverlayWindowView.swift
// MacDroid
//
// Floating live-control window. Keep it focused while playing; keyboard and
// mouse events are converted into ADB input commands for the active profile.

import AppKit
import SwiftUI

struct KeyMappingOverlayWindowView: View {
    @EnvironmentObject private var app: AppEnvironment

    private var activeProfile: KeyMappingProfile? {
        guard let packageName = app.activeKeyMappingPackageName else {
            return nil
        }

        return app.keyProfiles.first(where: { $0.packageName == packageName })
    }

    private var activeGame: AndroidApp? {
        guard let packageName = app.activeKeyMappingPackageName else {
            return nil
        }

        return app.games.first(where: { $0.packageName == packageName })
    }

    var body: some View {
        ZStack {
            VisualEffectBackground(material: .hudWindow, blendingMode: .behindWindow)
            FloatingWindowConfigurator()
            KeyMappingKeyboardCaptureView { trigger in
                Task { await app.runKeyMappingTrigger(trigger) }
            }
            .frame(width: 1, height: 1)
            .opacity(0.01)

            VStack(alignment: .leading, spacing: 14) {
                header

                if let activeProfile {
                    overlayCanvas(profile: activeProfile)
                } else {
                    EmptyStateView(
                        systemImage: "keyboard",
                        title: "No active profile",
                        message: "Open Key Mapping and activate a game profile."
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }

                footer
            }
            .padding(18)
        }
        .frame(width: 960, height: 590)
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        HStack(spacing: 12) {
            Image(systemName: "keyboard.badge.eye")
                .font(.title2)
                .foregroundStyle(Color(hex: 0x1EEA8A))

            VStack(alignment: .leading, spacing: 3) {
                Text(activeGame?.name ?? "Key Mapping Overlay")
                    .font(.headline.weight(.bold))
                Text(activeProfile?.name ?? "Waiting for profile")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            StatusBadge(
                title: app.keyMappingOverlayIsArmed ? "Armed" : "Paused",
                color: app.keyMappingOverlayIsArmed ? Color(hex: 0x1EEA8A) : .gray
            )

            Button {
                if let activeGame {
                    app.activateKeyMapping(for: activeGame)
                }
            } label: {
                Image(systemName: "play.fill")
            }
            .help("Arm key mapping")
            .disabled(activeGame == nil)

            Button {
                app.stopKeyMappingOverlay()
            } label: {
                Image(systemName: "pause.fill")
            }
            .help("Pause key mapping")
        }
    }

    private func overlayCanvas(profile: KeyMappingProfile) -> some View {
        GeometryReader { proxy in
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.black.opacity(0.30))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(hex: 0x1EEA8A, opacity: 0.45), lineWidth: 1)
                    )
                    .contentShape(Rectangle())
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onEnded { value in
                                Task {
                                    await app.runOverlayMouseTap(
                                        at: normalizedPoint(from: value.location, in: proxy.size)
                                    )
                                }
                            }
                    )

                ForEach(profile.mappings.filter(\.isEnabled)) { mapping in
                    VStack(spacing: 4) {
                        Text(mapping.trigger)
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundStyle(.black)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                            .frame(width: 48, height: 48)
                            .background(Color(hex: 0x1EEA8A), in: Circle())

                        Text(mapping.action.rawValue)
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.black.opacity(0.55), in: Capsule())
                    }
                    .position(
                        x: proxy.size.width * mapping.tapPoint.clamped.x,
                        y: proxy.size.height * mapping.tapPoint.clamped.y
                    )
                }
            }
        }
        .aspectRatio(16.0 / 9.0, contentMode: .fit)
    }

    private var footer: some View {
        HStack {
            Text(app.keyMappingOverlayMessage)
                .font(.caption)
                .foregroundStyle(Color(hex: 0x1EEA8A))
                .lineLimit(2)

            Spacer()

            Text("Focus this window for keyboard controls")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
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
}

private struct KeyMappingKeyboardCaptureView: NSViewRepresentable {
    let onKeyDown: (String) -> Void

    func makeNSView(context: Context) -> KeyboardCaptureNSView {
        let view = KeyboardCaptureNSView()
        view.onKeyDown = onKeyDown

        DispatchQueue.main.async {
            view.window?.makeFirstResponder(view)
        }

        return view
    }

    func updateNSView(_ nsView: KeyboardCaptureNSView, context: Context) {
        nsView.onKeyDown = onKeyDown

        DispatchQueue.main.async {
            nsView.window?.makeFirstResponder(nsView)
        }
    }

    final class KeyboardCaptureNSView: NSView {
        var onKeyDown: ((String) -> Void)?

        override var acceptsFirstResponder: Bool {
            true
        }

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()

            DispatchQueue.main.async {
                self.window?.makeFirstResponder(self)
            }
        }

        override func keyDown(with event: NSEvent) {
            onKeyDown?(Self.triggerName(for: event))
        }

        private static func triggerName(for event: NSEvent) -> String {
            switch event.keyCode {
            case 36: return "Return"
            case 48: return "Tab"
            case 49: return "Space"
            case 51: return "Delete"
            case 53: return "Escape"
            case 123: return "Arrow Left"
            case 124: return "Arrow Right"
            case 125: return "Arrow Down"
            case 126: return "Arrow Up"
            default:
                let text = event.charactersIgnoringModifiers ?? ""
                return text.isEmpty ? "Key \(event.keyCode)" : text.uppercased()
            }
        }
    }
}
