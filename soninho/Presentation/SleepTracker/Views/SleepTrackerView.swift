//
//  SleepTrackerView.swift
//  soninho
//
//  Created by João Flores on 28/01/26.
//

import SwiftUI

// MARK: - Sleep Tracker View
struct SleepTrackerView: View {
    // MARK: - Properties
    @StateObject private var viewModel = SleepTrackerViewModel()
    @State private var showingStopConfirmation = false
    @State private var showingCancelConfirmation = false

    // MARK: - View Body
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                backgroundGradient

                VStack(spacing: 40) {
                    Spacer()

                    // Status Message
                    Text(viewModel.trackingStatusMessage)
                        .font(AppFonts.headline())
                        .foregroundColor(AppColors.textSecondary)

                    // Timer Display
                    timerDisplay

                    // Current Phase (when tracking)
                    if viewModel.isTracking {
                        currentPhaseDisplay
                    }

                    Spacer()

                    // Action Buttons
                    actionButtons
                        .padding(.bottom, 60)
                }
                .padding(.horizontal, AppSpacing.screenHorizontal)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(String(localized: "tracker_title"))
                        .font(AppFonts.headline())
                        .foregroundColor(AppColors.textPrimary)
                }
            }
            .confirmationDialog(
                String(localized: "tracker_stop_title"),
                isPresented: $showingStopConfirmation,
                titleVisibility: .visible
            ) {
                Button(String(localized: "tracker_stop_save")) {
                    Task {
                        await viewModel.stopTracking()
                    }
                }
                Button(String(localized: "tracker_cancel"), role: .cancel) {}
            } message: {
                Text(String(localized: "tracker_stop_message"))
            }
            .confirmationDialog(
                String(localized: "tracker_cancel_title"),
                isPresented: $showingCancelConfirmation,
                titleVisibility: .visible
            ) {
                Button(String(localized: "tracker_discard"), role: .destructive) {
                    viewModel.cancelTracking()
                }
                Button(String(localized: "tracker_keep_tracking"), role: .cancel) {}
            } message: {
                Text(String(localized: "tracker_cancel_message"))
            }
        }
    }

    // MARK: - Background
    private var backgroundGradient: some View {
        LinearGradient(
            colors: viewModel.isTracking
                ? [Color(hex: "0F172A"), Color(hex: "1E1B4B"), Color(hex: "312E81")]
                : [AppColors.background, AppColors.surface],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    // MARK: - Timer Display
    private var timerDisplay: some View {
        ZStack {
            // Animated rings
            ForEach(0..<3) { index in
                Circle()
                    .stroke(
                        AppColors.primary.opacity(viewModel.isTracking ? 0.1 : 0.05),
                        lineWidth: 2
                    )
                    .frame(width: CGFloat(200 + index * 40), height: CGFloat(200 + index * 40))
                    .scaleEffect(viewModel.isTracking ? 1.05 : 1.0)
                    .animation(
                        .easeInOut(duration: 2)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.3),
                        value: viewModel.isTracking
                    )
            }

            // Main circle
            Circle()
                .fill(AppColors.surface.opacity(0.8))
                .frame(width: 200, height: 200)
                .shadow(color: AppColors.primary.opacity(viewModel.isTracking ? 0.3 : 0), radius: 30)

            // Timer text
            VStack(spacing: 8) {
                if viewModel.isTracking {
                    Image(systemName: "moon.zzz.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(AppColors.sleepGradient)

                    Text(viewModel.elapsedTimeString)
                        .font(AppFonts.timer())
                        .foregroundColor(AppColors.textPrimary)
                        .monospacedDigit()
                } else {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(AppColors.sleepGradient)

                    Text(String(localized: "tracker_tap_to_start"))
                        .font(AppFonts.subheadline())
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
    }

    // MARK: - Current Phase Display
    private var currentPhaseDisplay: some View {
        HStack(spacing: 8) {
            Image(systemName: viewModel.currentPhase.icon)
                .foregroundColor(viewModel.currentPhase.color)

            Text(viewModel.currentPhase.localizedName)
                .font(AppFonts.subheadline())
                .foregroundColor(viewModel.currentPhase.color)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(viewModel.currentPhase.color.opacity(0.15))
        .clipShape(Capsule())
        .animation(.easeInOut, value: viewModel.currentPhase)
    }

    // MARK: - Action Buttons
    private var actionButtons: some View {
        VStack(spacing: 16) {
            if viewModel.isTracking {
                // Wake Up Button
                AppButton(
                    title: String(localized: "tracker_wake_up"),
                    style: .primary,
                    icon: "sunrise.fill"
                ) {
                    showingStopConfirmation = true
                }

                // Cancel Button
                Button {
                    showingCancelConfirmation = true
                } label: {
                    Text(String(localized: "tracker_cancel_session"))
                        .font(AppFonts.subheadline())
                        .foregroundColor(AppColors.textSecondary)
                }
            } else {
                // Start Sleep Button
                AppButton(
                    title: String(localized: "tracker_start_sleep"),
                    style: .primary,
                    icon: "moon.fill"
                ) {
                    viewModel.startTracking()
                }

                // Quick Sleep Info
                HStack(spacing: 4) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 12))

                    Text(String(localized: "tracker_info"))
                        .font(AppFonts.caption())
                }
                .foregroundColor(AppColors.textTertiary)
            }
        }
    }
}

// MARK: - Preview
#Preview {
    SleepTrackerView()
}
