//
//  ShakeMissionView.swift
//  soninho
//
//  Dismiss mission: shake the phone a target number of times to silence the
//  alarm. The physical motion breaks sleep inertia.
//

import SwiftUI
import UIKit

// MARK: - Shake Mission View
struct ShakeMissionView: View {
    // MARK: - Properties
    let difficulty: MissionDifficulty
    let onComplete: () -> Void

    @StateObject private var detector = ShakeDetector()
    @State private var target = 25
    @State private var wobble = false
    @State private var didComplete = false

    // MARK: - Computed Properties
    private var progress: Double {
        guard target > 0 else { return 0 }
        return min(Double(detector.shakeCount) / Double(target), 1.0)
    }

    // MARK: - View Body
    var body: some View {
        VStack(spacing: 32) {
            Text(String(localized: "wake_shake_title"))
                .font(AppFonts.title3())
                .foregroundStyle(AppColors.textPrimary)

            Text(String(localized: "wake_shake_subtitle"))
                .font(AppFonts.subheadline())
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)

            // Progress ring with phone icon
            ZStack {
                Circle()
                    .stroke(AppColors.surfaceSecondary, lineWidth: 12)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(AppColors.accent, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.3), value: progress)

                VStack(spacing: 4) {
                    Image(systemName: "iphone.gen3.radiowaves.left.and.right")
                        .font(.system(size: 44))
                        .foregroundStyle(AppColors.accent)
                        .rotationEffect(.degrees(wobble ? 12 : -12))

                    Text("\(detector.shakeCount)/\(target)")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(AppColors.textPrimary)
                        .monospacedDigit()
                }
            }
            .frame(width: 220, height: 220)
        }
        .padding(.horizontal, 28)
        .onAppear {
            target = difficulty.shakeTarget
            detector.start()
        }
        .onDisappear { detector.stop() }
        .onChange(of: detector.shakeCount) { _, _ in
            withAnimation(.spring(response: 0.18, dampingFraction: 0.4)) { wobble.toggle() }
            UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            if !didComplete, detector.shakeCount >= target {
                didComplete = true
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                detector.stop()
                onComplete()
            }
        }
    }
}
