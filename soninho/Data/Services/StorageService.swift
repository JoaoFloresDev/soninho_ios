//
//  StorageService.swift
//  soninho
//
//  Created by João Flores on 28/01/26.
//

import Foundation
import SwiftUI

// MARK: - Storage Service
@MainActor
final class StorageService: ObservableObject {
    // MARK: - Singleton
    static let shared = StorageService()

    // MARK: - Properties
    private let defaults = UserDefaults.standard
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // MARK: - Published Properties
    @Published var hasCompletedOnboarding: Bool {
        didSet { defaults.set(hasCompletedOnboarding, forKey: StorageKeys.hasCompletedOnboarding) }
    }

    @Published var isPremiumUser: Bool {
        didSet { defaults.set(isPremiumUser, forKey: StorageKeys.isPremiumUser) }
    }

    @Published var smartAlarmEnabled: Bool {
        didSet { defaults.set(smartAlarmEnabled, forKey: StorageKeys.smartAlarmEnabled) }
    }

    @Published var hapticFeedbackEnabled: Bool {
        didSet { defaults.set(hapticFeedbackEnabled, forKey: StorageKeys.hapticFeedbackEnabled) }
    }

    @Published var notificationsEnabled: Bool {
        didSet { defaults.set(notificationsEnabled, forKey: StorageKeys.notificationsEnabled) }
    }

    // MARK: - Init
    private init() {
        self.hasCompletedOnboarding = defaults.bool(forKey: StorageKeys.hasCompletedOnboarding)
        self.isPremiumUser = defaults.bool(forKey: StorageKeys.isPremiumUser)
        self.smartAlarmEnabled = defaults.object(forKey: StorageKeys.smartAlarmEnabled) as? Bool ?? true
        self.hapticFeedbackEnabled = defaults.object(forKey: StorageKeys.hapticFeedbackEnabled) as? Bool ?? true
        self.notificationsEnabled = defaults.object(forKey: StorageKeys.notificationsEnabled) as? Bool ?? true
    }

    // MARK: - Alarm Methods
    func saveAlarm(_ alarm: AlarmModel) {
        if let data = try? encoder.encode(alarm) {
            var alarms = loadAlarms()
            if let index = alarms.firstIndex(where: { $0.id == alarm.id }) {
                alarms[index] = alarm
            } else {
                alarms.append(alarm)
            }
            if let alarmsData = try? encoder.encode(alarms) {
                defaults.set(alarmsData, forKey: "savedAlarms")
            }
        }
    }

    func loadAlarms() -> [AlarmModel] {
        guard let data = defaults.data(forKey: "savedAlarms"),
              let alarms = try? decoder.decode([AlarmModel].self, from: data) else {
            return []
        }
        return alarms
    }

    func deleteAlarm(_ alarm: AlarmModel) {
        var alarms = loadAlarms()
        alarms.removeAll { $0.id == alarm.id }
        if let data = try? encoder.encode(alarms) {
            defaults.set(data, forKey: "savedAlarms")
        }
    }

    // MARK: - Sleep Records (Local Cache)
    func saveSleepRecords(_ records: [SleepRecord]) {
        if let data = try? encoder.encode(records) {
            defaults.set(data, forKey: "cachedSleepRecords")
        }
    }

    func loadCachedSleepRecords() -> [SleepRecord] {
        guard let data = defaults.data(forKey: "cachedSleepRecords"),
              let records = try? decoder.decode([SleepRecord].self, from: data) else {
            return []
        }
        return records
    }

    // MARK: - Session Tracking
    var sessionCount: Int {
        get { defaults.integer(forKey: StorageKeys.sessionCount) }
        set { defaults.set(newValue, forKey: StorageKeys.sessionCount) }
    }

    func incrementSessionCount() {
        sessionCount += 1
    }

    // MARK: - Review
    var lastReviewRequestDate: Date? {
        get { defaults.object(forKey: StorageKeys.lastReviewRequestDate) as? Date }
        set { defaults.set(newValue, forKey: StorageKeys.lastReviewRequestDate) }
    }

    var hasRatedApp: Bool {
        get { defaults.bool(forKey: StorageKeys.hasRatedApp) }
        set { defaults.set(newValue, forKey: StorageKeys.hasRatedApp) }
    }

    func shouldRequestReview() -> Bool {
        guard !hasRatedApp else { return false }
        guard sessionCount >= AppConstants.reviewMinSessions else { return false }

        if let lastRequest = lastReviewRequestDate {
            let daysSinceLastRequest = Calendar.current.dateComponents(
                [.day],
                from: lastRequest,
                to: Date()
            ).day ?? 0
            return daysSinceLastRequest >= AppConstants.reviewMinDays
        }

        return true
    }

    // MARK: - Language
    var selectedLanguage: String? {
        get { defaults.string(forKey: StorageKeys.selectedLanguage) }
        set { defaults.set(newValue, forKey: StorageKeys.selectedLanguage) }
    }

    // MARK: - Bedtime Settings
    var defaultBedtime: Date {
        get {
            if let date = defaults.object(forKey: StorageKeys.defaultBedtime) as? Date {
                return date
            }
            // Default: 23:00
            var components = DateComponents()
            components.hour = 23
            components.minute = 0
            return Calendar.current.date(from: components) ?? Date()
        }
        set { defaults.set(newValue, forKey: StorageKeys.defaultBedtime) }
    }

    var defaultWakeTime: Date {
        get {
            if let date = defaults.object(forKey: StorageKeys.defaultWakeTime) as? Date {
                return date
            }
            // Default: 07:00
            var components = DateComponents()
            components.hour = 7
            components.minute = 0
            return Calendar.current.date(from: components) ?? Date()
        }
        set { defaults.set(newValue, forKey: StorageKeys.defaultWakeTime) }
    }

    // MARK: - Reset
    func resetAllData() {
        let domain = Bundle.main.bundleIdentifier!
        defaults.removePersistentDomain(forName: domain)
        defaults.synchronize()

        // Reset published properties
        hasCompletedOnboarding = false
        isPremiumUser = false
        smartAlarmEnabled = true
        hapticFeedbackEnabled = true
        notificationsEnabled = true
    }
}
