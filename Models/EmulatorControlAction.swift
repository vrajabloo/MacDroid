//
// EmulatorControlAction.swift
// MacDroid
//
// Actions shown in MacDroid's replacement emulator toolbar. These mirror the
// common Google Emulator side buttons, but run through ADB so they keep working
// even if the official emulator toolbar ignores clicks.

import Foundation

enum EmulatorControlAction: String, CaseIterable, Identifiable {
    case power
    case volumeUp
    case volumeDown
    case screenshot
    case rotateLeft
    case rotateRight
    case back
    case home
    case recents

    var id: String { rawValue }

    var title: String {
        switch self {
        case .power: return "Power"
        case .volumeUp: return "Volume Up"
        case .volumeDown: return "Volume Down"
        case .screenshot: return "Screenshot"
        case .rotateLeft: return "Rotate Left"
        case .rotateRight: return "Rotate Right"
        case .back: return "Back"
        case .home: return "Home"
        case .recents: return "Recents"
        }
    }

    var systemImage: String {
        switch self {
        case .power: return "power"
        case .volumeUp: return "speaker.wave.3.fill"
        case .volumeDown: return "speaker.wave.1.fill"
        case .screenshot: return "camera.fill"
        case .rotateLeft: return "rotate.left"
        case .rotateRight: return "rotate.right"
        case .back: return "chevron.backward"
        case .home: return "circle"
        case .recents: return "square"
        }
    }

    var keyCode: String? {
        switch self {
        case .power: return "26"
        case .volumeUp: return "24"
        case .volumeDown: return "25"
        case .back: return "4"
        case .home: return "3"
        case .recents: return "187"
        case .screenshot, .rotateLeft, .rotateRight:
            return nil
        }
    }
}

