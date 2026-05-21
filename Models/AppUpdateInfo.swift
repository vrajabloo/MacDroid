//
// AppUpdateInfo.swift
// MacDroid
//
// Result returned by the GitHub Release update checker.

import Foundation

struct AppUpdateInfo: Codable, Equatable {
    var currentVersion: String
    var latestVersion: String?
    var releaseName: String?
    var releaseURL: URL?
    var releaseNotes: String?
    var checkedAt: Date?
    var isUpdateAvailable: Bool
    var message: String

    static let idle = AppUpdateInfo(
        currentVersion: AppVersion.current,
        latestVersion: nil,
        releaseName: nil,
        releaseURL: nil,
        releaseNotes: nil,
        checkedAt: nil,
        isUpdateAvailable: false,
        message: "No update check has run yet."
    )
}
