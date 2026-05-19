//
// MetricCard.swift
// CleanDroid Gaming
//
// Small dashboard metric card for installed games, AVDs, and SDK readiness.

import SwiftUI

struct MetricCard: View {
    var title: String
    var value: String
    var systemImage: String
    var color: Color

    var body: some View {
        PanelView {
            HStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(width: 34, height: 34)
                    .background(color.opacity(0.14), in: RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 2) {
                    Text(value)
                        .font(.title3.weight(.bold))
                    Text(title)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)
            }
        }
    }
}

