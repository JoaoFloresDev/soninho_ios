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
    @Published var autoStartSleepEnabled: Bool {
        didSet { storageService.autoStartSleepEnabled = autoStartSleepEnabled }
    }
    @Published var autoStartSleepTime: Date {
        didSet { storageService.autoStartSleepTime = autoStartSleepTime }
    }

    // MARK: - Properties
    var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }



    // MARK: - Init
    init(storageService: StorageService = .shared) {
        self.storageService = storageService
        self.bedtimeReminderEnabled = storageService.bedtimeReminderEnabled
        self.bedtimeReminderTime = storageService.bedtimeReminderTime
        self.autoStartSleepEnabled = storageService.autoStartSleepEnabled
        self.autoStartSleepTime = storageService.autoStartSleepTime
    }

    // MARK: - Public Methods

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


    func requestReview() {
        RatingGateService.shared.openWriteReview()
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
