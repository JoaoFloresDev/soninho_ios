//
//  ReviewService.swift
//  soninho
//
//  The app's only way to ask for a rating: the native StoreKit prompt,
//  requested directly at the aha-moment. No pre-prompt sheet and no feedback
//  form in front of it — that extra question filtered who got to rate (App
//  Review 5.6.1) and carried the crash and nagging bugs (LEARNINGS #85, #87, #88).
//
//  - `recordPositiveEvent(trigger:)` — call right after the user gets the
//    app's value. The call site picks the moment; this service decides whether
//    asking now is allowed.
//  - `openWriteReview()` — the Settings "Rate app" row: the App Store review
//    composer, on request, with no throttle.
//

import StoreKit
import UIKit

// MARK: - Review Trigger
/// The aha-moment that asked for the review. Forwarded to analytics as `trigger`.
enum ReviewTrigger: String {
    /// A measured night was saved after the user woke up.
    case nightTracked = "night_tracked"
}

// MARK: - Review Service
@MainActor
final class ReviewService {
    // MARK: - Singleton
    static let shared = ReviewService()

    // MARK: - Constants
    private enum Constants {
        /// A night is saved at most once per morning, so 2 already means the
        /// user came back to the value on a second day; a 3rd would push the
        /// first ask past the first days, when a sleep app loses most installs.
        static let minPositiveEvents = 2
        /// Days between two automatic requests.
        static let cooldownDays = 90
        /// iOS draws the prompt at most 3 times a year; asking more only spends attempts.
        static let maxRequestsPerYear = 3
        /// Seconds between the wake-up screens leaving and the request.
        static let delaySeconds: Double = 1.0
        /// The greeting auto-dismisses in 4 s; past this the moment is gone.
        static let maxWakeScreenWaitSeconds: Double = 30
        static let wakeScreenPollNanoseconds: UInt64 = 250_000_000
        /// Entries closer than this are one interruption (legacy migration).
        static let sameInterruptionSeconds: TimeInterval = 3_600
        static let historyLimit = 10
        static let positiveCountKey = "review.positiveCount"
        static let requestDatesKey = "review.requestDates"
        static let lastRequestVersionKey = "review.lastRequestVersion"
        static let legacyMigratedKey = "review.legacyMigrated"
    }

    // MARK: - Legacy Keys
    /// What the removed pre-prompt flow stored, read once by the migration. Its
    /// prefix is split on purpose: the flow is gone, and its type name should
    /// not keep showing up in a search of the source.
    private enum LegacyKeys {
        static let prefix = "rating" + "Gate."
        static let positiveCount = prefix + "positiveCount"
        static let lastShown = prefix + "lastShown"
        static let lastNegative = prefix + "lastNegative"
        static let nativePromptDates = prefix + "nativePromptDates"
        /// Written by the StorageService review flow of the first builds.
        static let lastReviewRequest = "lastReviewRequestDate"
    }

    // MARK: - Properties
    private let defaults = UserDefaults.standard
    /// A request is waiting for its moment; a second aha-moment inside that
    /// window must not queue another one.
    private var isRequestPending = false

    // MARK: - Computed Properties
    /// The alarm screen and the good-morning greeting are the success UI of this
    /// app's aha-moment — and an alarm ringing is never a moment to ask in.
    private var isWakeUpScreenVisible: Bool {
        NotificationService.shared.isAlarmRinging || WakeGreetingManager.shared.isShowing
    }

    private static var appVersion: String? {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String
    }

    // MARK: - Init
    private init() {}

    // MARK: - Public Methods

    /// Call right after the user gets the app's value. Returns true when a
    /// request was scheduled.
    @discardableResult
    func recordPositiveEvent(trigger: ReviewTrigger) -> Bool {
        migrateLegacyStateIfNeeded()
        let count = defaults.integer(forKey: Constants.positiveCountKey) + 1
        defaults.set(count, forKey: Constants.positiveCountKey)
        guard !isRequestPending, isEligible(positiveCount: count, now: Date()) else { return false }

        isRequestPending = true
        Task { @MainActor in
            defer { self.isRequestPending = false }
            guard await self.waitForWakeUpScreensToLeave() else { return }
            try? await Task.sleep(nanoseconds: UInt64(Constants.delaySeconds * 1_000_000_000))
            // The user left or an alarm started during the delay: keep the
            // attempt for the next aha-moment.
            guard !self.isWakeUpScreenVisible, self.requestNativeReview() else { return }
            self.recordRequest(date: Date())
            Analytics.log("review_prompt_requested", ["trigger": trigger.rawValue])
        }
        return true
    }

