//
// KeyMappingProfile.swift
// MacDroid
//
// Defines the data model for keyboard, mouse, and gamepad mapping profiles.
// MacDroid can execute basic tap, long-press, and swipe mappings through ADB now.

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
    var action: InputMappingAction
    var tapPoint: NormalizedPoint
    var secondaryPoint: NormalizedPoint?
    var durationMilliseconds: Int
    var isEnabled: Bool
    var repeatWhileHeld: Bool
    var note: String

    enum CodingKeys: String, CodingKey {
        case id
        case inputType
        case trigger
        case action
        case tapPoint
        case secondaryPoint
        case durationMilliseconds
        case isEnabled
        case repeatWhileHeld
        case note
    }

    init(
        id: UUID = UUID(),
        inputType: InputMappingType,
        trigger: String,
        action: InputMappingAction = .tap,
        tapPoint: NormalizedPoint,
        secondaryPoint: NormalizedPoint? = nil,
        durationMilliseconds: Int = 120,
        isEnabled: Bool = true,
        repeatWhileHeld: Bool = false,
        note: String
    ) {
        self.id = id
        self.inputType = inputType
        self.trigger = trigger
        self.action = action
        self.tapPoint = tapPoint
        self.secondaryPoint = secondaryPoint
        self.durationMilliseconds = durationMilliseconds
        self.isEnabled = isEnabled
        self.repeatWhileHeld = repeatWhileHeld
        self.note = note
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        self.inputType = try container.decodeIfPresent(InputMappingType.self, forKey: .inputType) ?? .keyboard
        self.trigger = try container.decodeIfPresent(String.self, forKey: .trigger) ?? "Space"
        self.action = try container.decodeIfPresent(InputMappingAction.self, forKey: .action) ?? .tap
        self.tapPoint = try container.decodeIfPresent(NormalizedPoint.self, forKey: .tapPoint) ?? NormalizedPoint(x: 0.5, y: 0.5)
        self.secondaryPoint = try container.decodeIfPresent(NormalizedPoint.self, forKey: .secondaryPoint)
        self.durationMilliseconds = try container.decodeIfPresent(Int.self, forKey: .durationMilliseconds) ?? 120
        self.isEnabled = try container.decodeIfPresent(Bool.self, forKey: .isEnabled) ?? true
        self.repeatWhileHeld = try container.decodeIfPresent(Bool.self, forKey: .repeatWhileHeld) ?? false
        self.note = try container.decodeIfPresent(String.self, forKey: .note) ?? ""
    }

    static func sample(trigger: String, x: Double, y: Double) -> InputMapping {
        InputMapping(
            inputType: .keyboard,
            trigger: trigger,
            action: .tap,
            tapPoint: NormalizedPoint(x: x, y: y),
            durationMilliseconds: 120,
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
    case liveOverlay = "Live Overlay"
    case gamepadPlanned = "Gamepad Planned"

    var id: String { rawValue }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = try container.decode(String.self)
        self = InputBridgeMode(rawValue: rawValue) ?? (rawValue == "Overlay Planned" ? .liveOverlay : .adbTap)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    var summary: String {
        switch self {
        case .adbTap: return "Works now for manual tap tests and saved profile playback."
        case .liveOverlay: return "Captures keys in MacDroid's overlay window and sends ADB input commands."
        case .gamepadPlanned: return "Prepared for native controller event bridging."
        }
    }
}

struct NormalizedPoint: Codable, Hashable {
    var x: Double
    var y: Double

    var clamped: NormalizedPoint {
        NormalizedPoint(
            x: max(0, min(1, x)),
            y: max(0, min(1, y))
        )
    }
}

enum InputMappingAction: String, Codable, CaseIterable, Identifiable {
    case tap = "Tap"
    case longPress = "Long Press"
    case swipe = "Swipe"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .tap: return "hand.tap.fill"
        case .longPress: return "hand.point.up.left.fill"
        case .swipe: return "arrow.up.right"
        }
    }

    var defaultDurationMilliseconds: Int {
        switch self {
        case .tap: return 120
        case .longPress: return 650
        case .swipe: return 280
        }
    }
}
