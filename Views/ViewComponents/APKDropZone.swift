//
// APKDropZone.swift
// CleanDroid Gaming
//
// Drag-and-drop installer target. It accepts file URLs and forwards .apk paths to
// the APKInstallerService through AppEnvironment.

import SwiftUI
import UniformTypeIdentifiers

struct APKDropZone: View {
    @EnvironmentObject private var app: AppEnvironment
    @State private var isTargeted = false

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "arrow.down.app.fill")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(Color(hex: 0x1EEA8A))

            Text("Drop APK to install")
                .font(.title3.weight(.bold))

            Text("CleanDroid will run adb install -r against the active emulator.")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            if let progress = app.installProgress {
                ProgressView(value: progress)
                    .tint(Color(hex: 0x1EEA8A))
                    .frame(maxWidth: 260)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 220)
        .padding(22)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isTargeted ? Color(hex: 0x1EEA8A, opacity: 0.16) : Color.white.opacity(0.055))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(
                            isTargeted ? Color(hex: 0x1EEA8A) : Color.white.opacity(0.12),
                            style: StrokeStyle(lineWidth: 1.5, dash: [8, 6])
                        )
                )
        )
        .onDrop(of: [UTType.fileURL.identifier], isTargeted: $isTargeted) { providers in
            handleDrop(providers)
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else {
            return false
        }

        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
            let url: URL?

            if let data = item as? Data,
               let string = String(data: data, encoding: .utf8) {
                url = URL(string: string)
            } else {
                url = item as? URL
            }

            guard let url else {
                return
            }

            Task { @MainActor in
                await app.installAPK(from: url)
            }
        }

        return true
    }
}

