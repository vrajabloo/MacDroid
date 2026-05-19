//
// AppPaths.swift
// CleanDroid Gaming
//
// Centralizes local folders used by the app. Keeping paths in one place makes it
// easier for beginner developers to understand where settings and profiles live.

import Foundation

enum AppPaths {
    static var applicationSupportDirectory: URL {
        let base = FileManager.default.urls(
            for: .applicationSupportDirectory,
            in: .userDomainMask
        ).first ?? FileManager.default.homeDirectoryForCurrentUser

        return base.appendingPathComponent("CleanDroid Gaming", isDirectory: true)
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

    static var screenshotsDirectory: URL {
        applicationSupportDirectory.appendingPathComponent("Screenshots", isDirectory: true)
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
}
