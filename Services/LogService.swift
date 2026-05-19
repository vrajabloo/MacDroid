//
// LogService.swift
// CleanDroid Gaming
//
// Keeps a user-friendly activity log for the Logs screen. Services write an
// explanation before each Android SDK command so users can learn what is going on.

import Foundation

@MainActor
final class LogService: ObservableObject {
    @Published private(set) var entries: [LogEntry] = []

    func log(_ message: String, level: LogLevel = .info, command: String? = nil) {
        let entry = LogEntry(
            id: UUID(),
            date: .now,
            level: level,
            message: message,
            command: command
        )

        entries.insert(entry, at: 0)

        if entries.count > 500 {
            entries.removeLast(entries.count - 500)
        }
    }

    func clear() {
        entries.removeAll()
    }
}

