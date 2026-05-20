//
// SidebarView.swift
// MacDroid
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
                        Text("MacDroid")
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

            VStack(spacing: 6) {
                ForEach(AppSection.allCases) { section in
                    sidebarButton(for: section)
                }
            }
            .padding(.horizontal, 12)

            Spacer(minLength: 16)

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
        .frame(maxHeight: .infinity, alignment: .top)
        .background(VisualEffectBackground(material: .sidebar, blendingMode: .behindWindow))
    }

    private func sidebarButton(for section: AppSection) -> some View {
        let isSelected = selectedSection == section

        return Button {
            selectedSection = section
        } label: {
            HStack(spacing: 10) {
                Image(systemName: section.systemImage)
                    .font(.system(size: 14, weight: .semibold))
                    .frame(width: 20)

                Text(section.rawValue)
                    .font(.callout.weight(isSelected ? .semibold : .regular))

                Spacer()
            }
            .foregroundStyle(isSelected ? Color.white : Color.white.opacity(0.68))
            .padding(.horizontal, 10)
            .frame(height: 36)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.white.opacity(0.13) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color(hex: 0x1EEA8A, opacity: 0.32) : Color.clear, lineWidth: 1)
            )
            .contentShape(RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .help("Open \(section.rawValue)")
    }
}
