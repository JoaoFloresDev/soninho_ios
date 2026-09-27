//
//  PaywallView.swift
//  soninho
//
//  Sunrise Premium paywall: unlocks the shake, typing and memory wake-up
//  missions. Built on PaywallKit's PurchaseScaffold (StoreKit 2).
//

import SwiftUI
import PaywallKit

// MARK: - Paywall View
struct PaywallView: View {
    // MARK: - Properties
    @Binding var isPresented: Bool

    // MARK: - View Body
    var body: some View {
        PurchaseScaffold(
            isPresented: $isPresented,
            title: String(localized: "paywall.title"),
            accentColor: AppColors.accent,
            features: PaywallContent.features,
            heroSymbol: "sunrise.fill",
            termsURL: URL(string: AppConstants.termsOfUseURL),
            privacyURL: URL(string: AppConstants.privacyPolicyURL),
            hasCooldown: true,
            allowCloseAfter: 3.0,
            startTrialText: String(localized: "paywall.startTrial"),
            unlockNowText: String(localized: "paywall.unlockNow"),
            restoreText: String(localized: "paywall.restore"),
            termsText: String(localized: "paywall.terms"),
            perText: String(localized: "paywall.per"),
            thenText: String(localized: "paywall.then"),
            saveText: String(localized: "paywall.save"),
            nothingRestoredText: String(localized: "paywall.nothingRestored"),
            plansUnavailableText: String(localized: "paywall.plansUnavailable"),
            retryText: String(localized: "paywall.retry"),
            periodNames: PaywallContent.periodNames
        )
        .onAppear { Analytics.screen("paywall") }
    }
}

// MARK: - Paywall Content
enum PaywallContent {
    // MARK: - Computed Properties
    static var features: [PurchaseFeature] {
        [
            PurchaseFeature(title: String(localized: "paywall.feature.1"), icon: WakeMission.shake.icon),
            PurchaseFeature(title: String(localized: "paywall.feature.2"), icon: WakeMission.typing.icon),
            PurchaseFeature(title: String(localized: "paywall.feature.3"), icon: WakeMission.memory.icon),
            PurchaseFeature(title: String(localized: "paywall.feature.4"), icon: "alarm.fill")
        ]
    }

    // MARK: - Constants
    static let periodNames = PurchasePeriodNames(
        planName: { period in
            switch period {
            case .day: return String(localized: "paywall.plan.daily")
            case .week: return String(localized: "paywall.plan.weekly")
            case .month: return String(localized: "paywall.plan.monthly")
            case .year: return String(localized: "paywall.plan.yearly")
            }
        },
        unitName: { period in
            switch period {
            case .day: return String(localized: "paywall.unit.day")
            case .week: return String(localized: "paywall.unit.week")
            case .month: return String(localized: "paywall.unit.month")
            case .year: return String(localized: "paywall.unit.year")
            }
        },
        trialName: { count, period in
            switch period {
            case .day: return String(localized: "paywall.trial.day \(count)")
            case .week: return String(localized: "paywall.trial.week \(count)")
            case .month: return String(localized: "paywall.trial.month \(count)")
            case .year: return String(localized: "paywall.trial.year \(count)")
            }
        }
    )
}
