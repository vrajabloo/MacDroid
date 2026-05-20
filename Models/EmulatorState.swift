//
// EmulatorState.swift
// MacDroid
//
// A simple state enum for the emulator lifecycle. The UI uses this to show
// beginner-friendly status text instead of raw command-line output.

import Foundation
import SwiftUI

enum EmulatorState: String, Codable {
    case unknown
    case stopped
    case booting
    case running
    case error

    var title: String {
        switch self {
        case .unknown:
            return "Unknown"
        case .stopped:
            return "Stopped"
        case .booting:
            return "Booting"
        case .running:
            return "Running"
        case .error:
            return "Needs Attention"
        }
    }

    var color: Color {
        switch self {
        case .running:
            return Color(hex: 0x1EEA8A)
        case .booting:
            return Color(hex: 0xFFD166)
        case .error:
            return Color(hex: 0xFF4D6D)
        case .stopped, .unknown:
            return Color.secondary
        }
    }
}

