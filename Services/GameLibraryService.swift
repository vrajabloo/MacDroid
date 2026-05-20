//
// GameLibraryService.swift
// MacDroid
//
// Maintains the game library shown in the UI. Live app data comes from ADB, and
// local JSON preserves friendly metadata such as last-played timestamps.

import Foundation

@MainActor
final class GameLibraryService {
    private let logService: LogService

    init(logService: LogService) {
        self.logService = logService
    }

    func loadCachedLibrary() -> [AndroidApp] {
        do {
            return try FileStorage.load([AndroidApp].self, from: AppPaths.libraryURL) ?? []
        } catch {
            logService.log("Could not read saved game library: \(error.localizedDescription)", level: .warning)
            return []
        }
    }

    func saveLibrary(_ apps: [AndroidApp]) {
        do {
            try FileStorage.save(apps, to: AppPaths.libraryURL)
        } catch {
            logService.log("Could not save game library: \(error.localizedDescription)", level: .warning)
        }
    }

    func merge(discoveredApps: [AndroidApp], cachedApps: [AndroidApp]) -> [AndroidApp] {
        let cachedByPackage = Dictionary(uniqueKeysWithValues: cachedApps.map { ($0.packageName, $0) })

        let merged = discoveredApps.map { discovered -> AndroidApp in
            guard let cached = cachedByPackage[discovered.packageName] else {
                return discovered
            }

            var app = discovered
            app.name = cached.name.isEmpty ? discovered.name : cached.name
            app.iconData = cached.iconData
            app.lastPlayed = cached.lastPlayed
            app.installedAt = cached.installedAt ?? discovered.installedAt
            app.versionName = discovered.versionName ?? cached.versionName
            app.sourceDir = discovered.sourceDir ?? cached.sourceDir
            app.isFavorite = cached.isFavorite
            return app
        }

        saveLibrary(merged)
        return merged
    }

    func markPlayed(_ app: AndroidApp, in apps: [AndroidApp]) -> [AndroidApp] {
        var updated = apps
        guard let index = updated.firstIndex(where: { $0.packageName == app.packageName }) else {
            return apps
        }

        updated[index].lastPlayed = .now
        saveLibrary(updated)
        return updated
    }

    func toggleFavorite(_ app: AndroidApp, in apps: [AndroidApp]) -> [AndroidApp] {
        var updated = apps
        guard let index = updated.firstIndex(where: { $0.packageName == app.packageName }) else {
            return apps
        }

        updated[index].isFavorite.toggle()
        saveLibrary(updated)
        return updated
    }
}
