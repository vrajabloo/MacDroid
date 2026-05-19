//
// SidebarView.swift
// CleanDroid Gaming
//
// Native macOS sidebar with a gaming-style product mark and live emulator status.

import SwiftUI

struct SidebarView: View {
    @EnvironmentObject private var app: AppEnvironment
    @Binding var selectedSection: AppSection?

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Button {
                Task { await app.launchFromEmulatorIcon() }
            } label: {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(hex: 0x1EEA8A))
                        Image(systemName: "gamecontroller.fill")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundStyle(Color.black)
                    }
                    .frame(width: 42, height: 42)

                    VStack(alignment: .leading, spacing: 2) {
                        Text("CleanDroid")
                            .font(.headline.weight(.bold))
                        Text("Click to launch")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .buttonStyle(.plain)
            .help("Start the emulator like a commercial emulator app")
            .padding(.top, 12)
            .padding(.horizontal, 14)

            List(AppSection.allCases, selection: $selectedSection) { section in
                Label(section.rawValue, systemImage: section.systemImage)
                    .tag(Optional(section))
                    .padding(.vertical, 4)
            }
            .listStyle(.sidebar)

            VStack(alignment: .leading, spacing: 10) {
                StatusBadge(title: app.emulatorState.title, color: app.emulatorState.color)

                Text(app.statusMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                if app.isBusy {
                    ProgressView()
                        .controlSize(.small)
                        .tint(Color(hex: 0x1EEA8A))
                }
            }
            .padding(14)
        }
        .background(VisualEffectBackground(material: .sidebar, blendingMode: .behindWindow))
    }
}
