//
//  SettingsViewModel.swift
//  soninho
//
//  Created by João Flores on 28/01/26.
//

import Foundation
import StoreKit
import MessageUI

// MARK: - Settings ViewModel
@MainActor
final class SettingsViewModel: ObservableObject {
    // MARK: - Dependencies
    private let storageService: StorageService

    // MARK: - Published Properties
    @Published var hapticFeedbackEnabled: Bool
    @Published var notificationsEnabled: Bool
    @Published var smartAlarmEnabled: Bool
    @Published var bedtimeReminderEnabled: Bool {
        didSet {
            storageService.bedtimeReminderEnabled = bedtimeReminderEnabled
            updateBedtimeReminder()
        }
    }
    @Published var showingLanguagePicker = false
    @Published var showingResetConfirmation = false

    // MARK: - Properties
    var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    var isPremium: Bool {
        storageService.isPremiumUser
    }

    var selectedLanguage: String {
        storageService.selectedLanguage ?? Locale.current.language.languageCode?.identifier ?? "en"
    }

    let languages = [
        ("en", "English"),
        ("pt", "Português"),
        ("es", "Español")
    ]

    // MARK: - Init
    init(storageService: StorageService = .shared) {
        self.storageService = storageService
        self.hapticFeedbackEnabled = storageService.hapticFeedbackEnabled
        self.notificationsEnabled = storageService.notificationsEnabled
        self.smartAlarmEnabled = storageService.smartAlarmEnabled
        self.bedtimeReminderEnabled = storageService.bedtimeReminderEnabled
    }

    // MARK: - Public Methods
    func toggleHapticFeedback() {
        HapticManager.selection()
        hapticFeedbackEnabled.toggle()
        storageService.hapticFeedbackEnabled = hapticFeedbackEnabled
    }

    func toggleNotifications() {
        HapticManager.selection()
        notificationsEnabled.toggle()
        storageService.notificationsEnabled = notificationsEnabled
    }

    func toggleSmartAlarm() {
        HapticManager.selection()
        smartAlarmEnabled.toggle()
        storageService.smartAlarmEnabled = smartAlarmEnabled
    }

    private func updateBedtimeReminder() {
        Task {
            if bedtimeReminderEnabled {
                await NotificationService.shared.scheduleBedtimeReminder(
                    bedtime: storageService.defaultBedtime,
                    minutesBefore: storageService.bedtimeReminderMinutes
                )
            } else {
                await NotificationService.shared.cancelBedtimeReminder()
            }
        }
    }

    func setLanguage(_ code: String) {
        HapticManager.selection()
        storageService.selectedLanguage = code
        // In production, you'd restart the app or update the locale
    }

    func requestReview() {
        HapticManager.mediumImpact()
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }

    func openAppStore() {
        HapticManager.mediumImpact()
        if let url = URL(string: AppConstants.appStoreURL) {
            UIApplication.shared.open(url)
        }
    }

    func shareApp() {
        HapticManager.mediumImpact()
        // Handled in the view
    }

    func sendFeedback() {
        HapticManager.mediumImpact()
        let email = AppConstants.supportEmail
        if let url = URL(string: "mailto:\(email)?subject=Soninho%20Feedback") {
            UIApplication.shared.open(url)
        }
    }

    func openPrivacyPolicy() {
        HapticManager.lightImpact()
        if let url = URL(string: AppConstants.privacyPolicyURL) {
            UIApplication.shared.open(url)
        }
    }

    func openTermsOfUse() {
        HapticManager.lightImpact()
        if let url = URL(string: AppConstants.termsOfUseURL) {
            UIApplication.shared.open(url)
        }
    }

    func resetAllData() {
        HapticManager.heavyImpact()
        storageService.resetAllData()
        // Update local state
        hapticFeedbackEnabled = true
        notificationsEnabled = true
        smartAlarmEnabled = true
    }
}
