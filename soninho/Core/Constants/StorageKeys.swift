//
//  StorageKeys.swift
//  soninho
//
//  Created by João Flores on 28/01/26.
//

import Foundation

// MARK: - Storage Keys
/// Keys for UserDefaults storage.
enum StorageKeys {
    // MARK: - Onboarding
    static let hasCompletedOnboarding = "hasCompletedOnboarding"

    // MARK: - User Preferences
    static let selectedLanguage = "selectedLanguage"
    static let notificationsEnabled = "notificationsEnabled"
    static let hapticFeedbackEnabled = "hapticFeedbackEnabled"

    // MARK: - Sleep Settings
    static let defaultBedtime = "defaultBedtime"
    static let defaultWakeTime = "defaultWakeTime"
    static let smartAlarmEnabled = "smartAlarmEnabled"
    static let smartAlarmWindow = "smartAlarmWindow"
    static let alarmSound = "alarmSound"
    static let alarmVolume = "alarmVolume"

    // MARK: - Premium
    static let isPremiumUser = "isPremiumUser"
    static let premiumExpirationDate = "premiumExpirationDate"

    // MARK: - Review
    static let lastReviewRequestDate = "lastReviewRequestDate"
    static let sessionCount = "sessionCount"
    static let hasRatedApp = "hasRatedApp"

    // MARK: - Statistics
    static let totalSleepSessions = "totalSleepSessions"
    static let averageSleepDuration = "averageSleepDuration"
    static let averageBedtime = "averageBedtime"

    // MARK: - Tracking
    static let isCurrentlyTracking = "isCurrentlyTracking"
    static let trackingStartTime = "trackingStartTime"
}
