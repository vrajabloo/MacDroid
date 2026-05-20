//
// HomeViewModel.swift
// MacDroid
//
// Presentation helpers for the home dashboard. Keeping these values here keeps
// the SwiftUI view focused on layout instead of app-state decisions.

import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    func primaryActionTitle(for state: EmulatorState) -> String {
        switch state {
        case .running:
            return "Play"
        case .booting:
            return "Booting..."
        case .stopped, .unknown, .error:
            return "Start Emulator"
        }
    }

    func recentGames(from games: [AndroidApp]) -> [AndroidApp] {
        games
            .filter { $0.lastPlayed != nil }
            .sorted { ($0.lastPlayed ?? .distantPast) > ($1.lastPlayed ?? .distantPast) }
            .prefix(4)
            .map { $0 }
    }
}

