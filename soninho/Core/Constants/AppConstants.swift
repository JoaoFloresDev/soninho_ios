//
//  AppConstants.swift
//  soninho
//
//  Created by João Flores on 28/01/26.
//

import Foundation

// MARK: - App Constants
enum AppConstants {
    // MARK: - App Info
    static var appName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? "Soninho"
    }
    static let appStoreId = "6758740138"
    static let supportEmail = "contact@gambitstudiotech.com"

    // MARK: - URLs
    static let privacyPolicyURL = "https://drive.google.com/file/d/1fEHysu7rRdk9Hns4CCgK-4ty2_a57vR_/view"
    static let termsOfUseURL = "https://drive.google.com/file/d/1fEHysu7rRdk9Hns4CCgK-4ty2_a57vR_/view"
    static let appStoreURL = "https://apps.apple.com/app/id\(appStoreId)"

    // MARK: - Feature Flags
    /// Set to true to enable in-app purchases and premium features
    static let isPurchasesEnabled = false

    // MARK: - StoreKit Products
    static let entitlementIdentifier = "premium"
    static let monthlyProductId = "soninho_monthly_1590"
    static let annualProductId = "soninho_annual_9990"

    // MARK: - Sleep Constants
    static let minSleepDurationHours: Double = 3
    static let maxSleepDurationHours: Double = 14
    static let idealSleepHours: Double = 8
    static let smartAlarmWindowMinutes: Int = 30

    // MARK: - Sleep Phases Duration (average percentages)
    static let deepSleepPercentage: Double = 0.20 // 20%
    static let lightSleepPercentage: Double = 0.50 // 50%
    static let remSleepPercentage: Double = 0.25 // 25%
    static let awakePercentage: Double = 0.05 // 5%

    // MARK: - Sleep Quality Thresholds
    static let excellentSleepScore: Int = 85
    static let goodSleepScore: Int = 70
    static let fairSleepScore: Int = 50

    // MARK: - Review
    static let reviewMinDays: Int = 60
    static let reviewMinSessions: Int = 5

    // MARK: - Animation
    static let animationDuration: Double = 0.3
    static let springAnimation: Double = 0.5
}
