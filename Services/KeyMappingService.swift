//
// KeyMappingService.swift
// CleanDroid Gaming
//
// Saves and loads per-game input mapping profiles. The MVP stores the design and
// data now; future builds can execute mappings through ADB input or overlays.

import Foundation

@MainActor
final class KeyMappingService {
    private let logService: LogService

    init(logService: LogService) {
        self.logService = logService
    }

    func loadProfiles() -> [KeyMappingProfile] {
        do {
            return try FileStorage.load([KeyMappingProfile].self, from: AppPaths.keyMappingsURL) ?? []
        } catch {
            logService.log("Could not read key mapping profiles: \(error.localizedDescription)", level: .warning)
            return []
        }
    }

    func saveProfiles(_ profiles: [KeyMappingProfile]) {
        do {
            try FileStorage.save(profiles, to: AppPaths.keyMappingsURL)
            logService.log("Key mapping profiles saved.", level: .success)
        } catch {
            logService.log("Could not save key mapping profiles: \(error.localizedDescription)", level: .error)
        }
    }

    func profile(for app: AndroidApp, profiles: [KeyMappingProfile]) -> KeyMappingProfile {
        profiles.first(where: { $0.packageName == app.packageName }) ?? KeyMappingProfile.empty(for: app)
    }
}

