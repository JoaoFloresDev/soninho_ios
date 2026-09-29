//
//  PaywallContent.swift
//  soninho
//
//  Benefit rows of the Sunrise Premium paywall.
//

import SwiftUI

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
}
