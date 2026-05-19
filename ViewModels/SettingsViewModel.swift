//
// SettingsViewModel.swift
// CleanDroid Gaming
//
// Tracks whether settings have unsaved changes. The saved values are Codable and
// can later be expanded without changing the UI flow.

import Foundation

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var hasUnsavedChanges = false

    func markChanged() {
        hasUnsavedChanges = true
    }

    func markSaved() {
        hasUnsavedChanges = false
    }
}

