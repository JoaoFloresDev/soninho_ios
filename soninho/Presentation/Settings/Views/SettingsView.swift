//
//  SettingsView.swift
//  soninho
//
//  Created by João Flores on 28/01/26.
//

import SwiftUI
import UIKit
import PaywallKit

// MARK: - Settings View
struct SettingsView: View {
    // MARK: - Properties
    @StateObject private var viewModel = SettingsViewModel()
    @ObservedObject private var store = StoreKitManager.shared
    @State private var showPaywall = false
    /// Fixed when the screen opens: a purchase made inside must not flip it mid-way.
    @State private var paywallMode: PaywallView.Mode = .offer
    // MARK: - View Body
    var body: some View {
        NavigationStack {
            List {
                // Premium Section
                premiumSection

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
            .background(GlassBackdrop())
            .contentMargins(.bottom, AppSpacing.lg, for: .scrollContent)
            .navigationTitle(String(localized: "settings_title"))
            .navigationBarTitleDisplayMode(.large)
            .onAppear { Analytics.screen("settings") }
            .fullScreenCover(isPresented: $showPaywall) {
                PaywallView(isPresented: $showPaywall, mode: paywallMode)
            }
        }
    }

    // MARK: - Premium Section
    private var premiumSection: some View {
        Section {
            if store.isPremium {
                Button {
                    PaywallAnalytics.source = "settings"
                    paywallMode = .owned
                    showPaywall = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(AppColors.accent)
                            .frame(width: 22)
                        Text(String(localized: "settings_premium_active"))
                            .font(AppFonts.body())
                            .foregroundStyle(AppColors.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("settings.premium.active")
                .glassListRow()
            } else {
                Button {
                    PaywallAnalytics.source = "settings"
                    paywallMode = .offer
                    showPaywall = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "sunrise.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(AppColors.accent)
                            .frame(width: 22)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(String(localized: "settings_premium"))
                                .font(AppFonts.body())
                                .foregroundStyle(AppColors.textPrimary)
                            Text(String(localized: "settings_premium_subtitle"))
                                .font(AppFonts.caption())
                                .foregroundStyle(AppColors.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(AppColors.textSecondary)
                    }
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("settings.premium")
                .glassListRow()
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


    // MARK: - Sleep Settings Section
    private var sleepSettingsSection: some View {
        Section(header: Text(String(localized: "settings_sleep"))) {
            // Bedtime Reminder
            Toggle(isOn: $viewModel.bedtimeReminderEnabled) {
                settingsRowLabel("moon.zzz.fill", String(localized: "settings_bedtime_reminder"))
            }
            .tint(AppColors.primary)
            .glassListRow()

            // Bedtime Reminder Time
            if viewModel.bedtimeReminderEnabled {
                DatePicker(selection: $viewModel.bedtimeReminderTime, displayedComponents: .hourAndMinute) {
                    settingsRowLabel("clock", String(localized: "settings_bedtime_time"))
                        .foregroundStyle(AppColors.textPrimary)
                }
                .tint(AppColors.primary)
                .glassListRow()
            }

            // Auto-start — a single cell that expands to reveal its time picker.
            VStack(alignment: .leading, spacing: 0) {
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

                if viewModel.autoStartSleepEnabled {
                    Divider()
                        .padding(.vertical, 12)

                    DatePicker(selection: $viewModel.autoStartSleepTime, displayedComponents: .hourAndMinute) {
                        Text(String(localized: "settings_autostart_time"))
                            .foregroundStyle(AppColors.textPrimary)
                    }
                    .tint(AppColors.primary)
                }
            }
            .glassListRow()
            .animation(.easeInOut(duration: 0.25), value: viewModel.autoStartSleepEnabled)

            // Sleep Tips
            NavigationLink {
                SleepTipsView()
            } label: {
                Label(String(localized: "settings_sleep_tips"), systemImage: "lightbulb.fill")
                    .foregroundStyle(AppColors.textPrimary)
            }
            .glassListRow()
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
            .glassListRow()
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
            .glassListRow()

            // Terms of Use
            Button {
                viewModel.openTermsOfUse()
            } label: {
                Label(String(localized: "settings_terms"), systemImage: "doc.text.fill")
                    .foregroundStyle(AppColors.textPrimary)
            }
            .glassListRow()

            // Version
            HStack {
                Label(String(localized: "settings_version"), systemImage: "info.circle.fill")
                    .foregroundStyle(AppColors.textPrimary)

                Spacer()

                Text(viewModel.appVersion)
                    .foregroundStyle(AppColors.textSecondary)
            }
            .glassListRow()
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
