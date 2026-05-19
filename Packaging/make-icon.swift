//
// make-icon.swift
// CleanDroid Gaming
//
// Generates a simple premium app icon for the local macOS bundle. This keeps the
// project self-contained without needing a designer-provided .icns file yet.

import AppKit
import Foundation

let outputDirectory = URL(fileURLWithPath: CommandLine.arguments.dropFirst().first ?? ".")
let iconsetURL = outputDirectory.appendingPathComponent("AppIcon.iconset", isDirectory: true)
let icnsURL = outputDirectory.appendingPathComponent("AppIcon.icns")

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
    drawIcon(in: CGRect(origin: .zero, size: pixelSize))
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

func drawIcon(in rect: CGRect) {
    let cornerRadius = rect.width * 0.18
    let backgroundPath = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
    NSColor(calibratedRed: 0.03, green: 0.04, blue: 0.045, alpha: 1).setFill()
    backgroundPath.fill()

    let accentRect = rect.insetBy(dx: rect.width * 0.13, dy: rect.height * 0.13)
    let accentPath = NSBezierPath(roundedRect: accentRect, xRadius: rect.width * 0.12, yRadius: rect.width * 0.12)
    NSColor(calibratedRed: 0.12, green: 0.92, blue: 0.54, alpha: 1).setFill()
    accentPath.fill()

    let innerRect = accentRect.insetBy(dx: rect.width * 0.08, dy: rect.height * 0.08)
    let innerPath = NSBezierPath(roundedRect: innerRect, xRadius: rect.width * 0.08, yRadius: rect.width * 0.08)
    NSColor(calibratedRed: 0.02, green: 0.03, blue: 0.028, alpha: 1).setFill()
    innerPath.fill()

    if let symbol = NSImage(systemSymbolName: "gamecontroller.fill", accessibilityDescription: nil) {
        let symbolRect = rect.insetBy(dx: rect.width * 0.24, dy: rect.height * 0.28)
        symbol.isTemplate = true
        NSColor(calibratedRed: 0.12, green: 0.92, blue: 0.54, alpha: 1).set()
        symbol.draw(in: symbolRect)
    }

    let playCircle = NSBezierPath(ovalIn: CGRect(
        x: rect.maxX - rect.width * 0.34,
        y: rect.minY + rect.height * 0.12,
        width: rect.width * 0.22,
        height: rect.width * 0.22
    ))
    NSColor(calibratedRed: 0.0, green: 0.76, blue: 1.0, alpha: 1).setFill()
    playCircle.fill()
}

