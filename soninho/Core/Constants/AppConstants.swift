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
    static let termsOfUseURL = "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"
    static let appStoreURL = "https://apps.apple.com/app/id\(appStoreId)"

    // MARK: - StoreKit Products
    static let weeklyProductId = "com.gambitstudio.soninho.premium.weekly"
    static let yearlyProductId = "com.gambitstudio.soninho.premium.yearly"

    // MARK: - Sleep Constants
    static let smartAlarmWindowMinutes: Int = 30
    /// Sessions longer than this are auto-cancelled — the user forgot to stop tracking.
    static let autoCancelSleepSessionHours: Double = 12

    // MARK: - Animation
    static let animationDuration: Double = 0.3
    static let springAnimation: Double = 0.5
}
