//
// AndroidDeviceInfo.swift
// CleanDroid Gaming
//
// Friendly details about the currently connected emulator. These values come
// from ADB properties and help users understand what Android device is running.

import Foundation

struct AndroidDeviceInfo: Codable, Equatable {
    var serial: String?
    var manufacturer: String?
    var model: String?
    var androidVersion: String?
    var apiLevel: String?
    var abi: String?
    var bootCompleted: Bool

    var title: String {
        let vendor = manufacturer?.isEmpty == false ? manufacturer! : "Android"
        let deviceModel = model?.isEmpty == false ? model! : "Emulator"
        return "\(vendor) \(deviceModel)"
    }

    static let empty = AndroidDeviceInfo(
        serial: nil,
        manufacturer: nil,
        model: nil,
        androidVersion: nil,
        apiLevel: nil,
        abi: nil,
        bootCompleted: false
    )
}

