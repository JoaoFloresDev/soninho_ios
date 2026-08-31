//
//  AnalyticsService.swift
//  soninho
//

import Foundation
import FirebaseCore
import FirebaseAnalytics

// MARK: - Analytics
/// The app's single analytics entry point, following the lab's canonical event
/// taxonomy (`_GambitStudio/analytics/event-taxonomy.md`).
///
/// Every call is a no-op until `configure()` succeeds, so the app runs normally
/// on a build without `GoogleService-Info.plist` instead of crashing in
/// `FirebaseApp.configure()`.
enum Analytics {

    // MARK: - Constants
    private static let firstCoreActionKey = "analytics.hasLoggedFirstCoreAction"

    // MARK: - Properties
    private(set) static var isEnabled = false

    // MARK: - Public Methods

    /// Starts Firebase if the app was built with a configuration file.
    /// Returns whether analytics is live, so callers can log the gap.
    @discardableResult
    static func configure() -> Bool {
        guard Bundle.main.url(forResource: "GoogleService-Info", withExtension: "plist") != nil else {
            return false
        }
        FirebaseApp.configure()
        isEnabled = true
        return true
    }

    static func log(_ name: String, _ params: [String: Any] = [:]) {
        guard isEnabled else { return }
        FirebaseAnalytics.Analytics.logEvent(name, parameters: params)
    }

    /// SwiftUI's automatic screen_view reports `UIHostingController`, which is
    /// useless — screens are named explicitly instead.
    static func screen(_ name: String) {
        log(AnalyticsEventScreenView, [AnalyticsParameterScreenName: name])
    }

    /// The activation event. `first` marks the very first time on this install,
    /// which is what makes D1 retention comparable across apps.
    static func coreAction(_ kind: String) {
        let defaults = UserDefaults.standard
        let isFirst = !defaults.bool(forKey: firstCoreActionKey)
        if isFirst {
            defaults.set(true, forKey: firstCoreActionKey)
        }
        log("core_action", ["kind": kind, "first": isFirst])
    }

    static func featureUsed(_ name: String, source: String) {
        log("feature_used", ["name": name, "source": source])
    }

    static func permissionResult(_ kind: String, granted: Bool) {
        log("permission_result", ["kind": kind, "granted": granted])
    }

    static func onboardingStepViewed(_ step: Int) {
        log("onboarding_step_viewed", ["step": step])
    }

    static func onboardingCompleted(steps: Int, seconds: Int) {
        log("onboarding_completed", ["steps": steps, "seconds": seconds])
    }

    static func onboardingSkipped(at step: Int) {
        log("onboarding_skipped", ["step": step])
    }

    static func tabViewed(_ tab: String) {
        log("tab_viewed", ["tab": tab])
    }

    static func emptyStateViewed(_ screen: String) {
        log("empty_state_viewed", ["screen": screen])
    }
}
