//
// AppPaths.swift
// MacDroid
//
// Centralizes local folders used by the app. Keeping paths in one place makes it
// easier for beginner developers to understand where settings and profiles live.

import Foundation

enum AppPaths {
    static var applicationSupportDirectory: URL {
        let base = applicationSupportBaseDirectory
        let currentDirectory = base.appendingPathComponent("MacDroid", isDirectory: true)

        migrateLegacySupportDirectoryIfNeeded(
            from: base.appendingPathComponent("CleanDroid Gaming", isDirectory: true),
            to: currentDirectory
        )

        return currentDirectory
    }

    static var settingsURL: URL {
        applicationSupportDirectory.appendingPathComponent("settings.json")
    }

    static var libraryURL: URL {
        applicationSupportDirectory.appendingPathComponent("game-library.json")
    }

    static var keyMappingsURL: URL {
        applicationSupportDirectory.appendingPathComponent("key-mappings.json")
    }

    static var gameProfilesURL: URL {
        applicationSupportDirectory.appendingPathComponent("game-profiles.json")
    }

    static var screenshotsDirectory: URL {
        applicationSupportDirectory.appendingPathComponent("Screenshots", isDirectory: true)
    }

    static var exportsDirectory: URL {
        applicationSupportDirectory.appendingPathComponent("Exports", isDirectory: true)
    }

    static func ensureApplicationSupportDirectory() throws {
        try FileManager.default.createDirectory(
            at: applicationSupportDirectory,
            withIntermediateDirectories: true
        )
    }

    static func ensureScreenshotsDirectory() throws {
        try FileManager.default.createDirectory(
            at: screenshotsDirectory,
            withIntermediateDirectories: true
        )
    }

    static func ensureExportsDirectory() throws {
        try FileManager.default.createDirectory(
            at: exportsDirectory,
            withIntermediateDirectories: true
        )
    }

    private static var applicationSupportBaseDirectory: URL {
        FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? FileManager.default.homeDirectoryForCurrentUser
    }

    private static func migrateLegacySupportDirectoryIfNeeded(from legacyURL: URL, to currentURL: URL) {
        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: legacyURL.path),
              !fileManager.fileExists(atPath: currentURL.path) else {
            return
        }

        // Older builds stored JSON files under "CleanDroid Gaming".
        // Copying that folder once lets existing users keep settings and profiles after the rename.
        try? fileManager.copyItem(at: legacyURL, to: currentURL)
    }
}
