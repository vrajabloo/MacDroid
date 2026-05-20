//
// APKInstallerView.swift
// MacDroid
//
// Dedicated APK installer screen with drag-and-drop and file browsing. Both
// paths install through ADB so the official emulator receives the APK.

import SwiftUI
import UniformTypeIdentifiers

struct APKInstallerView: View {
    @EnvironmentObject private var app: AppEnvironment
    @State private var isShowingImporter = false

    private var apkType: UTType {
        UTType(filenameExtension: "apk") ?? .data
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 22) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("APK Installer")
                        .font(.largeTitle.weight(.black))
                    Text("Install Android games into the running emulator.")
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button {
                    isShowingImporter = true
                } label: {
                    Label("Browse APK", systemImage: "folder.fill")
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: 0x1EEA8A))
            }

            APKDropZone()

            PanelView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Installer checklist")
                        .font(.title3.weight(.bold))

                    checklistRow(app.sdkInfo.hasADB, "ADB detected")
                    checklistRow(app.emulatorState == .running, "Emulator running")
                    checklistRow(true, "APK will be installed with adb install -r")

                    Text("If install fails, open Logs for the exact ADB output and a beginner-friendly explanation.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()
        }
        .padding(28)
        .fileImporter(
            isPresented: $isShowingImporter,
            allowedContentTypes: [apkType],
            allowsMultipleSelection: false
        ) { result in
            guard case .success(let urls) = result, let url = urls.first else {
                return
            }

            Task {
                await app.installAPK(from: url)
            }
        }
    }

    private func checklistRow(_ isComplete: Bool, _ title: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: isComplete ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isComplete ? Color(hex: 0x1EEA8A) : Color.secondary)
            Text(title)
                .foregroundStyle(isComplete ? .primary : .secondary)
        }
    }
}

