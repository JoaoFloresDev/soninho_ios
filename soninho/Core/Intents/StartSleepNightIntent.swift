//
//  StartSleepNightIntent.swift
//  soninho
//
//  Exposes "Start sleep night" to Siri / the Shortcuts app so the user can
//  automate starting their sleep tracking — e.g. a Shortcuts automation
//  "When Sleep Focus turns on → Start sleep night" makes it fully hands-free.
//

import AppIntents
import Foundation

// MARK: - Start Sleep Night Intent
struct StartSleepNightIntent: AppIntent {
    static var title: LocalizedStringResource = "Start sleep night"
    static var description = IntentDescription("Opens Soninho and starts tracking your sleep night.")

    // Bring the app forward — the tracking session (motion + audio) needs the
    // app running, and at bedtime opening it is expected.
    static var openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult {
        // Post once the UI is up. The Sleep tab is the default tab, so it is
        // subscribed shortly after launch; a small delay covers cold starts.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            NotificationCenter.default.post(name: .didRequestSwitchToSleepTab, object: nil)
            NotificationCenter.default.post(name: .didRequestStartSleepTracking, object: nil)
        }
        return .result()
    }
}

// MARK: - App Shortcuts
struct SoninhoAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartSleepNightIntent(),
            phrases: [
                "Start my sleep night in \(.applicationName)",
                "Start sleep tracking in \(.applicationName)",
                "Iniciar noite de sono no \(.applicationName)",
                "Começar a dormir no \(.applicationName)",
                "Iniciar noche de sueño en \(.applicationName)"
            ],
            shortTitle: "Start sleep night",
            systemImageName: "moon.zzz.fill"
        )
    }
}
