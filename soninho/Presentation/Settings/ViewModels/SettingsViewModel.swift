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
    @Published var bedtimeReminderEnabled: Bool {
        didSet {
            storageService.bedtimeReminderEnabled = bedtimeReminderEnabled
            updateBedtimeReminder()
        }
    }
    @Published var bedtimeReminderTime: Date {
        didSet {
            storageService.bedtimeReminderTime = bedtimeReminderTime
            updateBedtimeReminder()
        }
    }
    @Published var showingLanguagePicker = false

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
        self.bedtimeReminderEnabled = storageService.bedtimeReminderEnabled
        self.bedtimeReminderTime = storageService.bedtimeReminderTime
    }

    // MARK: - Public Methods
    func toggleHapticFeedback() {
        hapticFeedbackEnabled.toggle()
        storageService.hapticFeedbackEnabled = hapticFeedbackEnabled
    }

    func toggleNotifications() {
        notificationsEnabled.toggle()
        storageService.notificationsEnabled = notificationsEnabled
    }

    private func updateBedtimeReminder() {
        let enabled = bedtimeReminderEnabled
        let time = bedtimeReminderTime
        Task {
            if enabled {
                await NotificationService.shared.scheduleBedtimeReminder(at: time)
            } else {
                await NotificationService.shared.cancelBedtimeReminder()
            }
        }
    }

    func setLanguage(_ code: String) {
        storageService.selectedLanguage = code
        // In production, you'd restart the app or update the locale
    }

    func requestReview() {
        if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
            SKStoreReviewController.requestReview(in: scene)
        }
    }

    func openAppStore() {
        if let url = URL(string: AppConstants.appStoreURL) {
            UIApplication.shared.open(url)
        }
    }

    func shareApp() {
        // Handled in the view
    }

    func sendFeedback() {
        let email = AppConstants.supportEmail
        let subject = AppConstants.appName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? AppConstants.appName
        if let url = URL(string: "mailto:\(email)?subject=\(subject)%20Feedback") {
            UIApplication.shared.open(url)
        }
    }

    func openPrivacyPolicy() {
        if let url = URL(string: AppConstants.privacyPolicyURL) {
            UIApplication.shared.open(url)
        }
    }

    func openTermsOfUse() {
        if let url = URL(string: AppConstants.termsOfUseURL) {
            UIApplication.shared.open(url)
        }
    }

}
