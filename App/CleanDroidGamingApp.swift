//
// CleanDroidGamingApp.swift
// CleanDroid Gaming
//
// App entry point. The shared AppEnvironment is created once and injected into
// every SwiftUI screen.

import SwiftUI

@main
struct CleanDroidGamingApp: App {
    @StateObject private var environment = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(environment)
                .preferredColorScheme(.dark)
                .frame(minWidth: 1180, minHeight: 760)
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) { }
        }

        Window("Emulator Controls", id: "emulator-controls") {
            EmulatorControlsWindowView()
                .environmentObject(environment)
        }
        .windowResizability(.contentSize)
        .windowStyle(.hiddenTitleBar)
    }
}
