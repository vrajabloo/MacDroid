//
// AndroidApp.swift
// MacDroid
//
// A small model that represents an Android app or game discovered through ADB.
// The MVP uses package names from `adb shell pm list packages -3`; later versions
// can enrich this model with icons and artwork extracted from APK metadata.

import Foundation
import SwiftUI

struct AndroidApp: Identifiable, Codable, Hashable {
    var id: String { packageName }

    var name: String
    var packageName: String
    var iconData: Data?
    var lastPlayed: Date?
    var installedAt: Date?
    var versionName: String? = nil
    var sourceDir: String? = nil
    var artworkSeed: Int
    var isFavorite: Bool

    enum CodingKeys: String, CodingKey {
        case name
        case packageName
        case iconData
        case lastPlayed
        case installedAt
        case versionName
        case sourceDir
        case artworkSeed
        case isFavorite
    }

    init(
        name: String,
        packageName: String,
        iconData: Data?,
        lastPlayed: Date?,
        installedAt: Date?,
        versionName: String? = nil,
        sourceDir: String? = nil,
        artworkSeed: Int,
        isFavorite: Bool = false
    ) {
        self.name = name
        self.packageName = packageName
        self.iconData = iconData
        self.lastPlayed = lastPlayed
        self.installedAt = installedAt
        self.versionName = versionName
        self.sourceDir = sourceDir
        self.artworkSeed = artworkSeed
        self.isFavorite = isFavorite
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Unknown App"
        self.packageName = try container.decode(String.self, forKey: .packageName)
        self.iconData = try container.decodeIfPresent(Data.self, forKey: .iconData)
        self.lastPlayed = try container.decodeIfPresent(Date.self, forKey: .lastPlayed)
        self.installedAt = try container.decodeIfPresent(Date.self, forKey: .installedAt)
        self.versionName = try container.decodeIfPresent(String.self, forKey: .versionName)
        self.sourceDir = try container.decodeIfPresent(String.self, forKey: .sourceDir)
        self.artworkSeed = try container.decodeIfPresent(Int.self, forKey: .artworkSeed) ?? Self.stableSeed(from: packageName)
        self.isFavorite = try container.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false
    }

    var displayInitial: String {
        let firstCharacter = name.trimmingCharacters(in: .whitespacesAndNewlines).first
        return firstCharacter.map { String($0).uppercased() } ?? "A"
    }

    var artworkGradient: LinearGradient {
        let palettes: [[Color]] = [
            [Color(hex: 0x1EEA8A), Color(hex: 0x0A7CFF)],
            [Color(hex: 0xA6FF4D), Color(hex: 0x00C2FF)],
            [Color(hex: 0x00E5A8), Color(hex: 0x7D5CFF)],
            [Color(hex: 0x39FF88), Color(hex: 0x101820)],
            [Color(hex: 0x2AF598), Color(hex: 0x009EFD)]
        ]

        let colors = palettes[abs(artworkSeed) % palettes.count]
        return LinearGradient(
            colors: colors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static func stableSeed(from text: String) -> Int {
        text.unicodeScalars.reduce(0) { partialResult, scalar in
            partialResult &* 31 &+ Int(scalar.value)
        }
    }
}

extension AndroidApp {
    static let samples: [AndroidApp] = [
        AndroidApp(
            name: "Android Racing",
            packageName: "com.example.racing",
            iconData: nil,
            lastPlayed: .now.addingTimeInterval(-3600),
            installedAt: .now.addingTimeInterval(-86400),
            versionName: "1.0",
            sourceDir: nil,
            artworkSeed: 1
        ),
        AndroidApp(
            name: "Galaxy Quest",
            packageName: "com.example.galaxy",
            iconData: nil,
            lastPlayed: .now.addingTimeInterval(-7200),
            installedAt: .now.addingTimeInterval(-172800),
            versionName: "2.1",
            sourceDir: nil,
            artworkSeed: 2
        )
    ]
}
