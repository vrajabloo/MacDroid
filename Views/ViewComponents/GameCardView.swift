//
// GameCardView.swift
// CleanDroid Gaming
//
// Artwork-style card for an installed Android app. Real app icons can be wired
// into AndroidApp.iconData in a later metadata pass.

import SwiftUI

struct GameCardView: View {
    var app: AndroidApp
    var onPlay: () -> Void
    var onUninstall: () -> Void
    var onCreateProfile: () -> Void
    var onToggleFavorite: () -> Void = {}
    var onOpenAppInfo: () -> Void = {}

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(app.artworkGradient)
                    .aspectRatio(1.45, contentMode: .fit)
                    .overlay(alignment: .bottomLeading) {
                        Text(app.displayInitial)
                            .font(.system(size: 54, weight: .black, design: .rounded))
                            .foregroundStyle(.black.opacity(0.54))
                            .padding(16)
                    }

                HStack(spacing: 6) {
                    Button(action: onToggleFavorite) {
                        Image(systemName: app.isFavorite ? "star.fill" : "star")
                            .frame(width: 30, height: 30)
                    }
                    .buttonStyle(.plain)
                    .help(app.isFavorite ? "Remove from favorites" : "Add to favorites")

                    Menu {
                        Button("Create Key Profile", action: onCreateProfile)
                        Button("Open Android App Info", action: onOpenAppInfo)
                        Button("Uninstall", role: .destructive, action: onUninstall)
                    } label: {
                        Image(systemName: "ellipsis")
                            .frame(width: 30, height: 30)
                    }
                    .menuStyle(.borderlessButton)
                }
                .padding(8)
                .background(Color.black.opacity(0.22), in: Capsule())
                .padding(8)
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(app.name)
                    .font(.headline)
                    .lineLimit(1)

                Text(app.packageName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                if let versionName = app.versionName {
                    Text("Version \(versionName)")
                        .font(.caption2)
                        .foregroundStyle(Color(hex: 0x1EEA8A))
                        .lineLimit(1)
                }

                if let lastPlayed = app.lastPlayed {
                    Text("Last played \(lastPlayed.formatted(date: .abbreviated, time: .shortened))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            HStack {
                Button(action: onPlay) {
                    Label("Play", systemImage: "play.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: 0x1EEA8A))

                Button(action: onCreateProfile) {
                    Image(systemName: "keyboard")
                        .frame(width: 30)
                }
                .help("Create or open key mapping profile")
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.065))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.10), lineWidth: 1)
                )
        )
    }
}
