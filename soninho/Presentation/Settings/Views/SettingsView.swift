//
//  SettingsView.swift
//  soninho
//
//  Created by João Flores on 28/01/26.
//

import SwiftUI
import UIKit

// MARK: - Settings View
struct SettingsView: View {
    // MARK: - Properties
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showingPaywall = false

    // MARK: - View Body
    var body: some View {
        NavigationStack {
            List {
                // Premium Section (only show when purchases enabled)
                if AppConstants.isPurchasesEnabled {
                    premiumSection
                }

                // Sleep Settings Section
                sleepSettingsSection

                // Support Section
                supportSection

                // About Section
                aboutSection
            }
            .listStyle(.insetGrouped)
            .labelStyle(SettingsRowLabelStyle())
            .scrollContentBackground(.hidden)
            .background(AppColors.background)
            .contentMargins(.bottom, AppSpacing.lg, for: .scrollContent)
            .navigationTitle(String(localized: "settings_title"))
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
        }
    }

    // MARK: - Row Label (matches SettingsRowLabelStyle for controls that ignore it)
    private func settingsRowLabel(_ systemImage: String, _ title: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 14))
                .frame(width: 22, alignment: .center)
            Text(title)
        }
    }

    // MARK: - Premium Section
    private var premiumSection: some View {
        Section {
            if viewModel.isPremium {
                HStack(spacing: 12) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 17))
                        .foregroundStyle(AppColors.accent)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(String(localized: "settings_premium_active"))
                            .font(AppFonts.body())
                            .foregroundStyle(AppColors.textPrimary)

                        Text(String(localized: "settings_premium_thanks"))
                            .font(AppFonts.caption())
                            .foregroundStyle(AppColors.textSecondary)
                    }
                }
                .listRowBackground(AppColors.surface)
            } else {
                Button {
                    showingPaywall = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [AppColors.accent, Color(hex: "FBBF24")],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text(String(localized: "settings_upgrade_pro"))
                                .font(AppFonts.body())
                                .foregroundStyle(AppColors.textPrimary)

                            Text(String(localized: "settings_upgrade_description"))
                                .font(AppFonts.caption())
                                .foregroundStyle(AppColors.textSecondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(AppColors.textTertiary)
                    }
                }
                .listRowBackground(AppColors.surface)
            }
        }
    }

    // MARK: - Sleep Settings Section
    private var sleepSettingsSection: some View {
        Section(header: Text(String(localized: "settings_sleep"))) {
            // Bedtime Reminder
            Toggle(isOn: $viewModel.bedtimeReminderEnabled) {
                settingsRowLabel("moon.zzz.fill", String(localized: "settings_bedtime_reminder"))
            }
            .tint(AppColors.primary)
            .listRowBackground(AppColors.surface)

            // Bedtime Reminder Time
            if viewModel.bedtimeReminderEnabled {
                DatePicker(selection: $viewModel.bedtimeReminderTime, displayedComponents: .hourAndMinute) {
                    settingsRowLabel("clock", String(localized: "settings_bedtime_time"))
                        .foregroundStyle(AppColors.textPrimary)
                }
                .tint(AppColors.primary)
                .listRowBackground(AppColors.surface)
            }

            // Auto-start the sleep night at its own time (while the app is alive)
            Toggle(isOn: $viewModel.autoStartSleepEnabled) {
                VStack(alignment: .leading, spacing: 2) {
                    settingsRowLabel("powersleep", String(localized: "settings_autostart_sleep"))
                    Text(String(localized: "settings_autostart_sleep_desc"))
                        .font(AppFonts.caption())
                        .foregroundStyle(AppColors.textSecondary)
                        .padding(.leading, 34)
                }
            }
            .tint(AppColors.primary)
            .listRowBackground(AppColors.surface)

            // Auto-start Time
            if viewModel.autoStartSleepEnabled {
                DatePicker(selection: $viewModel.autoStartSleepTime, displayedComponents: .hourAndMinute) {
                    settingsRowLabel("powersleep", String(localized: "settings_autostart_time"))
                        .foregroundStyle(AppColors.textPrimary)
                }
                .tint(AppColors.primary)
                .listRowBackground(AppColors.surface)
            }

            // Sleep Tips
            NavigationLink {
                SleepTipsView()
            } label: {
                Label(String(localized: "settings_sleep_tips"), systemImage: "lightbulb.fill")
                    .foregroundStyle(AppColors.textPrimary)
            }
            .listRowBackground(AppColors.surface)

            // Health App Integration
            NavigationLink {
                HealthKitSettingsView()
            } label: {
                Label(String(localized: "settings_health_app"), systemImage: "heart.fill")
                    .foregroundStyle(AppColors.textPrimary)
            }
            .listRowBackground(AppColors.surface)
        }
    }

    // MARK: - Support Section
    private var supportSection: some View {
        Section(header: Text(String(localized: "settings_support"))) {
            // Rate App
            Button {
                viewModel.requestReview()
            } label: {
                Label(String(localized: "settings_rate_app"), systemImage: "star.fill")
                    .foregroundStyle(AppColors.textPrimary)
            }
            .listRowBackground(AppColors.surface)

            // Share App
            if let shareURL = URL(string: AppConstants.appStoreURL) {
                ShareLink(item: shareURL, message: Text(String(localized: "share_message"))) {
                    settingsRowLabel("square.and.arrow.up", String(localized: "settings_share_app"))
                        .foregroundStyle(AppColors.textPrimary)
                }
                .listRowBackground(AppColors.surface)
            }

            // Send Feedback
            Button {
                viewModel.sendFeedback()
            } label: {
                Label(String(localized: "settings_feedback"), systemImage: "envelope.fill")
                    .foregroundStyle(AppColors.textPrimary)
            }
            .listRowBackground(AppColors.surface)
        }
    }

    // MARK: - About Section
    private var aboutSection: some View {
        Section(header: Text(String(localized: "settings_about"))) {
            // Privacy Policy
            Button {
                viewModel.openPrivacyPolicy()
            } label: {
                Label(String(localized: "settings_privacy"), systemImage: "hand.raised.fill")
                    .foregroundStyle(AppColors.textPrimary)
            }
            .listRowBackground(AppColors.surface)

            // Version
            HStack {
                Label(String(localized: "settings_version"), systemImage: "info.circle.fill")
                    .foregroundStyle(AppColors.textPrimary)

                Spacer()

                Text(viewModel.appVersion)
                    .foregroundStyle(AppColors.textSecondary)
            }
            .listRowBackground(AppColors.surface)
        }
    }

}

