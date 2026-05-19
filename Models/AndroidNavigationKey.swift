//
// AndroidNavigationKey.swift
// CleanDroid Gaming
//
// Android navigation keys that CleanDroid can send through ADB. These mirror the
// standard emulator controls users expect from commercial Android emulators.

import Foundation

enum AndroidNavigationKey: String, CaseIterable, Identifiable {
    case back = "KEYCODE_BACK"
    case home = "KEYCODE_HOME"
    case recents = "KEYCODE_APP_SWITCH"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .back:
            return "Back"
        case .home:
            return "Home"
        case .recents:
            return "Recents"
        }
    }

    var systemImage: String {
        switch self {
        case .back:
            return "chevron.backward"
        case .home:
            return "house.fill"
        case .recents:
            return "rectangle.stack.fill"
        }
    }

    var adbKeyCode: String {
        switch self {
        case .back:
            return "4"
        case .home:
            return "3"
        case .recents:
            return "187"
        }
    }

    var commandGroups: [[String]] {
        switch self {
        case .back:
            return [
                ["shell", "input", "keyevent", adbKeyCode],
                ["shell", "input", "keyevent", rawValue],
                ["shell", "cmd", "input", "keyevent", adbKeyCode]
            ]
        case .home:
            return [
                ["shell", "am", "start", "-a", "android.intent.action.MAIN", "-c", "android.intent.category.HOME"],
                ["shell", "input", "keyevent", adbKeyCode],
                ["shell", "input", "keyevent", rawValue]
            ]
        case .recents:
            return [
                ["shell", "input", "keyevent", adbKeyCode],
                ["shell", "input", "keyevent", rawValue],
                ["shell", "cmd", "input", "keyevent", adbKeyCode]
            ]
        }
    }
}
