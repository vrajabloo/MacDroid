//
// AppSection.swift
// MacDroid
//
// Defines the sidebar destinations. Each section maps to one main SwiftUI screen.

import Foundation

enum AppSection: String, CaseIterable, Identifiable, Hashable {
    case home = "Home"
    case library = "Library"
    case installer = "APK Installer"
    case boost = "Boost"
    case controls = "Key Mapping"
    case settings = "Settings"
    case logs = "Logs"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .home: return "house.fill"
        case .library: return "square.grid.2x2.fill"
        case .installer: return "arrow.down.app.fill"
        case .boost: return "wrench.and.screwdriver.fill"
        case .controls: return "keyboard.fill"
        case .settings: return "slider.horizontal.3"
        case .logs: return "terminal.fill"
        }
    }
}
