//
// GameProfileService.swift
// MacDroid
//
// Persists per-game launch profiles as JSON. Keeping this separate from the UI
// makes it easy to later add import/export or cloud sync.

import Foundation

@MainActor
final class GameProfileService {
    private let logService: LogService

    init(logService: LogService) {
        self.logService = logService
    }

    func loadProfiles() -> [GameProfile] {
        do {
            return try FileStorage.load([GameProfile].self, from: AppPaths.gameProfilesURL) ?? []
        } catch {
            logService.log("Could not read game profiles: \(error.localizedDescription)", level: .warning)
            return []
        }
    }

    func saveProfiles(_ profiles: [GameProfile]) {
        do {
            try FileStorage.save(profiles, to: AppPaths.gameProfilesURL)
            logService.log("Game profiles saved.", level: .success)
        } catch {
            logService.log("Could not save game profiles: \(error.localizedDescription)", level: .error)
        }
    }
}
