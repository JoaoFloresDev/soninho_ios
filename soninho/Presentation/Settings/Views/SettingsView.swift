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
            toggleWithTime(
                isOn: $viewModel.bedtimeReminderEnabled,
                time: $viewModel.bedtimeReminderTime,
                icon: "moon.zzz.fill",
                title: String(localized: "settings_bedtime_reminder"),
                detail: nil,
                timeTitle: String(localized: "settings_bedtime_time"),
                id: "settings.reminder"
            )

            // Auto-start
            toggleWithTime(
                isOn: $viewModel.autoStartSleepEnabled,
                time: $viewModel.autoStartSleepTime,
                icon: "powersleep",
                title: String(localized: "settings_autostart_sleep"),
                detail: String(localized: "settings_autostart_sleep_desc"),
                timeTitle: String(localized: "settings_autostart_time"),
                id: "settings.autostart"
            )

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

    /// A toggle and its time as one card: switching on slides the time picker out of
    /// the toggle inside the same cell. The animation rides on the binding, so List
    /// resizes the row in the same transaction instead of jumping after the content.
    private func toggleWithTime(
        isOn: Binding<Bool>,
        time: Binding<Date>,
        icon: String,
        title: String,
        detail: String?,
        timeTitle: String,
        id: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Toggle(isOn: isOn.animation(.spring(response: 0.38, dampingFraction: 0.88))) {
                VStack(alignment: .leading, spacing: 2) {
                    settingsRowLabel(icon, title)
                    if let detail {
                        Text(detail)
                            .font(AppFonts.caption())
                            .foregroundStyle(AppColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.leading, 34)
                    }
                }
            }
            .tint(AppColors.primary)
            .accessibilityIdentifier("\(id).toggle")

            if isOn.wrappedValue {
                VStack(spacing: 0) {
                    Divider()
                        .padding(.vertical, 12)
                    DatePicker(selection: time, displayedComponents: .hourAndMinute) {
                        Text(timeTitle)
                            .foregroundStyle(AppColors.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .tint(AppColors.primary)
                    .accessibilityIdentifier("\(id).time")
                }
                .transition(.opacity)
            }
        }
        // Pinned to the top: while List animates the row's height, centring would make the
        // toggle drift down and snap back.
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .clipped()
        .glassListRow()
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
