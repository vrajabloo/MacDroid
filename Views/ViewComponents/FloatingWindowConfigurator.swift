//
// FloatingWindowConfigurator.swift
// MacDroid
//
// Makes the MacDroid emulator controls window float above normal windows.
// This lets it behave like a practical replacement for the official emulator
// side toolbar when that toolbar does not respond to clicks.

import AppKit
import SwiftUI

struct FloatingWindowConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()

        DispatchQueue.main.async {
            configure(window: view.window)
        }

        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            configure(window: nsView.window)
        }
    }

    private func configure(window: NSWindow?) {
        guard let window else {
            return
        }

        window.level = .floating
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.isMovableByWindowBackground = true
        window.titleVisibility = .hidden
    }
}

