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

    /// A toggle and its time as one card. Switching on opens the card at once and fades the
    /// time in; animating List's row height made the content drift and snap back.
    private func toggleWithTime(
        isOn: Binding<Bool>,
        time: Binding<Date>,
        icon: String,
        title: String,
        detail: String?,
        timeTitle: String,
        id: String
    ) -> some View {
        ToggleTimeCard(isOn: isOn, time: time, id: id, timeTitle: timeTitle) {
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

// MARK: - Toggle Time Card
/// Toggle + time picker in one cell. The row resizes without animation and only the
/// picker fades, so nothing in the cell moves while List settles the new height.
private struct ToggleTimeCard<Label: View>: View {
    // MARK: - Properties
    @Binding var isOn: Bool
    @Binding var time: Date
    let id: String
    let timeTitle: String
    @ViewBuilder let label: () -> Label

    // MARK: - State
    @State private var showsTime = false
    @State private var timeOpacity: Double = 0

    // MARK: - View Body
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Toggle(isOn: $isOn) { label() }
                .tint(AppColors.primary)
                .accessibilityIdentifier("\(id).toggle")

            if showsTime {
                VStack(spacing: 0) {
                    Divider()
                        .padding(.vertical, 12)
                    DatePicker(selection: $time, displayedComponents: .hourAndMinute) {
                        Text(timeTitle)
                            .foregroundStyle(AppColors.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .tint(AppColors.primary)
                    .accessibilityIdentifier("\(id).time")
                }
                .opacity(timeOpacity)
            }
        }
        .onAppear {
            showsTime = isOn
            timeOpacity = isOn ? 1 : 0
        }
        .onChange(of: isOn) { _, on in
            if on {
                showsTime = true
                timeOpacity = 0
                withAnimation(.easeOut(duration: 0.25).delay(0.05)) { timeOpacity = 1 }
            } else {
                withAnimation(.easeIn(duration: 0.12)) { timeOpacity = 0 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                    if !isOn { showsTime = false }
                }
            }
        }
    }
}
