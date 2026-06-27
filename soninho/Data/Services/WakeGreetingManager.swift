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

    // MARK: - Init
    private init() {}

    // MARK: - Public Methods
    func show() {
        isShowing = true
    }

    func dismiss() {
        isShowing = false
    }
}
