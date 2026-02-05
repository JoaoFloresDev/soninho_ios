//
//  ReviewService.swift
//  soninho
//
//  Created by João Flores on 28/01/26.
//

import StoreKit
import SwiftUI

// MARK: - Review Service
@MainActor
final class ReviewService: ObservableObject {
    // MARK: - Singleton
    static let shared = ReviewService()

    // MARK: - Constants
    private enum Constants {
        static let appOpenCountKey = "appOpenCount"
        static let lastReviewRequestKey = "lastReviewRequestDate"
        static let hasRequestedReviewKey = "hasRequestedReview"
        static let minOpenCountForReview = 5
        static let maxOpenCountForReview = 10
        static let daysBetweenReviews = 60
    }

    // MARK: - Properties
    private let defaults = UserDefaults.standard

    var appOpenCount: Int {
        get { defaults.integer(forKey: Constants.appOpenCountKey) }
        set { defaults.set(newValue, forKey: Constants.appOpenCountKey) }
    }

    private var lastReviewRequestDate: Date? {
        get { defaults.object(forKey: Constants.lastReviewRequestKey) as? Date }
        set { defaults.set(newValue, forKey: Constants.lastReviewRequestKey) }
    }

    private var hasRequestedReview: Bool {
        get { defaults.bool(forKey: Constants.hasRequestedReviewKey) }
        set { defaults.set(newValue, forKey: Constants.hasRequestedReviewKey) }
    }

    // MARK: - Init
    private init() {}

    // MARK: - Public Methods
    /// Call this when the app launches
    func incrementAppOpenCount() {
        appOpenCount += 1
        print("App open count: \(appOpenCount)")
    }

    /// Request review if conditions are met (5th-10th app open)
    func requestReviewIfAppropriate() {
        guard shouldRequestReview() else {
            print("Review conditions not met")
            return
        }

        // Request review
        if let windowScene = UIApplication.shared.connectedScenes
            .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene {
            SKStoreReviewController.requestReview(in: windowScene)
            lastReviewRequestDate = Date()
            hasRequestedReview = true
            print("Review requested!")
        }
    }

    /// Check if we should request a review
    private func shouldRequestReview() -> Bool {
        // Check if app open count is between 5 and 10
        guard appOpenCount >= Constants.minOpenCountForReview,
              appOpenCount <= Constants.maxOpenCountForReview else {
            return false
        }

        // If we've already requested a review during this range, don't request again
        // unless 60 days have passed
        if hasRequestedReview {
            guard let lastRequest = lastReviewRequestDate else {
                return true
            }

            let daysSinceLastRequest = Calendar.current.dateComponents(
                [.day],
                from: lastRequest,
                to: Date()
            ).day ?? 0

            return daysSinceLastRequest >= Constants.daysBetweenReviews
        }

        return true
    }

    /// Call this when user completes a positive action (like finishing sleep tracking)
    func userCompletedPositiveAction() {
        // Only request after positive moments
        if appOpenCount >= Constants.minOpenCountForReview {
            requestReviewIfAppropriate()
        }
    }

    /// Reset for testing
    func resetForTesting() {
        appOpenCount = 0
        lastReviewRequestDate = nil
        hasRequestedReview = false
    }
}
