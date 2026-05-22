//
// AppVersion.swift
// MacDroid
//
// Keeps the public app version in one small place. The update checker compares
// this value with the latest GitHub Release tag.

import Foundation

enum AppVersion {
    static let current = "0.3.1"
    static let repositoryOwner = "vrajabloo"
    static let repositoryName = "MacDroid"
}
