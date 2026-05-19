//
// LibraryViewModel.swift
// CleanDroid Gaming
//
// Stores library screen UI state such as search text. The actual Android app
// data remains in AppEnvironment so every screen sees the same source of truth.

import Foundation

@MainActor
final class LibraryViewModel: ObservableObject {
    @Published var searchText = ""
    @Published var filter: LibraryFilter = .installed

    func filteredGames(_ games: [AndroidApp]) -> [AndroidApp] {
        let scopedGames: [AndroidApp]
        switch filter {
        case .installed:
            scopedGames = games
        case .recent:
            scopedGames = games
                .filter { $0.lastPlayed != nil }
                .sorted { ($0.lastPlayed ?? .distantPast) > ($1.lastPlayed ?? .distantPast) }
        case .favorites:
            scopedGames = games.filter(\.isFavorite)
        }

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            return scopedGames
        }

        return scopedGames.filter {
            $0.name.localizedCaseInsensitiveContains(query)
                || $0.packageName.localizedCaseInsensitiveContains(query)
        }
    }
}

enum LibraryFilter: String, CaseIterable, Identifiable {
    case installed = "Installed"
    case recent = "Recent"
    case favorites = "Favorites"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .installed: return "square.grid.2x2.fill"
        case .recent: return "clock.fill"
        case .favorites: return "star.fill"
        }
    }
}
