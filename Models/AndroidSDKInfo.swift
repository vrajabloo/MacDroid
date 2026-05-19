//
// AndroidSDKInfo.swift
// CleanDroid Gaming
//
// Stores the local Android SDK paths that CleanDroid Gaming needs in order to
// talk to the official Google Android Emulator, ADB, SDK Manager, and AVD tools.

import Foundation

struct AndroidSDKInfo: Codable, Equatable {
    var sdkRoot: URL?
    var adbURL: URL?
    var emulatorURL: URL?
    var avdManagerURL: URL?
    var sdkManagerURL: URL?
    var detectedMessages: [String]
    var playStoreImageAvailable: Bool

    var hasADB: Bool {
        adbURL != nil
    }

    var hasEmulator: Bool {
        emulatorURL != nil
    }

    var canManageAVDs: Bool {
        avdManagerURL != nil
    }

    var canInstallSystemImages: Bool {
        sdkManagerURL != nil
    }

    var isReadyForGaming: Bool {
        hasADB && hasEmulator && canManageAVDs
    }

    static let empty = AndroidSDKInfo(
        sdkRoot: nil,
        adbURL: nil,
        emulatorURL: nil,
        avdManagerURL: nil,
        sdkManagerURL: nil,
        detectedMessages: [],
        playStoreImageAvailable: false
    )
}

