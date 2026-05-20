//
// KeyMappingProfile.swift
// MacDroid
//
// Defines the data model for future keyboard, mouse, and gamepad mapping.
// The MVP stores profiles now; direct injection can later use ADB input commands
// or a native overlay once the right technique is chosen for each Android game.

import Foundation

struct KeyMappingProfile: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var packageName: String
    var mappings: [InputMapping]
    var inputBridgeMode: InputBridgeMode
    var gamepadEnabled: Bool
    var createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case packageName
        case mappings
        case inputBridgeMode
        case gamepadEnabled
        case createdAt
        case updatedAt
    }

    init(
        id: UUID,
        name: String,
        packageName: String,
        mappings: [InputMapping],
        inputBridgeMode: InputBridgeMode = .adbTap,
        gamepadEnabled: Bool = false,
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.name = name
        self.packageName = packageName
        self.mappings = mappings
        self.inputBridgeMode = inputBridgeMode
        self.gamepadEnabled = gamepadEnabled
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.name = try container.decodeIfPresent(String.self, forKey: .name) ?? "Controls"
        self.packageName = try container.decode(String.self, forKey: .packageName)
        self.mappings = try container.decodeIfPresent([InputMapping].self, forKey: .mappings) ?? []
        self.inputBridgeMode = try container.decodeIfPresent(InputBridgeMode.self, forKey: .inputBridgeMode) ?? .adbTap
        self.gamepadEnabled = try container.decodeIfPresent(Bool.self, forKey: .gamepadEnabled) ?? false
        self.createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? .now
        self.updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? .now
    }

    static func empty(for app: AndroidApp) -> KeyMappingProfile {
        KeyMappingProfile(
            id: UUID(),
            name: "\(app.name) Controls",
            packageName: app.packageName,
            mappings: [],
            createdAt: .now,
            updatedAt: .now
        )
    }
}

struct InputMapping: Identifiable, Codable, Hashable {
    var id: UUID
    var inputType: InputMappingType
    var trigger: String
    var tapPoint: NormalizedPoint
    var note: String

    static func sample(trigger: String, x: Double, y: Double) -> InputMapping {
        InputMapping(
            id: UUID(),
            inputType: .keyboard,
            trigger: trigger,
            tapPoint: NormalizedPoint(x: x, y: y),
            note: "Tap at \(Int(x * 100))%, \(Int(y * 100))%"
        )
    }
}

enum InputMappingType: String, Codable, CaseIterable, Identifiable {
    case keyboard = "Keyboard"
    case mouse = "Mouse"
    case gamepad = "Gamepad"

    var id: String { rawValue }
}

enum InputBridgeMode: String, Codable, CaseIterable, Identifiable {
    case adbTap = "ADB Tap"
    case overlayPlanned = "Overlay Planned"
    case gamepadPlanned = "Gamepad Planned"

    var id: String { rawValue }

    var summary: String {
        switch self {
        case .adbTap: return "Works now for manual tap tests."
        case .overlayPlanned: return "Prepared for real-time keyboard and mouse overlay injection."
        case .gamepadPlanned: return "Prepared for native controller event bridging."
        }
    }
}

struct NormalizedPoint: Codable, Hashable {
    var x: Double
    var y: Double
}
