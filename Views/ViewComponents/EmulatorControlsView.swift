//
// EmulatorControlsView.swift
// CleanDroid Gaming
//
// CleanDroid's own emulator toolbar. It is a practical replacement for the
// official Google Emulator side toolbar when that toolbar ignores mouse clicks.

import SwiftUI

enum EmulatorControlsLayout {
    case horizontal
    case vertical
}

struct EmulatorControlsView: View {
    @EnvironmentObject private var app: AppEnvironment

    var layout: EmulatorControlsLayout = .vertical
    var showStatus = true

    var body: some View {
        Group {
            switch layout {
            case .horizontal:
                HStack(spacing: 8) {
                    buttons
                }
            case .vertical:
                VStack(spacing: 8) {
                    buttons
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.075))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                )
        )
        .overlay(alignment: .bottom) {
            if showStatus && !app.lastEmulatorControlMessage.isEmpty {
                Text(app.lastEmulatorControlMessage)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color(hex: 0x1EEA8A))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.62), in: Capsule())
                    .offset(y: 28)
            }
        }
    }

    @ViewBuilder
    private var buttons: some View {
        ForEach(EmulatorControlAction.allCases) { action in
            controlButton(for: action)
        }
    }

    private func controlButton(for action: EmulatorControlAction) -> some View {
        Button {
            Task { await app.sendEmulatorControl(action) }
        } label: {
            Image(systemName: action.systemImage)
                .font(.system(size: 15, weight: .semibold))
                .frame(width: 34, height: 34)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(Color(hex: 0xD8FFF0))
        .background(Color.black.opacity(0.20), in: RoundedRectangle(cornerRadius: 7))
        .overlay(
            RoundedRectangle(cornerRadius: 7)
                .stroke(Color.white.opacity(0.10), lineWidth: 1)
        )
        .disabled(app.emulatorState == .stopped || app.emulatorState == .unknown)
        .help(action.title)
    }
}
