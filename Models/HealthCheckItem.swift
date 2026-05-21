//
// HealthCheckItem.swift
// MacDroid
//
// A simple status row for the Health screen. Each item uses beginner-friendly
// text so users know what is working and what needs attention.

import Foundation
import SwiftUI

struct HealthCheckItem: Identifiable, Codable, Hashable {
    var id: String
    var title: String
    var message: String
    var status: HealthCheckStatus
    var actionTitle: String?
}

enum HealthCheckStatus: String, Codable, CaseIterable, Identifiable {
    case good = "Good"
    case warning = "Warning"
    case error = "Error"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .good: return Color(hex: 0x1EEA8A)
        case .warning: return Color(hex: 0xFFD166)
        case .error: return Color(hex: 0xFF4D6D)
        }
    }

    var systemImage: String {
        switch self {
        case .good: return "checkmark.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.octagon.fill"
        }
    }
}
