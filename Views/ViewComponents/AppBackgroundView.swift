//
// AppBackgroundView.swift
// CleanDroid Gaming
//
// Dark graphite background with restrained neon accents. The goal is premium and
// game-ready without becoming cartoonish.

import SwiftUI

struct AppBackgroundView: View {
    var body: some View {
        ZStack {
            Color(hex: 0x090B0D)

            LinearGradient(
                colors: [
                    Color(hex: 0x11211A, opacity: 0.82),
                    Color(hex: 0x0B1114, opacity: 0.88),
                    Color(hex: 0x121214, opacity: 1.0),
                    Color(hex: 0x07100C, opacity: 0.92)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
        .ignoresSafeArea()
    }
}
