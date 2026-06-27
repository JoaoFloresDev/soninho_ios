//
//  AlarmRingingView.swift
//  soninho
//
//  Full-screen alarm experience. Orchestrates the Pacote Despertar phases:
//  gradual sunrise ring → dismiss mission → anti-relapse confirmation.
//

import SwiftUI

// MARK: - Alarm Ringing View
struct AlarmRingingView: View {
    // MARK: - Phase
    private enum Phase {
        case ringing, mission, confirmation
    }

    /// What the user asked for before the mission gate — so snooze can't bypass
    /// the wake-up mission either.
    private enum PendingAction {
        case dismiss, snooze
    }

    // MARK: - Properties
    @EnvironmentObject private var notificationService: NotificationService
    @State private var phase: Phase = .ringing
    @State private var pendingAction: PendingAction = .dismiss
    @State private var alarm: AlarmModel?
    @State private var sunriseProgress: Double = 0
    @State private var pulseScale: CGFloat = 1.0
    @State private var bellRotation: Double = 0

    // MARK: - View Body
    var body: some View {
        ZStack {
            SunriseBackground(progress: sunriseProgress)

            switch phase {
            case .ringing:
                ringingContent
            case .mission:
                missionContent
            case .confirmation:
                WakeConfirmationView(
                    onConfirmed: { notificationService.completeAlarm() },
                    onRelapse: { relapse() }
                )
            }
        }
        .transition(.opacity)
        .onAppear { setup() }
    }

    // MARK: - Ringing Phase
    private var ringingContent: some View {
        VStack(spacing: 40) {
            Spacer()

            Text((notificationService.ringingAlarmTime ?? Date()).timeString)
                .font(.system(size: 64, weight: .thin, design: .rounded))
                .foregroundStyle(.white)
                .monospacedDigit()
                .shadow(color: .black.opacity(0.35), radius: 10, y: 2)

            // Pulsing alarm icon
            ZStack {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .stroke(Color.white.opacity(0.15), lineWidth: 2)
                        .frame(width: 140 + CGFloat(index) * 40, height: 140 + CGFloat(index) * 40)
                        .scaleEffect(pulseScale)
                        .opacity(2.0 - pulseScale)
                }

                Circle()
                    .fill(AppColors.surface.opacity(0.85))
                    .frame(width: 140, height: 140)
                    .shadow(color: .black.opacity(0.3), radius: 20)

                Image(systemName: "alarm.fill")
                    .font(.system(size: 56))
                    .foregroundStyle(AppColors.sleepGradient)
                    .rotationEffect(.degrees(bellRotation))
            }

            Text(String(localized: "alarm_ringing_title"))
                .font(AppFonts.title2())
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.3), radius: 6)

            Spacer()

            VStack(spacing: 16) {
                Button {
                    requestDismiss()
                } label: {
                    actionLabel(
                        icon: missionIcon,
                        text: missionDismissText,
                        foreground: .white,
                        background: AppColors.primary
                    )
                }

                Button {
                    requestSnooze()
                } label: {
                    actionLabel(
                        icon: "clock.arrow.circlepath",
                        text: String(localized: "alarm_snooze_label"),
                        foreground: AppColors.textSecondary,
                        background: AppColors.surface.opacity(0.85)
                    )
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 60)
        }
    }

    // MARK: - Mission Phase
    @ViewBuilder
    private var missionContent: some View {
        let difficulty = alarm?.missionDifficulty ?? .medium
        VStack {
            if alarm?.mission == .shake {
                ShakeMissionView(difficulty: difficulty, onComplete: missionCompleted)
            } else {
                MathMissionView(difficulty: difficulty, onComplete: missionCompleted)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Computed Properties
    private var missionIcon: String {
        (alarm?.mission.requiresMission ?? false) ? "checklist" : "xmark"
    }

    private var missionDismissText: String {
        (alarm?.mission.requiresMission ?? false)
            ? String(localized: "wake_start_mission")
            : String(localized: "alarm_dismiss")
    }

    // MARK: - Subviews
    private func actionLabel(icon: String, text: String, foreground: Color, background: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
            Text(text)
                .font(AppFonts.headline())
        }
        .foregroundStyle(foreground)
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .background(background)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Flow
    private func setup() {
        loadAlarm()
        startAnimations()
        startSunrise()
    }

    private func loadAlarm() {
        guard let id = notificationService.ringingAlarmId, let uuid = UUID(uuidString: id) else { return }
        alarm = StorageService.shared.loadAlarms().first { $0.id == uuid }
    }

    private func requestDismiss() {
        pendingAction = .dismiss
        gateThroughMission { finishOrConfirm() }
    }

    private func requestSnooze() {
        pendingAction = .snooze
        gateThroughMission { notificationService.snoozeCurrentAlarm() }
    }

    /// If the alarm has a wake-up mission, show it first; otherwise run the
    /// action immediately. Snooze and dismiss both pass through here so snooze
    /// can't skip the mission.
    private func gateThroughMission(_ immediate: () -> Void) {
        if alarm?.mission.requiresMission ?? false {
            withAnimation(.spring(response: 0.4)) { phase = .mission }
        } else {
            immediate()
        }
    }

    private func missionCompleted() {
        switch pendingAction {
        case .snooze:
            notificationService.snoozeCurrentAlarm()
        case .dismiss:
            finishOrConfirm()
        }
    }

    private func finishOrConfirm() {
        if alarm?.antiRelapseEnabled ?? false {
            notificationService.muteAlarm()
            withAnimation(.spring(response: 0.4)) { phase = .confirmation }
        } else {
            notificationService.completeAlarm()
        }
    }

    private func relapse() {
        notificationService.reRing()
        withAnimation(.spring(response: 0.4)) { phase = .ringing }
    }

    private func startSunrise() {
        guard let alarm, alarm.gradualWakeEnabled else {
            sunriseProgress = 0
            return
        }
        withAnimation(.easeInOut(duration: Double(alarm.gradualWakeDuration * 60))) {
            sunriseProgress = 1
        }
    }

    private func startAnimations() {
        withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
            pulseScale = 1.15
        }
        withAnimation(.easeInOut(duration: 0.15).repeatForever(autoreverses: true)) {
            bellRotation = 8
        }
    }
}
