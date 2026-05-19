//
// EmulatorControlsWindowView.swift
// CleanDroid Gaming
//
// A small standalone controls window. Users can keep this next to the official
// Android Emulator window when the emulator's own side toolbar is unreliable.

import SwiftUI

struct EmulatorControlsWindowView: View {
    @EnvironmentObject private var app: AppEnvironment

    var body: some View {
        ZStack {
            VisualEffectBackground(material: .hudWindow, blendingMode: .behindWindow)
            FloatingWindowConfigurator()

            VStack(spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "gamecontroller.fill")
                        .foregroundStyle(Color(hex: 0x1EEA8A))
                    Text("Emulator Controls")
                        .font(.headline.weight(.bold))
                }

                StatusBadge(title: app.emulatorState.title, color: app.emulatorState.color)

                EmulatorControlsView(layout: .vertical, showStatus: false)

                if !app.lastEmulatorControlMessage.isEmpty {
                    Text(app.lastEmulatorControlMessage)
                        .font(.caption)
                        .foregroundStyle(Color(hex: 0x1EEA8A))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                } else {
                    Text("Use this instead of the Google toolbar.")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(14)
        }
        .frame(width: 112, height: 520)
        .preferredColorScheme(.dark)
    }
}
