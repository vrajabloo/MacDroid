//
// PanelView.swift
// CleanDroid Gaming
//
// Reusable polished panel. Cards are used for individual tools and repeated
// items, while page sections remain spacious and unframed.

import SwiftUI

struct PanelView<Content: View>: View {
    var padding: CGFloat = 18
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.055))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.10), lineWidth: 1)
                    )
            )
    }
}

