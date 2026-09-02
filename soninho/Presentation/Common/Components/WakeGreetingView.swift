//
//  WakeGreetingView.swift
//  soninho
//
//  Full-screen animated greeting shown when a sleep session ends — wishes the
//  user a good morning or a good rest of the day depending on the time.
//

import SwiftUI
import UIKit

// MARK: - Wake Greeting View
struct WakeGreetingView: View {
    // MARK: - Mode
    enum Mode {
        case wake    // user woke up — good morning / good rest of day
        case snooze  // user snoozed — see you in a few minutes
    }

    // MARK: - Properties
    var mode: Mode = .wake
    let onDismiss: () -> Void

    @State private var appeared = false
    @State private var glow = false
    @State private var didDismiss = false

    private let hour = Calendar.current.component(.hour, from: Date())

    // MARK: - Computed Properties
    private var isMorning: Bool { (5..<12).contains(hour) }
    /// Daytime — sun shown until 20h; moon only at actual night.
    private var isDay: Bool { (12..<20).contains(hour) }

    private var icon: String {
        if mode == .snooze { return "moon.zzz.fill" }
        if isMorning { return "sunrise.fill" }
        if isDay { return "sun.max.fill" }
        return "moon.stars.fill"
    }

    private var greeting: String {
        if mode == .snooze { return String(localized: "snooze_greeting") }
        return isMorning
            ? String(localized: "wake_greeting_morning")
            : String(localized: "wake_greeting_rest")
    }

    private var subtitle: String? {
        if mode == .snooze { return String(localized: "snooze_greeting_subtitle") }
        // "Your night was saved" only when one was (or is about to be). The
        // manual-stop path clears the tracking state BEFORE showing this, so
        // the manager's flag — set by whoever saved — is the reliable signal;
        // the live-state checks cover the alarm path, where the greeting shows
        // before the night is finished.
        guard WakeGreetingManager.shared.lastNightWasSaved
                || UserDefaults.standard.bool(forKey: StorageKeys.isCurrentlyTracking)
                || MotionSleepMonitor.shared.isMonitoring && !MotionSleepMonitor.shared.isAlarmOnlySession else {
            return nil
        }
        return String(localized: "wake_greeting_subtitle")
    }

    private var gradientColors: [Color] {
        if mode == .snooze {
            return [Color(hex: "2B1206"), Color(hex: "140A05"), Color(hex: "000000")]
        }
        if isMorning {
            return [Color(hex: "FBBF24"), Color(hex: "F97316"), Color(hex: "2B1206")]
        }
        if isDay {
            return [Color(hex: "FF8A50"), Color(hex: "D84315"), Color(hex: "1A0C05")]
        }
        return [Color(hex: "331507"), Color(hex: "140A05"), Color(hex: "000000")]
    }

    private var autoDismissDelay: TimeInterval { mode == .snooze ? 2.2 : 4.0 }

    // MARK: - View Body
    var body: some View {
        ZStack {
            LinearGradient(colors: gradientColors, startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea(edges: .top)

            VStack(spacing: 28) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.16))
                        .frame(width: 150, height: 150)
                        .scaleEffect(glow ? 1.12 : 0.95)

                    Image(systemName: icon)
                        .font(.system(size: 76))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.25), radius: 12, y: 4)
                }
                .scaleEffect(appeared ? 1 : 0.5)
                .opacity(appeared ? 1 : 0)

                VStack(spacing: 10) {
                    Text(greeting)
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .shadow(color: .black.opacity(0.2), radius: 8, y: 2)

                    if let subtitle {
                        Text(subtitle)
                            .font(AppFonts.body())
                            .foregroundStyle(.white.opacity(0.85))
                            .multilineTextAlignment(.center)
                    }
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 24)
            }
            .padding(.horizontal, 40)
        }
        .contentShape(Rectangle())
        .onTapGesture { finish() }
        .onAppear { start() }
    }

    // MARK: - Private Methods
    private func start() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation(.spring(response: 0.7, dampingFraction: 0.7)) {
            appeared = true
        }
        withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
            glow = true
        }
        // Auto-dismiss after a few seconds.
        DispatchQueue.main.asyncAfter(deadline: .now() + autoDismissDelay) {
            finish()
        }
    }

    /// Tap and the auto-dismiss timer both land here; the callback re-posts
    /// .didCompleteAlarm, so running it twice double-counted downstream.
    private func finish() {
        guard !didDismiss else { return }
        didDismiss = true
        onDismiss()
    }
}
