//
// GameProfile.swift
// MacDroid
//
// Stores per-game launch preferences. These profiles let MacDroid remember the
// best orientation, performance, display, and input setup for each Android game.

import Foundation

struct GameProfile: Identifiable, Codable, Hashable {
    var id: UUID
    var packageName: String
    var displayName: String
    var orientationPreference: GameOrientationPreference
    var performanceProfile: PerformanceProfile
    var resolutionPreset: ResolutionPreset
    var dpiPreset: DPIPreset
    var autoOpenKeyMappingOverlay: Bool
    var keyMappingProfileID: UUID?
    var createdAt: Date
    var updatedAt: Date

    static func `default`(for app: AndroidApp, keyMappingProfileID: UUID? = nil) -> GameProfile {
        GameProfile(
            id: UUID(),
            packageName: app.packageName,
            displayName: app.name,
            orientationPreference: .landscape,
            performanceProfile: .performance,
            resolutionPreset: .p1080,
            dpiPreset: .dpi320,
            autoOpenKeyMappingOverlay: false,
            keyMappingProfileID: keyMappingProfileID,
            createdAt: .now,
            updatedAt: .now
        )
    }
}

enum GameOrientationPreference: String, Codable, CaseIterable, Identifiable {
    case system = "System"
    case portrait = "Portrait"
    case landscape = "Landscape"
    case forceLandscape = "Force Landscape"
    case reset = "Reset"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .system: return "iphone.gen3"
        case .portrait: return "rectangle.portrait.rotate"
        case .landscape: return "rectangle.landscape.rotate"
        case .forceLandscape: return "lock.rotation"
        case .reset: return "arrow.counterclockwise"
        }
    }

    var adbRotation: Int? {
        switch self {
        case .landscape, .forceLandscape:
            return 0
        case .portrait:
            return 1
        case .system, .reset:
            return nil
        }
    }

    var summary: String {
        switch self {
        case .system: return "Leaves Android orientation as-is."
        case .portrait: return "Locks the app to a portrait-style phone rotation."
        case .landscape: return "Uses the emulator's normal wide gaming layout."
        case .forceLandscape: return "Repairs orientation locks, then keeps the game wide."
        case .reset: return "Returns Android rotation handling to automatic behavior."
        }
    }
}
