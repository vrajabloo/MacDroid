//
// SetupWizardView.swift
// MacDroid
//
// First-run setup for beginner users. It checks the Android SDK pieces MacDroid
// needs and offers one-click repair actions where the official SDK allows it.

import SwiftUI

struct SetupWizardView: View {
    @EnvironmentObject private var app: AppEnvironment
    @Binding var selectedSection: AppSection?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header
                readinessPanel
                quickActions
                finishPanel
            }
            .padding(28)
            .frame(maxWidth: 1040, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }

    private var header: some View {
        ViewThatFits(in: .horizontal) {
            HStack(alignment: .center, spacing: 18) {
                titleBlock
                Spacer()
                StatusBadge(
                    title: app.settings.setupWizardCompleted ? "Complete" : "Setup Needed",
                    color: app.settings.setupWizardCompleted ? Color(hex: 0x1EEA8A) : Color(hex: 0xFFD166)
                )
            }

            VStack(alignment: .leading, spacing: 12) {
                titleBlock
                StatusBadge(
                    title: app.settings.setupWizardCompleted ? "Complete" : "Setup Needed",
                    color: app.settings.setupWizardCompleted ? Color(hex: 0x1EEA8A) : Color(hex: 0xFFD166)
                )
            }
        }
    }

    private var titleBlock: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Setup Wizard")
                .font(.largeTitle.weight(.black))
            Text("Get Android SDK, ADB, emulator, AVD, and Play Store support ready for MacDroid.")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var readinessPanel: some View {
        PanelView {
            VStack(alignment: .leading, spacing: 14) {
                Label("Readiness", systemImage: "checklist.checked")
                    .font(.title3.weight(.bold))

                setupRow("Android SDK", isReady: app.sdkInfo.sdkRoot != nil, detail: app.sdkInfo.sdkRoot?.path ?? "Not detected")
                setupRow("ADB", isReady: app.sdkInfo.hasADB, detail: app.sdkInfo.adbURL?.path ?? "Missing")
                setupRow("Emulator", isReady: app.sdkInfo.hasEmulator, detail: app.sdkInfo.emulatorURL?.path ?? "Missing")
                setupRow("AVD Manager", isReady: app.sdkInfo.canManageAVDs, detail: app.sdkInfo.avdManagerURL?.path ?? "Missing")
                setupRow("Google Play ARM64 image", isReady: app.sdkInfo.playStoreImageAvailable, detail: app.sdkInfo.playStoreImageAvailable ? "Detected" : "Needed for Play Store")
                setupRow("Gaming AVD", isReady: !app.avds.isEmpty, detail: app.avds.isEmpty ? "Create MacDroid AVD" : "\(app.avds.count) AVD profile\(app.avds.count == 1 ? "" : "s") found")
            }
        }
    }

    private func setupRow(_ title: String, isReady: Bool, detail: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: isReady ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(isReady ? Color(hex: 0x1EEA8A) : Color(hex: 0xFFD166))
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
                    .lineLimit(2)
                    .truncationMode(.middle)
            }

            Spacer()
        }
        .padding(10)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 8))
    }

    private var quickActions: some View {
        LazyVGrid(columns: adaptiveColumns, spacing: 18) {
            actionCard(
                title: "Scan",
                icon: "magnifyingglass",
                message: "Search this Mac again for Android SDK tools.",
                buttonTitle: "Scan Again",
                disabled: app.isBusy
            ) {
                Task { await app.refreshAll() }
            }

            actionCard(
                title: "Fix Automatically",
                icon: "wand.and.stars",
                message: "Create the recommended MacDroid AVD and install the Google Play ARM64 image when SDK Manager allows it.",
                buttonTitle: "Run Setup Fix",
                disabled: app.isBusy || !app.sdkInfo.canManageAVDs
            ) {
                Task { await app.runSetupAutoFix() }
            }

            actionCard(
                title: "Launch",
                icon: "play.fill",
                message: "Start the selected Android emulator after setup is ready.",
                buttonTitle: "Start Emulator",
                disabled: app.isBusy || !app.sdkInfo.hasEmulator
            ) {
                Task { await app.startEmulator() }
            }
        }
    }

    private func actionCard(
        title: String,
        icon: String,
        message: String,
        buttonTitle: String,
        disabled: Bool,
        action: @escaping () -> Void
    ) -> some View {
        PanelView {
            VStack(alignment: .leading, spacing: 14) {
                Label(title, systemImage: icon)
                    .font(.title3.weight(.bold))

                Text(message)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)

                Button(action: action) {
                    Text(buttonTitle)
                        .frame(maxWidth: .infinity)
                }
                .disabled(disabled)
            }
        }
    }

    private var finishPanel: some View {
        PanelView {
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 16) {
                    finishText
                    Spacer()
                    finishButtons
                }

                VStack(alignment: .leading, spacing: 14) {
                    finishText
                    finishButtons
                }
            }
        }
    }

    private var finishText: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Ready to play")
                .font(.title3.weight(.bold))
            Text("Finish setup when the core tools are detected. You can reopen this screen any time from the sidebar.")
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var finishButtons: some View {
        HStack(spacing: 10) {
            Button {
                selectedSection = .health
            } label: {
                Label("Health", systemImage: "heart.text.square.fill")
            }

            Button {
                app.completeSetupWizard()
                selectedSection = .home
            } label: {
                Label("Finish Setup", systemImage: "checkmark.circle.fill")
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(hex: 0x1EEA8A))
            .disabled(!app.sdkInfo.isReadyForGaming)
        }
    }

    private var adaptiveColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 260, maximum: 420), spacing: 18, alignment: .top)]
    }
}
