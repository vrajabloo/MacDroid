//
// AVDDevice.swift
// CleanDroid Gaming
//
// Represents an Android Virtual Device returned by `avdmanager list avd`.
// CleanDroid Gaming starts and configures these official Google Emulator devices.

import Foundation

struct AVDDevice: Identifiable, Codable, Hashable {
    var id: String { name }

    var name: String
    var device: String
    var path: String
    var target: String
    var basedOn: String
    var isRecommended: Bool
}

