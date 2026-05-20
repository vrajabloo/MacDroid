// swift-tools-version: 5.9
//
// This package defines the MacDroid macOS app.
// Xcode can open this folder directly and run the SwiftUI executable target.

import PackageDescription

let package = Package(
    name: "MacDroid",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "MacDroid",
            targets: ["MacDroid"]
        )
    ],
    targets: [
        .executableTarget(
            name: "MacDroid",
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
