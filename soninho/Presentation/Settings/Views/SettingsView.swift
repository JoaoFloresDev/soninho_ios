//
//  SettingsView.swift
//  soninho
//
//  Created by João Flores on 28/01/26.
//

import SwiftUI

// MARK: - Settings View
struct SettingsView: View {
    // MARK: - Properties
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showingPaywall = false
    @State private var showingShareSheet = false

    // MARK: - View Body
    var body: some View {
        NavigationStack {
            List {
                // Premium Section (only show when purchases enabled)
                if AppConstants.isPurchasesEnabled {
                    premiumSection
                }

                // Preferences Section
                preferencesSection

                // Sleep Settings Section
                sleepSettingsSection

                // Support Section
                supportSection

                // About Section
                aboutSection

                // Danger Zone
                dangerSection
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(AppColors.background)
            .navigationTitle(String(localized: "settings_title"))
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showingShareSheet) {
                ShareSheet(items: [
                    String(localized: "share_message"),
                    URL(string: AppConstants.appStoreURL)!
                ])
            }
            .confirmationDialog(
                String(localized: "settings_reset_title"),
                isPresented: $viewModel.showingResetConfirmation,
                titleVisibility: .visible
            ) {
                Button(String(localized: "settings_reset_confirm"), role: .destructive) {
                    viewModel.resetAllData()
                }
                Button(String(localized: "action_cancel"), role: .cancel) {}
            } message: {
                Text(String(localized: "settings_reset_message"))
            }
            .sheet(isPresented: $viewModel.showingLanguagePicker) {
                LanguagePickerView(
                    selectedLanguage: viewModel.selectedLanguage,
                    languages: viewModel.languages,
                    onSelect: { code in
                        viewModel.setLanguage(code)
                        viewModel.showingLanguagePicker = false
                    }
                )
                .presentationDetents([.medium])
            }
        }
    }

    // MARK: - Premium Section
    private var premiumSection: some View {
        Section {
            if viewModel.isPremium {
                HStack(spacing: 12) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 20))
                        .foregroundColor(AppColors.accent)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(String(localized: "settings_premium_active"))
                            .font(AppFonts.body())
                            .foregroundColor(AppColors.textPrimary)

                        Text(String(localized: "settings_premium_thanks"))
                            .font(AppFonts.caption())
                            .foregroundColor(AppColors.textSecondary)
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
                                .foregroundColor(AppColors.textPrimary)

                            Text(String(localized: "settings_upgrade_description"))
                                .font(AppFonts.caption())
                                .foregroundColor(AppColors.textSecondary)
                        }

