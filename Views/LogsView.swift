//
// LogsView.swift
// CleanDroid Gaming
//
// Troubleshooting screen for command logs, startup errors, ADB output, and APK
// install failures. Messages are written for beginners, with raw commands shown.

import SwiftUI

struct LogsView: View {
    @EnvironmentObject private var app: AppEnvironment
    @StateObject private var viewModel = LogsViewModel()

    private var entries: [LogEntry] {
        viewModel.filteredEntries(app.logService.entries)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header
            filters
            logcatPanel

            if entries.isEmpty {
                PanelView {
                    EmptyStateView(
                        systemImage: "terminal",
                        title: "No matching logs",
                        message: "Run an emulator action or clear filters to see logs."
                    )
                    .frame(maxWidth: .infinity, minHeight: 360)
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(entries) { entry in
                            LogEntryRow(entry: entry)
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
        }
        .padding(28)
    }

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Logs")
                    .font(.largeTitle.weight(.black))
                Text("Beginner-friendly emulator, ADB, and installer history.")
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button(role: .destructive) {
                app.logService.clear()
            } label: {
                Label("Clear", systemImage: "trash")
            }
        }
    }

    private var filters: some View {
        HStack(spacing: 12) {
            TextField("Search logs", text: $viewModel.searchText)
                .textFieldStyle(.roundedBorder)
                .frame(width: 280)

            Button("All") {
                viewModel.selectedLevel = nil
            }
            .buttonStyle(.borderedProminent)
            .tint(viewModel.selectedLevel == nil ? Color(hex: 0x1EEA8A) : Color.gray)

            ForEach(LogLevel.allCases, id: \.self) { level in
                Button(level.title) {
                    viewModel.selectedLevel = level
                }
                .buttonStyle(.bordered)
                .tint(viewModel.selectedLevel == level ? level.color : Color.gray)
            }
        }
    }

    private var logcatPanel: some View {
        PanelView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Android logcat", systemImage: "doc.text.magnifyingglass")
                        .font(.headline)
                    Spacer()
                    Button {
                        Task { await app.loadRecentLogcat() }
                    } label: {
                        Label("Load Recent", systemImage: "arrow.down.doc.fill")
                    }
                    .disabled(app.emulatorState == .stopped || app.emulatorState == .unknown)
                }

                if app.recentLogcatText.isEmpty {
                    Text("No logcat loaded yet.")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                } else {
                    ScrollView {
                        Text(app.recentLogcatText)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(Color(hex: 0xD8FFE8))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 180)
                    .padding(10)
                    .background(Color.black.opacity(0.34), in: RoundedRectangle(cornerRadius: 6))
                }
            }
        }
    }
}

private struct LogEntryRow: View {
    var entry: LogEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                StatusBadge(title: entry.level.title, color: entry.level.color)
                Text(entry.date.formatted(date: .abbreviated, time: .standard))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            Text(entry.message)
                .font(.callout)
                .fixedSize(horizontal: false, vertical: true)

            if let command = entry.command {
                Text(command)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(Color(hex: 0xA6FF4D))
                    .textSelection(.enabled)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.black.opacity(0.34), in: RoundedRectangle(cornerRadius: 6))
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.055))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(entry.level.color.opacity(0.18), lineWidth: 1)
                )
        )
    }
}
