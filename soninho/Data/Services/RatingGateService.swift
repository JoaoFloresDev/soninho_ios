//
//  RatingGateService.swift
//  soninho
//
//  Rating pre-gate eligibility. Counts the app's aha-moments (alarm completed,
//  sleep night saved), enforces cooldowns and Apple's yearly native-prompt cap,
//  and decides when the "enjoying the app?" sheet may appear. Happy users go to
//  the native StoreKit prompt; unhappy ones stay in-app (feedback by e-mail).
//

import Combine
import StoreKit
import UIKit

// MARK: - Rating Gate Service
@MainActor
final class RatingGateService: ObservableObject {
    // MARK: - Singleton
    static let shared = RatingGateService()

    // MARK: - Constants
    private enum Constants {
        static let minPositiveEvents = 2
        static let cooldownDays = 60
        static let negativeCooldownDays = 120
        static let maxNativePromptsPerYear = 3
        static let positiveCountKey = "ratingGate.positiveCount"
        static let lastShownKey = "ratingGate.lastShown"
        static let lastNegativeKey = "ratingGate.lastNegative"
        static let nativePromptDatesKey = "ratingGate.nativePromptDates"
    }

    // MARK: - Published Properties
    /// True while the pre-gate sheet should be presented.
    @Published var isPresented = false

    // MARK: - Properties
    private let defaults = UserDefaults.standard

    // MARK: - Init
    private init() {}

    // MARK: - Public Methods
    /// Call on every positive moment. Presents the gate when eligible.
    @discardableResult
    func recordPositiveEvent() -> Bool {
        let count = defaults.integer(forKey: Constants.positiveCountKey) + 1
        defaults.set(count, forKey: Constants.positiveCountKey)
        guard count >= Constants.minPositiveEvents, isEligible, !isPresented else { return false }
        defaults.set(Date(), forKey: Constants.lastShownKey)
        isPresented = true
        Analytics.log("rating_gate_shown", ["positive_events": count])
        return true
    }

    func answeredYes() {
        Analytics.log("rating_gate_answered", ["liked": true])
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { [weak self] in
            self?.requestNativeReview()
        }
    }

    func answeredNo() {
        Analytics.log("rating_gate_answered", ["liked": false])
        defaults.set(Date(), forKey: Constants.lastNegativeKey)
    }

    /// Internal feedback goes straight to support by e-mail — 1-2 star intent
    /// never reaches the App Store unprompted.
    func sendFeedback(_ text: String) {
        var components = URLComponents(string: "mailto:\(AppConstants.supportEmail)")
        components?.queryItems = [
            URLQueryItem(name: "subject", value: "\(AppConstants.appName) Feedback"),
            URLQueryItem(name: "body", value: text)
        ]
        guard let url = components?.url else { return }
        Analytics.log("rating_gate_feedback_sent")
        UIApplication.shared.open(url)
    }

    /// Settings → "Rate app": straight to the App Store review composer.
    func openWriteReview() {
        guard let url = URL(string: "\(AppConstants.appStoreURL)?action=write-review") else { return }
        UIApplication.shared.open(url)
    }

    // MARK: - Private Methods
    private var isEligible: Bool {
        let now = Date()
        if let last = defaults.object(forKey: Constants.lastShownKey) as? Date,
           now.timeIntervalSince(last) < TimeInterval(Constants.cooldownDays) * 86_400 {
            return false
        }
        if let negative = defaults.object(forKey: Constants.lastNegativeKey) as? Date,
           now.timeIntervalSince(negative) < TimeInterval(Constants.negativeCooldownDays) * 86_400 {
            return false
        }
        return nativePromptsInLastYear() < Constants.maxNativePromptsPerYear
    }

    private func nativePromptsInLastYear() -> Int {
        let dates = (defaults.array(forKey: Constants.nativePromptDatesKey) as? [Date]) ?? []
        let cutoff = Date().addingTimeInterval(-365 * 86_400)
        return dates.filter { $0 > cutoff }.count
    }

    private func requestNativeReview() {
        guard let scene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene else { return }
        AppStore.requestReview(in: scene)
        var dates = (defaults.array(forKey: Constants.nativePromptDatesKey) as? [Date]) ?? []
        dates.append(Date())
        defaults.set(Array(dates.suffix(10)), forKey: Constants.nativePromptDatesKey)
    }
}
