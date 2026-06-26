//
//  MathMissionView.swift
//  soninho
//
//  Dismiss mission: solve N arithmetic problems on a custom keypad before the
//  alarm can be silenced. Difficulty scales the operands and round count.
//

import SwiftUI
import UIKit

// MARK: - Math Mission View
struct MathMissionView: View {
    // MARK: - Properties
    let difficulty: MissionDifficulty
    let onComplete: () -> Void

    @State private var challenge: MathChallenge = .make(for: .medium)
    @State private var input = ""
    @State private var roundsLeft = 1
    @State private var totalRounds = 1
    @State private var shakeWrong = false

    // MARK: - Constants
    private let keypad: [[String]] = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        ["⌫", "0", "OK"]
    ]

    // MARK: - View Body
    var body: some View {
        VStack(spacing: 28) {
            // Progress dots
            HStack(spacing: 8) {
                ForEach(0..<totalRounds, id: \.self) { index in
                    Circle()
                        .fill(index < (totalRounds - roundsLeft) ? AppColors.accent : AppColors.surfaceSecondary)
                        .frame(width: 9, height: 9)
                }
            }

            Text(String(localized: "wake_math_title"))
                .font(AppFonts.subheadline())
                .foregroundStyle(AppColors.textSecondary)

            // Question + answer
            VStack(spacing: 10) {
                Text(challenge.question)
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .foregroundStyle(AppColors.textPrimary)

                Text(input.isEmpty ? "—" : input)
                    .font(.system(size: 40, weight: .semibold, design: .rounded))
                    .foregroundStyle(input.isEmpty ? AppColors.textTertiary : AppColors.accent)
                    .monospacedDigit()
                    .frame(height: 48)
                    .offset(x: shakeWrong ? -10 : 0)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            // Keypad
            VStack(spacing: 12) {
                ForEach(keypad, id: \.self) { row in
                    HStack(spacing: 12) {
                        ForEach(row, id: \.self) { key in
                            keypadButton(key)
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 28)
        .onAppear { setup() }
    }

    // MARK: - Subviews
    private func keypadButton(_ key: String) -> some View {
        Button {
            handle(key)
        } label: {
            Group {
                if key == "⌫" {
                    Image(systemName: "delete.left.fill")
                } else if key == "OK" {
                    Image(systemName: "checkmark")
                } else {
                    Text(key)
                }
            }
            .font(.system(size: 26, weight: .semibold, design: .rounded))
            .foregroundStyle(key == "OK" ? .white : AppColors.textPrimary)
            .frame(maxWidth: .infinity)
            .frame(height: 64)
            .background(key == "OK" ? AppColors.accent : AppColors.surfaceSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }

    // MARK: - Private Methods
    private func setup() {
        totalRounds = difficulty.mathRounds
        roundsLeft = difficulty.mathRounds
        challenge = .make(for: difficulty)
        input = ""
    }

    private func handle(_ key: String) {
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        switch key {
        case "⌫":
            if !input.isEmpty { input.removeLast() }
        case "OK":
            submit()
        default:
            if input.count < 5 { input.append(key) }
        }
    }

    private func submit() {
        guard let value = Int(input) else { return }
        if value == challenge.answer {
            roundsLeft -= 1
            if roundsLeft <= 0 {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                onComplete()
            } else {
                input = ""
                challenge = .make(for: difficulty)
            }
        } else {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            withAnimation(.default.repeatCount(3, autoreverses: true).speed(6)) {
                shakeWrong = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                shakeWrong = false
                input = ""
            }
        }
    }
}
