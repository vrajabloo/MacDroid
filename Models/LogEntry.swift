//
// LogEntry.swift
// MacDroid
//
// A readable log item used by the troubleshooting screen. Logs explain what the
// app is doing before it runs Android SDK commands, which helps beginner users.

import Foundation
import SwiftUI

struct LogEntry: Identifiable, Codable, Hashable {
    var id: UUID
    var date: Date
    var level: LogLevel
    var message: String
    var command: String?
}

enum LogLevel: String, Codable, CaseIterable {
    case info
    case command
    case success
    case warning
    case error

    var title: String {
        rawValue.capitalized
    }

    var color: Color {
        switch self {
        case .info:
            return .secondary
        case .command:
            return Color(hex: 0x00C2FF)
        case .success:
            return Color(hex: 0x1EEA8A)
        case .warning:
            return Color(hex: 0xFFD166)
        case .error:
            return Color(hex: 0xFF4D6D)
        }
    }
}