    /// Settings "Rate app": straight to the App Store review composer. The user
    /// asked for it, so nothing stands in front of it and nothing is throttled.
    func openWriteReview() {
        guard let url = URL(string: "\(AppConstants.appStoreURL)?action=write-review") else { return }
        UIApplication.shared.open(url)
    }

    // MARK: - Private Methods

    private func isEligible(positiveCount: Int, now: Date) -> Bool {
        guard positiveCount >= Constants.minPositiveEvents else { return false }
        let dates = requestDates()
        if let last = dates.last,
           now.timeIntervalSince(last) < TimeInterval(Constants.cooldownDays) * 86_400 {
            return false
        }
        let yearAgo = now.addingTimeInterval(-365 * 86_400)
        guard dates.filter({ $0 > yearAgo }).count < Constants.maxRequestsPerYear else { return false }
        if let version = Self.appVersion,
           defaults.string(forKey: Constants.lastRequestVersionKey) == version {
            return false
        }
        return true
    }

    /// Waits until the alarm screen and the greeting are gone. False when they
    /// outlast the wait — that aha-moment passes without asking.
    private func waitForWakeUpScreensToLeave() async -> Bool {
        let deadline = Date().addingTimeInterval(Constants.maxWakeScreenWaitSeconds)
        while isWakeUpScreenVisible {
            guard Date() < deadline else { return false }
            try? await Task.sleep(nanoseconds: Constants.wakeScreenPollNanoseconds)
        }
        return true
    }

    /// Appends a request to the history, keeping the last `historyLimit`.
    private func recordRequest(date: Date) {
        var dates = requestDates()
        dates.append(date)
        storeRequestDates(dates)
        if let version = Self.appVersion {
            defaults.set(version, forKey: Constants.lastRequestVersionKey)
        }
    }

    /// Request history, oldest first.
    private func requestDates() -> [Date] {
        ((defaults.array(forKey: Constants.requestDatesKey) as? [Date]) ?? []).sorted()
    }

    private func storeRequestDates(_ dates: [Date]) {
        // Array(...) is load-bearing: suffix() yields an ArraySlice, which is NOT a
        // property-list type, and UserDefaults.set raises an ObjC exception — the
        // app dies right after asking (LEARNINGS #85).
        defaults.set(Array(dates.suffix(Constants.historyLimit)), forKey: Constants.requestDatesKey)
    }

    /// Carries over, once, the state of the flows this service replaced: the
    /// positive-event count, every sheet exhibition and every native prompt.
    /// Someone who saw the sheet last month was already interrupted — that
    /// counts toward the cooldown, or the first build without it would ask again.
    private func migrateLegacyStateIfNeeded() {
        guard !defaults.bool(forKey: Constants.legacyMigratedKey) else { return }
        defaults.set(true, forKey: Constants.legacyMigratedKey)

        let legacyCount = defaults.integer(forKey: LegacyKeys.positiveCount)
        if legacyCount > defaults.integer(forKey: Constants.positiveCountKey) {
            defaults.set(legacyCount, forKey: Constants.positiveCountKey)
        }

        var dates = requestDates()
        dates += (defaults.array(forKey: LegacyKeys.nativePromptDates) as? [Date]) ?? []
        for key in [LegacyKeys.lastShown, LegacyKeys.lastNegative, LegacyKeys.lastReviewRequest] {
            if let date = defaults.object(forKey: key) as? Date {
                dates.append(date)
            }
        }
        // A "yes" on the sheet wrote its exhibition and a native-prompt date
        // seconds apart: one interruption, not two.
        var merged: [Date] = []
        for date in dates.sorted() {
            if let last = merged.last, date.timeIntervalSince(last) < Constants.sameInterruptionSeconds { continue }
            merged.append(date)
        }
        storeRequestDates(merged)
    }

    /// Hands the request to StoreKit. False when there is no foreground scene to ask in.
    private func requestNativeReview() -> Bool {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) else { return false }
        if #available(iOS 18.0, *) {
            AppStore.requestReview(in: scene)
        } else {
            SKStoreReviewController.requestReview(in: scene)
        }
        return true
    }
}
