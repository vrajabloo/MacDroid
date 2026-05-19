//
// LogsViewModel.swift
// CleanDroid Gaming
//
// Adds search and severity filtering to the raw LogService entries.

import Foundation

@MainActor
final class LogsViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var selectedLevel: LogLevel?

    func filteredEntries(_ entries: [LogEntry]) -> [LogEntry] {
        entries.filter { entry in
            let matchesLevel = selectedLevel == nil || entry.level == selectedLevel
            let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
            let matchesSearch = query.isEmpty
                || entry.message.localizedCaseInsensitiveContains(query)
                || (entry.command?.localizedCaseInsensitiveContains(query) ?? false)

            return matchesLevel && matchesSearch
        }
    }
}

