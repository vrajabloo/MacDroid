//
// UpdateCheckerService.swift
// MacDroid
//
// Checks the public GitHub Releases API for the newest MacDroid release. The app
// only informs the user; it does not install updates automatically.

import Foundation

@MainActor
final class UpdateCheckerService {
    private struct GitHubRelease: Decodable {
        var tagName: String
        var name: String?
        var htmlURL: URL?
        var body: String?

        enum CodingKeys: String, CodingKey {
            case tagName = "tag_name"
            case name
            case htmlURL = "html_url"
            case body
        }
    }

    private let logService: LogService

    init(logService: LogService) {
        self.logService = logService
    }

    func checkForUpdates(
        owner: String = AppVersion.repositoryOwner,
        repository: String = AppVersion.repositoryName,
        currentVersion: String = AppVersion.current
    ) async -> AppUpdateInfo {
        guard let url = URL(string: "https://api.github.com/repos/\(owner)/\(repository)/releases/latest") else {
            return failure("The update URL is invalid.", currentVersion: currentVersion)
        }

        logService.log("Checking GitHub Releases for MacDroid updates.", level: .info)

        do {
            var request = URLRequest(url: url)
            request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
            request.setValue("MacDroid/\(currentVersion)", forHTTPHeaderField: "User-Agent")

            let (data, response) = try await URLSession.shared.data(for: request)

            if let httpResponse = response as? HTTPURLResponse,
               httpResponse.statusCode == 404 {
                return AppUpdateInfo(
                    currentVersion: currentVersion,
                    latestVersion: nil,
                    releaseName: nil,
                    releaseURL: URL(string: "https://github.com/\(owner)/\(repository)/releases"),
                    releaseNotes: nil,
                    checkedAt: .now,
                    isUpdateAvailable: false,
                    message: "No GitHub Release has been published yet."
                )
            }

            let release = try JSONDecoder().decode(GitHubRelease.self, from: data)
            let latestVersion = normalizedVersion(release.tagName)
            let hasUpdate = compare(latestVersion, isNewerThan: currentVersion)

            let info = AppUpdateInfo(
                currentVersion: currentVersion,
                latestVersion: release.tagName,
                releaseName: release.name,
                releaseURL: release.htmlURL,
                releaseNotes: release.body,
                checkedAt: .now,
                isUpdateAvailable: hasUpdate,
                message: hasUpdate ? "Version \(release.tagName) is available." : "MacDroid is up to date."
            )

            logService.log(info.message, level: hasUpdate ? .warning : .success)
            return info
        } catch {
            return failure("Could not check updates: \(error.localizedDescription)", currentVersion: currentVersion)
        }
    }

    private func failure(_ message: String, currentVersion: String) -> AppUpdateInfo {
        logService.log(message, level: .warning)
        return AppUpdateInfo(
            currentVersion: currentVersion,
            latestVersion: nil,
            releaseName: nil,
            releaseURL: URL(string: "https://github.com/\(AppVersion.repositoryOwner)/\(AppVersion.repositoryName)/releases"),
            releaseNotes: nil,
            checkedAt: .now,
            isUpdateAvailable: false,
            message: message
        )
    }

    private func normalizedVersion(_ text: String) -> String {
        text.trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
    }

    private func compare(_ candidate: String, isNewerThan current: String) -> Bool {
        let candidateParts = normalizedVersion(candidate).split(separator: ".").map { Int($0) ?? 0 }
        let currentParts = normalizedVersion(current).split(separator: ".").map { Int($0) ?? 0 }
        let maxCount = max(candidateParts.count, currentParts.count)

        for index in 0..<maxCount {
            let candidateValue = index < candidateParts.count ? candidateParts[index] : 0
            let currentValue = index < currentParts.count ? currentParts[index] : 0

            if candidateValue > currentValue {
                return true
            }

            if candidateValue < currentValue {
                return false
            }
        }

        return false
    }
}