                        Spacer()

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(AppColors.textTertiary)
                    }
                }
                .listRowBackground(AppColors.surface)
            }
        }
    }

    // MARK: - Preferences Section
    private var preferencesSection: some View {
        Section(header: Text(String(localized: "settings_preferences"))) {
            // Language
            Button {
                viewModel.showingLanguagePicker = true
            } label: {
                HStack {
                    Label(String(localized: "settings_language"), systemImage: "globe")
                        .foregroundColor(AppColors.textPrimary)

                    Spacer()

                    Text(viewModel.languages.first { $0.0 == viewModel.selectedLanguage }?.1 ?? "English")
                        .foregroundColor(AppColors.textSecondary)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppColors.textTertiary)
                }
            }
            .listRowBackground(AppColors.surface)

            // Haptic Feedback
            Toggle(isOn: Binding(
                get: { viewModel.hapticFeedbackEnabled },
                set: { _ in viewModel.toggleHapticFeedback() }
            )) {
                Label(String(localized: "settings_haptic"), systemImage: "iphone.radiowaves.left.and.right")
            }
            .tint(AppColors.primary)
            .listRowBackground(AppColors.surface)

            // Notifications
            Toggle(isOn: Binding(
                get: { viewModel.notificationsEnabled },
                set: { _ in viewModel.toggleNotifications() }
            )) {
                Label(String(localized: "settings_notifications"), systemImage: "bell.badge")
            }
            .tint(AppColors.primary)
            .listRowBackground(AppColors.surface)
        }
    }

    // MARK: - Sleep Settings Section
    private var sleepSettingsSection: some View {
        Section(header: Text(String(localized: "settings_sleep"))) {
            // Smart Alarm
            Toggle(isOn: Binding(
                get: { viewModel.smartAlarmEnabled },
                set: { _ in viewModel.toggleSmartAlarm() }
            )) {
                Label(String(localized: "settings_smart_alarm"), systemImage: "brain.head.profile")
            }
            .tint(AppColors.accent)
            .listRowBackground(AppColors.surface)

            // Health App Integration
            NavigationLink {
                HealthKitSettingsView()
            } label: {
                Label(String(localized: "settings_health_app"), systemImage: "heart.fill")
                    .foregroundColor(AppColors.textPrimary)
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
                    .foregroundColor(AppColors.textPrimary)
            }
            .listRowBackground(AppColors.surface)

            // Share App
            Button {
                showingShareSheet = true
            } label: {
                Label(String(localized: "settings_share_app"), systemImage: "square.and.arrow.up")
                    .foregroundColor(AppColors.textPrimary)
            }
            .listRowBackground(AppColors.surface)

            // Send Feedback
            Button {
                viewModel.sendFeedback()
            } label: {
                Label(String(localized: "settings_feedback"), systemImage: "envelope.fill")
                    .foregroundColor(AppColors.textPrimary)
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
                    .foregroundColor(AppColors.textPrimary)
            }
            .listRowBackground(AppColors.surface)

            // Terms of Use
            Button {
                viewModel.openTermsOfUse()
            } label: {
                Label(String(localized: "settings_terms"), systemImage: "doc.text.fill")
                    .foregroundColor(AppColors.textPrimary)
            }
            .listRowBackground(AppColors.surface)

            // Version
            HStack {
                Label(String(localized: "settings_version"), systemImage: "info.circle.fill")
                    .foregroundColor(AppColors.textPrimary)

                Spacer()

                Text(viewModel.appVersion)
                    .foregroundColor(AppColors.textSecondary)
            }
            .listRowBackground(AppColors.surface)
        }
    }

    // MARK: - Danger Section
    private var dangerSection: some View {
        Section {
            Button {
                viewModel.showingResetConfirmation = true
            } label: {
                Label(String(localized: "settings_reset_data"), systemImage: "trash.fill")
                    .foregroundColor(AppColors.error)
            }
            .listRowBackground(AppColors.surface)
        }
    }
}

// MARK: - Share Sheet
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - HealthKit Settings View
struct HealthKitSettingsView: View {
    @StateObject private var healthKitService = HealthKitService.shared

    var body: some View {
        List {
            Section {
                HStack {
                    Text(String(localized: "settings_health_status"))
                    Spacer()
                    Text(healthKitService.isAuthorized
                        ? String(localized: "settings_health_connected")
                        : String(localized: "settings_health_not_connected"))
                        .foregroundColor(healthKitService.isAuthorized ? AppColors.success : AppColors.textSecondary)
                }
                .listRowBackground(AppColors.surface)

                if !healthKitService.isAuthorized {
                    Button {
                        Task {
                            try? await healthKitService.requestAuthorization()
                        }
                    } label: {
                        Text(String(localized: "settings_health_connect"))
                            .foregroundColor(AppColors.primary)
                    }
                    .listRowBackground(AppColors.surface)
                }
            } header: {
                Text(String(localized: "settings_health_section"))
            } footer: {
                Text(String(localized: "settings_health_footer"))
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(AppColors.background)
        .navigationTitle(String(localized: "settings_health_app"))
    }
}

// MARK: - Language Picker View
struct LanguagePickerView: View {
    let selectedLanguage: String
    let languages: [(String, String)]
    let onSelect: (String) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                ForEach(languages, id: \.0) { code, name in
                    Button {
                        onSelect(code)
                    } label: {
                        HStack {
                            Text(name)
                                .foregroundColor(AppColors.textPrimary)

                            Spacer()

                            if code == selectedLanguage {
                                Image(systemName: "checkmark")
                                    .foregroundColor(AppColors.primary)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                    .listRowBackground(AppColors.surface)
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(AppColors.background)
            .navigationTitle(String(localized: "settings_language"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "action_done")) {
                        dismiss()
                    }
                    .foregroundColor(AppColors.primary)
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    SettingsView()
}
