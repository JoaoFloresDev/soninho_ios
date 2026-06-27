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

    @Published var bedtimeReminderEnabled: Bool {
        didSet { defaults.set(bedtimeReminderEnabled, forKey: StorageKeys.bedtimeReminderEnabled) }
    }

    @Published var bedtimeReminderMinutes: Int {
        didSet { defaults.set(bedtimeReminderMinutes, forKey: StorageKeys.bedtimeReminderMinutes) }
    }

    @Published var sleepGoalHours: Double {
        didSet { defaults.set(sleepGoalHours, forKey: StorageKeys.sleepGoalHours) }
    }

    @Published var autoStartSleepEnabled: Bool {
        didSet { defaults.set(autoStartSleepEnabled, forKey: StorageKeys.autoStartSleepEnabled) }
    }

    // MARK: - Init
    private init() {
        self.hasCompletedOnboarding = defaults.bool(forKey: StorageKeys.hasCompletedOnboarding)
        self.isPremiumUser = defaults.bool(forKey: StorageKeys.isPremiumUser)
        self.smartAlarmEnabled = defaults.object(forKey: StorageKeys.smartAlarmEnabled) as? Bool ?? true
        self.hapticFeedbackEnabled = defaults.object(forKey: StorageKeys.hapticFeedbackEnabled) as? Bool ?? true
        self.notificationsEnabled = defaults.object(forKey: StorageKeys.notificationsEnabled) as? Bool ?? true
        self.bedtimeReminderEnabled = defaults.object(forKey: StorageKeys.bedtimeReminderEnabled) as? Bool ?? false
        self.bedtimeReminderMinutes = defaults.object(forKey: StorageKeys.bedtimeReminderMinutes) as? Int ?? 30
        self.sleepGoalHours = defaults.object(forKey: StorageKeys.sleepGoalHours) as? Double ?? 8.0
        self.autoStartSleepEnabled = defaults.object(forKey: StorageKeys.autoStartSleepEnabled) as? Bool ?? false
    }

    // MARK: - Alarm Methods
    func saveAlarm(_ alarm: AlarmModel) {
        if (try? encoder.encode(alarm)) != nil {
            var alarms = loadAlarms()
            if let index = alarms.firstIndex(where: { $0.id == alarm.id }) {
                alarms[index] = alarm
            } else {
                alarms.append(alarm)
            }
            if let alarmsData = try? encoder.encode(alarms) {
                defaults.set(alarmsData, forKey: StorageKeys.savedAlarms)
            }
        }
    }

    func loadAlarms() -> [AlarmModel] {
        guard let data = defaults.data(forKey: StorageKeys.savedAlarms),
              let alarms = try? decoder.decode([AlarmModel].self, from: data) else {
            return []
        }
        return alarms
    }

    func deleteAlarm(_ alarm: AlarmModel) {
        var alarms = loadAlarms()
        alarms.removeAll { $0.id == alarm.id }
        if let data = try? encoder.encode(alarms) {
            defaults.set(data, forKey: StorageKeys.savedAlarms)
        }
    }

    // MARK: - Sleep Records (Local Cache)
    static let sleepRecordsDidChangeNotification = Notification.Name("sleepRecordsDidChange")

    func saveSleepRecords(_ records: [SleepRecord], notify: Bool = true) {
        // Prune records older than 90 days to prevent UserDefaults bloat
        let cutoff = Date().addingTimeInterval(-90 * 86400)
        let pruned = records.filter { $0.endTime > cutoff }

        if let data = try? encoder.encode(pruned) {
            defaults.set(data, forKey: StorageKeys.cachedSleepRecords)
        }

        if notify {
            NotificationCenter.default.post(name: Self.sleepRecordsDidChangeNotification, object: nil)
        }
    }

    func loadCachedSleepRecords() -> [SleepRecord] {
        guard let data = defaults.data(forKey: StorageKeys.cachedSleepRecords),
              let records = try? decoder.decode([SleepRecord].self, from: data) else {
            return []
        }
        return records
    }

    func deleteSleepRecord(_ record: SleepRecord) {
        var records = loadCachedSleepRecords()
        records.removeAll { $0.id == record.id }
        saveSleepRecords(records)
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
            // Default: today at 23:00 (must be a real calendar date, not a
            // year-0001 placeholder, or alarm scheduling breaks).
            return Calendar.current.date(bySettingHour: 23, minute: 0, second: 0, of: Date()) ?? Date()
        }
        set { defaults.set(newValue, forKey: StorageKeys.defaultBedtime) }
    }

    var defaultWakeTime: Date {
        get {
            if let date = defaults.object(forKey: StorageKeys.defaultWakeTime) as? Date {
                return date
            }
            // Default: today at 07:00 (real calendar date, not a year-0001
            // placeholder, or alarm scheduling breaks).
            return Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
        }
        set { defaults.set(newValue, forKey: StorageKeys.defaultWakeTime) }
    }

    /// Time of day the bedtime reminder fires.
    var bedtimeReminderTime: Date {
        get {
            if let date = defaults.object(forKey: StorageKeys.bedtimeReminderTime) as? Date {
                return date
            }
            // Default: today at 22:30.
            return Calendar.current.date(bySettingHour: 22, minute: 30, second: 0, of: Date()) ?? Date()
        }
        set { defaults.set(newValue, forKey: StorageKeys.bedtimeReminderTime) }
    }

    /// Time of day the sleep night auto-starts (independent of the reminder).
    var autoStartSleepTime: Date {
        get {
            if let date = defaults.object(forKey: StorageKeys.autoStartSleepTime) as? Date {
                return date
            }
            // Default: today at 23:00.
            return Calendar.current.date(bySettingHour: 23, minute: 0, second: 0, of: Date()) ?? Date()
        }
        set { defaults.set(newValue, forKey: StorageKeys.autoStartSleepTime) }
    }

    // MARK: - Streak Tracking
    var currentStreak: Int {
        get { defaults.integer(forKey: StorageKeys.currentStreak) }
        set { defaults.set(newValue, forKey: StorageKeys.currentStreak) }
    }

    var longestStreak: Int {
        get { defaults.integer(forKey: StorageKeys.longestStreak) }
        set { defaults.set(newValue, forKey: StorageKeys.longestStreak) }
    }

    var lastSleepDate: Date? {
        get { defaults.object(forKey: StorageKeys.lastSleepDate) as? Date }
        set { defaults.set(newValue, forKey: StorageKeys.lastSleepDate) }
    }

    func updateStreak(for sleepDate: Date) {
        let calendar = Calendar.current

        // Normalize dates to start of day to avoid timestamp comparison issues
        let normalizedSleepDate = calendar.startOfDay(for: sleepDate)

        if let lastDate = lastSleepDate {
            let normalizedLastDate = calendar.startOfDay(for: lastDate)
            let daysBetween = calendar.dateComponents([.day], from: normalizedLastDate, to: normalizedSleepDate).day ?? 0

            if daysBetween == 1 {
                // Consecutive day - increment streak
                currentStreak += 1
            } else if daysBetween > 1 {
                // Missed a day - reset streak
                currentStreak = 1
            }
            // If daysBetween == 0, same day, don't change streak
        } else {
            // First sleep record
            currentStreak = 1
        }

        // Update longest streak
        if currentStreak > longestStreak {
            longestStreak = currentStreak
        }

        lastSleepDate = normalizedSleepDate
    }

    // MARK: - Reset
    func resetAllData() {
        guard let domain = Bundle.main.bundleIdentifier else { return }
        defaults.removePersistentDomain(forName: domain)
        defaults.synchronize()

        // Reset published properties
        hasCompletedOnboarding = false
        isPremiumUser = false
        smartAlarmEnabled = true
        hapticFeedbackEnabled = true
        notificationsEnabled = true
        bedtimeReminderEnabled = false
        bedtimeReminderMinutes = 30
        sleepGoalHours = 8.0
    }
}
