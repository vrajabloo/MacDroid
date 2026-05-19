// swift-tools-version: 5.9
//
// This package defines the CleanDroid Gaming macOS app.
// Xcode can open this folder directly and run the SwiftUI executable target.

import PackageDescription

let package = Package(
    name: "CleanDroidGaming",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "CleanDroidGaming",
            targets: ["CleanDroidGaming"]
        )
    ],
    targets: [
        .executableTarget(
            name: "CleanDroidGaming",
            path: ".",
            exclude: [
                "Package.swift",
                "README.md",
                "Build",
                "Documentation",
                "Packaging",
                "Resources"
            ]
        )
    ],
    swiftLanguageVersions: [.v5]
)
