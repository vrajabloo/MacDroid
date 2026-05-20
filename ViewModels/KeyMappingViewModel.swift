//
// KeyMappingViewModel.swift
// MacDroid
//
// Handles lightweight editor state for key mapping profiles. The MVP edits data;
// future input injection can plug into the same profile model.

import Foundation

@MainActor
final class KeyMappingViewModel: ObservableObject {
    @Published var selectedPackageName: String?

    func profile(for app: AndroidApp, in profiles: [KeyMappingProfile]) -> KeyMappingProfile? {
        profiles.first(where: { $0.packageName == app.packageName })
    }
}

