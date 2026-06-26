//
//  WakeConfirmationView.swift
//  soninho
//
//  Anti-relapse confirmation: after the alarm is dismissed the user must take
//  a few steps to prove they actually got up. If they don't within the
//  window, the alarm re-rings.
//

import SwiftUI
import Combine
import UIKit

// MARK: - Wake Confirmation View
struct WakeConfirmationView: View {
    // MARK: - Properties
    let onConfirmed: () -> Void
    let onRelapse: () -> Void

    @StateObject private var monitor = StepWakeMonitor()
    @State private var remaining = WakeConfirmation.timeoutSeconds
    @State private var resolved = false

    private let target = WakeConfirmation.stepTarget
    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    // MARK: - Computed Properties
    private var progress: Double {
        min(Double(monitor.steps) / Double(target), 1.0)
    }

    // MARK: - View Body
    var body: some View {
        VStack(spacing: 32) {
            Image(systemName: "figure.walk.motion")
                .font(.system(size: 52))
                .foregroundStyle(AppColors.success)

            VStack(spacing: 8) {
                Text(String(localized: "wake_confirm_title"))
                    .font(AppFonts.title3())
                    .foregroundStyle(AppColors.textPrimary)

                Text(String(localized: "wake_confirm_subtitle"))
                    .font(AppFonts.subheadline())
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            // Step progress
            ZStack {
                Circle()
                    .stroke(AppColors.surfaceSecondary, lineWidth: 12)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(AppColors.success, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.3), value: progress)
                VStack(spacing: 2) {
                    Text("\(monitor.steps)/\(target)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.textPrimary)
                        .monospacedDigit()
                    Text(String(localized: "wake_confirm_steps"))
                        .font(AppFonts.caption())
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
            .frame(width: 200, height: 200)

            // Countdown
            Text(String(localized: "wake_confirm_countdown \(Int(remaining))"))
                .font(AppFonts.footnote())
                .foregroundStyle(AppColors.textTertiary)
                .monospacedDigit()
        }
        .padding(.horizontal, 28)
        .onAppear { monitor.start() }
        .onDisappear { monitor.stop() }
        .onChange(of: monitor.steps) { _, steps in
            if !resolved, steps >= target {
                resolve(success: true)
            }
        }
        .onReceive(ticker) { _ in
            guard !resolved else { return }
            remaining -= 1
            if remaining <= 0 { resolve(success: false) }
        }
    }

    // MARK: - Private Methods
    private func resolve(success: Bool) {
        resolved = true
        monitor.stop()
        if success {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            onConfirmed()
        } else {
            onRelapse()
        }
    }
}
