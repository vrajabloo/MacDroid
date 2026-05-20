//
// StatusBadge.swift
// MacDroid
//
// Compact status pill used for emulator and SDK health indicators.

import SwiftUI

struct StatusBadge: View {
    var title: String
    var color: Color

    var body: some View {
        HStack(spacing: 7) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(title)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(color.opacity(0.14))
                .overlay(Capsule().stroke(color.opacity(0.28), lineWidth: 1))
        )
    }
}

