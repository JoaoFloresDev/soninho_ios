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
    @StateObject private var wakeGreeting = WakeGreetingManager.shared
    @State private var showingStopConfirmation = false
    @State private var showingCancelConfirmation = false
    @State private var pulseAnimation = false

    // MARK: - View Body
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                backgroundGradient

                if viewModel.isTracking {
                    trackingContent
                        .transition(.opacity)
                } else {
                    idleContent
                        .transition(.opacity)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .confirmationDialog(
                String(localized: "tracker_stop_title"),
                isPresented: $showingStopConfirmation,
                titleVisibility: .visible
            ) {
                Button(String(localized: "tracker_stop_save")) {
                    Task {
                        await viewModel.stopTracking()
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            viewModel.objectWillChange.send()
                        }
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
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        viewModel.cancelTracking()
                    }
                }
                Button(String(localized: "tracker_keep_tracking"), role: .cancel) {}
            } message: {
                Text(String(localized: "tracker_cancel_message"))
            }
            .onReceive(NotificationCenter.default.publisher(for: .didRequestStartSleepTracking)) { _ in
                guard !viewModel.isTracking else { return }
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    viewModel.startTracking()
                }
            }
            // Wake-up greeting — covers only the Sleep screen (tab bar stays).
            .overlay {
                if wakeGreeting.isShowing {
                    WakeGreetingView(onDismiss: {
                        withAnimation(.easeInOut(duration: 0.5)) { wakeGreeting.dismiss() }
                    })
                    .transition(.opacity)
                }
            }
            .animation(.easeInOut(duration: 0.5), value: wakeGreeting.isShowing)
        }
    }

    // MARK: - Background
    private var backgroundGradient: some View {
        LinearGradient(
            colors: viewModel.isTracking
                ? [Color(hex: "0F172A"), Color(hex: "1E1B4B"), Color(hex: "312E81")]
                : [AppColors.background, AppColors.background],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    // MARK: - Idle Content (Not Tracking)
    private var idleContent: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(spacing: 28) {
                    // Header
                    idleHeaderSection

                    // How It Works
                    howItWorksSection

                    // Sleep Cycle Info
                    sleepCycleInfoCard

                    // Battery Info
                    batteryInfoCard
                }
                .padding(.horizontal, AppSpacing.screenHorizontal)
                .padding(.bottom, 24)
            }

            // Fixed bottom button — safeAreaInset from MainTabView already
            // accounts for the custom tab bar, so we only need minimal padding.
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    viewModel.startTracking()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "moon.zzz.fill")
                        .font(.system(size: 16, weight: .semibold))
                    Text(String(localized: "tracker_start"))
                        .font(AppFonts.headline())
                }
                .frame(maxWidth: .infinity)
                .frame(height: AppSpacing.buttonHeight)
                .foregroundStyle(.white)
                .background(AppColors.primary)
                .clipShape(RoundedRectangle(cornerRadius: AppSpacing.buttonCornerRadius, style: .continuous))
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
            .padding(.horizontal, AppSpacing.screenHorizontal)
            .padding(.top, 16)
            .padding(.bottom, 16)
            .frame(maxWidth: .infinity)
            .background(AppColors.surface)
            .clipShape(UnevenRoundedRectangle(topLeadingRadius: 22, topTrailingRadius: 22, style: .continuous))
        }
    }

    // MARK: - Idle Header Section
    private var idleHeaderSection: some View {
        VStack(spacing: 6) {
            Image(systemName: "moon.stars.fill")
                .font(.system(size: 48))
                .foregroundStyle(AppColors.primary)
                .padding(.top, 16)
                .padding(.bottom, 8)

            Text(String(localized: "tracker_ready_to_sleep"))
                .font(AppFonts.title2())
                .fontWeight(.bold)
                .foregroundStyle(AppColors.textPrimary)

            Text(String(localized: "tracker_description"))
                .font(AppFonts.subheadline())
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)
        }
    }

    // MARK: - How It Works Section
    private var howItWorksSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(String(localized: "tracker_how_it_works"))
                .font(AppFonts.headline())
                .foregroundStyle(AppColors.textPrimary)

            VStack(spacing: 12) {
                StepCard(
                    number: 1,
                    icon: "moon.fill",
                    title: String(localized: "tracker_step1_title"),
                    description: String(localized: "tracker_step1_desc"),
                    color: AppColors.primary
                )

                StepCard(
                    number: 2,
                    icon: "waveform.path.ecg",
                    title: String(localized: "tracker_step2_title"),
                    description: String(localized: "tracker_step2_desc"),
                    color: AppColors.deepSleep
                )

                StepCard(
                    number: 3,
                    icon: "sunrise.fill",
                    title: String(localized: "tracker_step3_title"),
                    description: String(localized: "tracker_step3_desc"),
                    color: AppColors.accent
                )
            }
        }
    }

    // MARK: - Sleep Cycle Info Card
    private var sleepCycleInfoCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 20))
                    .foregroundStyle(AppColors.remSleep)
                    .frame(width: 40, height: 40)
                    .background(AppColors.remSleep.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 10))

                VStack(alignment: .leading, spacing: 2) {
                    Text(String(localized: "tracker_cycles_title"))
                        .font(AppFonts.subheadline())
                        .fontWeight(.semibold)
                        .foregroundStyle(AppColors.textPrimary)

                    Text(String(localized: "tracker_cycles_desc"))
                        .font(AppFonts.caption())
                        .foregroundStyle(AppColors.textSecondary)
                }
            }

            // Phase pills
            HStack(spacing: 8) {
                PhasePill(phase: .light)
                PhasePill(phase: .deep)
                PhasePill(phase: .rem)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Battery Info Card
    private var batteryInfoCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "battery.100.bolt")
                .font(.system(size: 20))
                .foregroundStyle(AppColors.warning)
                .frame(width: 40, height: 40)
                .background(AppColors.warning.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(String(localized: "tracker_battery_info_title"))
                    .font(AppFonts.subheadline())
                    .fontWeight(.medium)
                    .foregroundStyle(AppColors.textPrimary)

                Text(String(localized: "tracker_battery_info_message"))
                    .font(AppFonts.caption())
                    .foregroundStyle(AppColors.textSecondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Tracking Content
    private var trackingContent: some View {
        VStack(spacing: 0) {
            // Scrollable center content
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    Spacer(minLength: 8)
                        .frame(height: 8)

                    // Status
                    Text(viewModel.trackingStatusMessage)
                        .font(AppFonts.subheadline())
                        .foregroundStyle(AppColors.textSecondary)

                    // Timer Display
                    trackingTimerDisplay

                    // Current Phase
                    currentPhaseDisplay

                    // Movement & Sound Indicators
                    HStack(spacing: 24) {
                        movementIndicator
                        soundIndicator
                    }

                    // Tracking tip
                    trackingTipCard
                        .padding(.top, 8)
                }
                .padding(.horizontal, AppSpacing.screenHorizontal)
                .padding(.bottom, 16)
            }

            // Fixed bottom actions
            VStack(spacing: 12) {
                Button {
                    showingStopConfirmation = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "sunrise.fill")
                            .font(.system(size: 16, weight: .semibold))
                        Text(String(localized: "tracker_wake_up"))
                            .font(AppFonts.headline())
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: AppSpacing.buttonHeight)
                    .foregroundStyle(.white)
                    .background(AppColors.primary)
                    .clipShape(RoundedRectangle(cornerRadius: AppSpacing.buttonCornerRadius, style: .continuous))
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())

                Button {
                    showingCancelConfirmation = true
                } label: {
                    Text(String(localized: "tracker_cancel_session"))
                        .font(AppFonts.subheadline())
                        .foregroundStyle(AppColors.textSecondary)
                        .frame(minHeight: 44)
                }
                .buttonStyle(.plain)
                .contentShape(Rectangle())
            }
            .padding(.horizontal, AppSpacing.screenHorizontal)
            .padding(.top, 12)
            .padding(.bottom, 16)
        }
    }

    // MARK: - Tracking Timer Display
    private var trackingTimerDisplay: some View {
        ZStack {
            // Pulsing rings
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .stroke(
                        AppColors.primary.opacity(0.12 - Double(index) * 0.03),
                        lineWidth: 1.5
                    )
                    .frame(
                        width: CGFloat(150 + index * 30),
                        height: CGFloat(150 + index * 30)
                    )
                    .scaleEffect(pulseAnimation ? 1.06 : 1.0)
                    .animation(
                        .easeInOut(duration: 2.5)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.4),
                        value: pulseAnimation
                    )
            }

            // Main circle
            Circle()
                .fill(AppColors.surface.opacity(0.85))
                .frame(width: 150, height: 150)
                .shadow(color: .black.opacity(0.3), radius: 20)

            // Timer content
            VStack(spacing: 6) {
                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(AppColors.sleepGradient)

                Text(viewModel.elapsedTimeString)
                    .font(AppFonts.title2())
                    .foregroundStyle(AppColors.textPrimary)
                    .monospacedDigit()
            }
        }
        .onAppear {
            pulseAnimation = true
        }
    }

    // MARK: - Current Phase Display
    private var currentPhaseDisplay: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(viewModel.currentPhase.color)
                .frame(width: 8, height: 8)

            Image(systemName: viewModel.currentPhase.icon)
                .foregroundStyle(viewModel.currentPhase.color)

            Text(viewModel.currentPhase.localizedName)
                .font(AppFonts.subheadline())
                .foregroundStyle(viewModel.currentPhase.color)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(viewModel.currentPhase.color.opacity(0.12))
        .clipShape(Capsule())
        .animation(.easeInOut(duration: 0.5), value: viewModel.currentPhase)
    }

    // MARK: - Tracking Tip Card
    private var trackingTipCard: some View {
        HStack(spacing: 12) {
            Image(systemName: "iphone.gen3")
                .font(.system(size: 20))
                .foregroundStyle(AppColors.primary)
                .frame(width: 36, height: 36)
                .background(AppColors.primary.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(String(localized: "tracker_tip_title"))
                    .font(AppFonts.caption())
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColors.textSecondary)

                Text(String(localized: "tracker_tip_message"))
                    .font(AppFonts.caption2())
                    .foregroundStyle(AppColors.textTertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(12)
        .background(AppColors.surface.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    // MARK: - Movement Indicator
    private var movementIndicator: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "waveform.path")
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.textTertiary)

                Text(String(localized: "tracker_movement"))
                    .font(AppFonts.caption2())
                    .foregroundStyle(AppColors.textTertiary)
            }

            // Movement bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(AppColors.surfaceSecondary)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(movementBarColor)
                        .frame(width: max(4, geometry.size.width * normalizedMovement))
                        .animation(.easeInOut(duration: 0.5), value: viewModel.movementIntensity)
                }
            }
            .frame(width: 120, height: 6)
        }
    }

    private var normalizedMovement: CGFloat {
        // Normalize movement to 0-1 range (0.1g = full bar)
        min(1.0, CGFloat(viewModel.movementIntensity / 0.1))
    }

    private var movementBarColor: Color {
        if viewModel.movementIntensity < 0.005 {
            return AppColors.deepSleep
        } else if viewModel.movementIntensity < 0.015 {
            return AppColors.lightSleep
        } else if viewModel.movementIntensity < 0.05 {
            return AppColors.warning
        } else {
            return AppColors.error
        }
    }

    // MARK: - Sound Indicator
    private var soundIndicator: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "mic.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(AppColors.textTertiary)

                Text(String(localized: "tracker_sound"))
                    .font(AppFonts.caption2())
                    .foregroundStyle(AppColors.textTertiary)
            }

            // Sound bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(AppColors.surfaceSecondary)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(soundBarColor)
                        .frame(width: max(4, geometry.size.width * CGFloat(viewModel.soundLevel)))
                        .animation(.easeInOut(duration: 0.5), value: viewModel.soundLevel)
                }
            }
            .frame(width: 120, height: 6)
        }
    }

    private var soundBarColor: Color {
        if viewModel.soundLevel < 0.2 {
            return AppColors.deepSleep
        } else if viewModel.soundLevel < 0.4 {
            return AppColors.lightSleep
        } else if viewModel.soundLevel < 0.7 {
            return AppColors.warning
        } else {
            return AppColors.error
        }
    }
}

// MARK: - Step Card
private struct StepCard: View {
    let number: Int
    let icon: String
    let title: String
    let description: String
    let color: Color

    var body: some View {
        HStack(spacing: 14) {
            // Number badge
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(AppFonts.subheadline())
                    .fontWeight(.semibold)
                    .foregroundStyle(AppColors.textPrimary)

                Text(description)
                    .font(AppFonts.caption())
                    .foregroundStyle(AppColors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

// MARK: - Phase Pill
private struct PhasePill: View {
    let phase: SleepPhase

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(phase.color)
                .frame(width: 8, height: 8)

            Text(phase.localizedName)
                .font(AppFonts.caption2())
                .foregroundStyle(AppColors.textSecondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(phase.color.opacity(0.1))
        .clipShape(Capsule())
    }
}