// MARK: - Settings Row Label Style
/// Smaller, consistently-aligned row icons (the default Label icon reads too big).
private struct SettingsRowLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 12) {
            configuration.icon
                .font(.system(size: 14))
                .frame(width: 22, alignment: .center)
            configuration.title
        }
    }
}

// MARK: - HealthKit Settings View
struct HealthKitSettingsView: View {
    @StateObject private var healthKit = HealthKitService.shared
    @State private var isRequesting = false

    var body: some View {
        List {
            Section {
                // Connect — triggers the Apple Health read-permission sheet.
                Button {
                    requestAccess()
                } label: {
                    HStack {
                        Label(String(localized: "settings_health_connect"), systemImage: "heart.fill")
                            .foregroundStyle(AppColors.textPrimary)
                        Spacer()
                        if isRequesting {
                            ProgressView()
                        } else {
                            Image(systemName: "arrow.right.circle.fill")
                                .foregroundStyle(AppColors.primary)
                        }
                    }
                }
                .disabled(isRequesting)
                .listRowBackground(AppColors.surface)

                // Apple hides read-only authorization, so we can't honestly show
                // a "Connected" status. Let the user manage access directly.
                Button {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                } label: {
                    HStack {
                        Text(String(localized: "settings_health_manage"))
                            .foregroundStyle(AppColors.primary)
                        Spacer()
                        Image(systemName: "arrow.up.forward.app")
                            .foregroundStyle(AppColors.textTertiary)
                    }
                }
                .listRowBackground(AppColors.surface)
            } header: {
                Text(String(localized: "settings_health_section"))
            } footer: {
                Text(String(localized: "settings_health_footer"))
            }
        }
        .listStyle(.insetGrouped)
        .labelStyle(SettingsRowLabelStyle())
        .scrollContentBackground(.hidden)
        .background(AppColors.background)
        .navigationTitle(String(localized: "settings_health_app"))
    }

    private func requestAccess() {
        isRequesting = true
        Task {
            try? await healthKit.requestAuthorization()
            isRequesting = false
        }
    }
}