//
//  PaywallContent.swift
//  soninho
//
//  Benefit rows and trial length of the Sunrise Premium paywall.
//

import SwiftUI
import StoreKit

// MARK: - Paywall Content
enum PaywallContent {
    // MARK: - Types
    struct Benefit: Identifiable {
        let id: String
        let title: String
        let detail: String
    }

    // MARK: - Computed Properties
    /// Outcome first, three rows, one line about the wake-up challenges.
    static var benefits: [Benefit] {
        [
            Benefit(id: "challenges",
                    title: boldName(String(localized: "paywall.benefit.challenges")),
                    detail: String(localized: "paywall.benefit.challenges.detail")),
            Benefit(id: "sleep",
                    title: boldName(String(localized: "paywall.benefit.sleep")),
                    detail: String(localized: "paywall.benefit.sleep.detail")),
            Benefit(id: "smart",
                    title: boldName(String(localized: "paywall.benefit.smart")),
                    detail: String(localized: "paywall.benefit.smart.detail"))
        ]
    }

    // MARK: - Private Methods
    /// The benefit name is the **bold** span every locale already has in its
    /// one-line sentence; the detail line has its own key.
    private static func boldName(_ raw: String) -> String {
        let parts = raw.components(separatedBy: "**")
        return parts.count >= 3 ? parts[1].trimmingCharacters(in: .whitespaces) : raw
    }

    // MARK: - Trial
    /// Free-trial length in days, or nil when the product has no free trial.
    static func trialDays(of product: Product) -> Int? {
        guard let offer = product.subscription?.introductoryOffer,
              offer.paymentMode == .freeTrial else { return nil }
        let value = offer.period.value
        switch offer.period.unit {
        case .day: return value
        case .week: return value * 7
        case .month: return value * 30
        case .year: return value * 365
        @unknown default: return nil
        }
    }
}
