//
//  TypingMissionView.swift
//  soninho
//
//  Dismiss mission: retype a phrase exactly before the alarm can be silenced.
//  Forces enough focus to break sleep inertia. Difficulty scales phrase length
//  and round count.
//

import SwiftUI
import UIKit

// MARK: - Typing Mission View
struct TypingMissionView: View {
    // MARK: - Properties
    let difficulty: MissionDifficulty
    let onComplete: () -> Void

    @State private var challenge: TypingChallenge = .make(for: .medium)
    @State private var input = ""
    @State private var roundsLeft = 1
    @State private var totalRounds = 1
    @State private var shakeWrong = false
    @FocusState private var isFieldFocused: Bool

    // MARK: - Computed Properties
    private var isMatch: Bool {
        normalized(input) == normalized(challenge.phrase)
    }

    // MARK: - View Body
    var body: some View {
        VStack(spacing: 24) {
            // Progress dots
            HStack(spacing: 8) {
                ForEach(0..<totalRounds, id: \.self) { index in
                    Circle()
                        .fill(index < (totalRounds - roundsLeft) ? AppColors.accent : AppColors.surfaceSecondary)
                        .frame(width: 9, height: 9)
                }
            }

            Text(String(localized: "wake_typing_title"))
                .font(AppFonts.subheadline())
                .foregroundStyle(AppColors.textSecondary)

            // Phrase to copy
            Text(challenge.phrase)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(AppColors.textPrimary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .padding(.horizontal, 16)
                .background(AppColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .offset(x: shakeWrong ? -10 : 0)

            // Input
            TextField(String(localized: "wake_typing_placeholder"), text: $input)
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(isMatch ? AppColors.success : AppColors.textPrimary)
                .multilineTextAlignment(.center)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .focused($isFieldFocused)
                .submitLabel(.done)
                .onSubmit { submit() }
                .padding()
                .background(AppColors.surface)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            // Confirm
            Button {
                submit()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark")
                        .font(.system(size: 16, weight: .semibold))
                    Text(String(localized: "wake_typing_confirm"))
                        .font(AppFonts.headline())
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(isMatch ? AppColors.accent : AppColors.surfaceTertiary)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .padding(.horizontal, 28)
        .onAppear { setup() }
    }

    // MARK: - Private Methods
    private func setup() {
        totalRounds = difficulty.typingRounds
        roundsLeft = difficulty.typingRounds
        challenge = .make(for: difficulty)
        input = ""
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            isFieldFocused = true
        }
    }

    private func normalized(_ text: String) -> String {
        text.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func submit() {
        if isMatch {
            roundsLeft -= 1
            if roundsLeft <= 0 {
                UINotificationFeedbackGenerator().notificationOccurred(.success)
                isFieldFocused = false
                onComplete()
            } else {
                input = ""
                var next = TypingChallenge.make(for: difficulty)
                // Avoid repeating the exact same phrase back to back.
                while next.phrase == challenge.phrase {
                    next = TypingChallenge.make(for: difficulty)
                }
                challenge = next
            }
        } else {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            withAnimation(.default.repeatCount(3, autoreverses: true).speed(6)) {
                shakeWrong = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                shakeWrong = false
            }
        }
    }
}
