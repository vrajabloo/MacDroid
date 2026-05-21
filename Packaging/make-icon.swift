//
// make-icon.swift
// MacDroid
//
// Converts Packaging/AppIconSource.png into the full macOS .iconset and .icns
// files. Keeping the source image in the repo makes icon updates repeatable.

import AppKit
import Foundation

let outputDirectory = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? ".")
let iconsetURL = outputDirectory.appendingPathComponent("AppIcon.iconset", isDirectory: true)
let icnsURL = outputDirectory.appendingPathComponent("AppIcon.icns")
let sourceURL = outputDirectory.appendingPathComponent("AppIconSource.png")

guard let sourceImage = NSImage(contentsOf: sourceURL) else {
    fatalError("Missing AppIconSource.png at \(sourceURL.path)")
}

try? FileManager.default.removeItem(at: iconsetURL)
try? FileManager.default.removeItem(at: icnsURL)
try FileManager.default.createDirectory(at: iconsetURL, withIntermediateDirectories: true)

let sizes: [(name: String, points: CGFloat, scale: CGFloat)] = [
    ("icon_16x16.png", 16, 1),
    ("icon_16x16@2x.png", 16, 2),
    ("icon_32x32.png", 32, 1),
    ("icon_32x32@2x.png", 32, 2),
    ("icon_128x128.png", 128, 1),
    ("icon_128x128@2x.png", 128, 2),
    ("icon_256x256.png", 256, 1),
    ("icon_256x256@2x.png", 256, 2),
    ("icon_512x512.png", 512, 1),
    ("icon_512x512@2x.png", 512, 2)
]

for size in sizes {
    let pixelSize = CGSize(width: size.points * size.scale, height: size.points * size.scale)
    let image = NSImage(size: pixelSize)

    image.lockFocus()
    NSGraphicsContext.current?.imageInterpolation = .high
    sourceImage.draw(
        in: CGRect(origin: .zero, size: pixelSize),
        from: CGRect(origin: .zero, size: sourceImage.size),
        operation: .copy,
        fraction: 1
    )
    image.unlockFocus()

    guard
        let tiffData = image.tiffRepresentation,
        let bitmap = NSBitmapImageRep(data: tiffData),
        let pngData = bitmap.representation(using: .png, properties: [:])
    else {
        continue
    }

    try pngData.write(to: iconsetURL.appendingPathComponent(size.name))
}

let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", iconsetURL.path, "-o", icnsURL.path]
try process.run()
process.waitUntilExit()
