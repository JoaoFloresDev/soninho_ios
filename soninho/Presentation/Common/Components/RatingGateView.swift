//
//  RatingGateView.swift
//  soninho
//
//  Pre-gate sheet: "enjoying the app?" with two answers. Yes → native StoreKit
//  prompt. No → short feedback form that goes to support by e-mail.
//  Attach with `.ratingGate()` on the app's root view.
//

import SwiftUI

// MARK: - Modifier
extension View {
    /// Presents the rating pre-gate whenever `RatingGateService.shared` activates.
    func ratingGate() -> some View {
        modifier(RatingGateModifier())
    }
}

struct RatingGateModifier: ViewModifier {
    @ObservedObject private var service = RatingGateService.shared

    func body(content: Content) -> some View {
        content.sheet(isPresented: $service.isPresented) {
            RatingGateSheet()
                .presentationDetents([.medium])
                .presentationDragIndicator(.visible)
        }
    }
}

// MARK: - Sheet
struct RatingGateSheet: View {
    // MARK: - Properties
    @ObservedObject private var service = RatingGateService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showFeedback = false
    @State private var feedbackText = ""
    @State private var feedbackSent = false

    // MARK: - View Body
    var body: some View {
        ZStack {
            GlassBackdrop()

            VStack(spacing: 20) {
                if showFeedback {
                    feedbackForm
                } else {
                    question
                }
            }
            .padding(24)
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Question Step
    private var question: some View {
        VStack(spacing: 16) {
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 52))
                .foregroundStyle(AppColors.sleepGradient)

            Text(String(localized: "rating_gate_title"))
                .font(AppFonts.title2())
                .foregroundStyle(AppColors.textPrimary)
                .multilineTextAlignment(.center)

            Text(String(localized: "rating_gate_subtitle"))
                .font(AppFonts.subheadline())
                .foregroundStyle(AppColors.textSecondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 10) {
                AppButton(title: String(localized: "rating_gate_yes"), style: .primary, icon: "star.fill") {
                    service.answeredYes()
                    dismiss()
                }

                AppButton(title: String(localized: "rating_gate_no"), style: .secondary) {
                    service.answeredNo()
                    withAnimation(.spring(response: 0.3)) { showFeedback = true }
                }
            }
        }
    }

    // MARK: - Feedback Step
    private var feedbackForm: some View {
        VStack(spacing: 16) {
            if feedbackSent {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(AppColors.success)

                Text(String(localized: "rating_gate_feedback_thanks"))
                    .font(AppFonts.headline())
                    .foregroundStyle(AppColors.textPrimary)
                    .multilineTextAlignment(.center)
            } else {
                Text(String(localized: "rating_gate_feedback_title"))
                    .font(AppFonts.title3())
                    .foregroundStyle(AppColors.textPrimary)
                    .multilineTextAlignment(.center)

                TextField(String(localized: "rating_gate_feedback_placeholder"), text: $feedbackText, axis: .vertical)
                    .lineLimit(4...6)
                    .foregroundStyle(AppColors.textPrimary)
                    .padding(12)
                    .glassSurface(cornerRadius: 12)

                AppButton(
                    title: String(localized: "rating_gate_feedback_send"),
                    style: .primary,
                    icon: "paperplane.fill",
                    isDisabled: feedbackText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                ) {
                    service.sendFeedback(feedbackText)
                    withAnimation(.spring(response: 0.3)) { feedbackSent = true }
                    Task {
                        try? await Task.sleep(for: .seconds(1.4))
                        dismiss()
                    }
                }
            }
        }
    }
}
