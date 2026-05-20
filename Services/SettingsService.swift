//
// SettingsService.swift
// MacDroid
//
// Loads and saves gaming performance settings using Codable JSON. This keeps the
// preferences easy to inspect while the app is still in MVP form.

import Foundation

@MainActor
final class SettingsService {
    private let logService: LogService

    init(logService: LogService) {
        self.logService = logService
    }

    func loadSettings() -> GamingSettings {
        do {
            return try FileStorage.load(GamingSettings.self, from: AppPaths.settingsURL) ?? .default
        } catch {
            logService.log("Could not read settings, so defaults were loaded: \(error.localizedDescription)", level: .warning)
            return .default
        }
    }

    func saveSettings(_ settings: GamingSettings) {
        do {
            try FileStorage.save(settings, to: AppPaths.settingsURL)
            logService.log("Gaming settings saved.", level: .success)
        } catch {
            logService.log("Could not save settings: \(error.localizedDescription)", level: .error)
        }
    }
}

