//
//  WakeGreetingManager.swift
//  soninho
//
//  Drives the full-screen wake-up greeting shown after a sleep session ends.
//

import Foundation

// MARK: - Wake Greeting Manager
@MainActor
final class WakeGreetingManager: ObservableObject {
    // MARK: - Singleton
    static let shared = WakeGreetingManager()

    // MARK: - Published Properties
    @Published var isShowing = false
    /// Whether the night this greeting closes was actually saved — the
    /// subtitle claims it, and the tracking state is already cleared by the
    /// time the manual-stop path shows the greeting.
    private(set) var lastNightWasSaved = false

    // MARK: - Init
    private init() {}

    // MARK: - Public Methods
    func show(nightSaved: Bool = false) {
        lastNightWasSaved = nightSaved
        isShowing = true
    }

    func dismiss() {
        isShowing = false
        lastNightWasSaved = false
    }
}
