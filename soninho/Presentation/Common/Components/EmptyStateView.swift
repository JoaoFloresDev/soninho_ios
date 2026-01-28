//
//  EmptyStateView.swift
//  soninho
//
//  Created by João Flores on 28/01/26.
//

import SwiftUI

// MARK: - Empty State View
struct EmptyStateView: View {
    // MARK: - Properties
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?

    // MARK: - State
    @State private var isAnimating = false

    // MARK: - Init
    init(
        icon: String = "moon.stars.fill",
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    // MARK: - View Body
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(AppColors.primary.opacity(0.1))
                    .frame(width: 120, height: 120)

                Circle()
                    .fill(AppColors.primary.opacity(0.2))
                    .frame(width: 90, height: 90)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(
                        .easeInOut(duration: 2).repeatForever(autoreverses: true),
                        value: isAnimating
                    )

                Image(systemName: icon)
                    .font(.system(size: 44))
                    .foregroundStyle(AppColors.sleepGradient)
            }

            // Text
            VStack(spacing: 8) {
                Text(title)
                    .font(AppFonts.title2())
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(AppFonts.body())
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            .padding(.horizontal, 32)

            // Action Button
            if let actionTitle = actionTitle, let action = action {
                AppButton(title: actionTitle, style: .primary, action: action)
                    .padding(.horizontal, 48)
                    .padding(.top, 8)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - No Data Empty State
struct NoSleepDataView: View {
    let onStartTracking: () -> Void

    var body: some View {
        EmptyStateView(
            icon: "bed.double.fill",
            title: String(localized: "empty_no_sleep_title"),
            message: String(localized: "empty_no_sleep_message"),
            actionTitle: String(localized: "empty_start_tracking"),
            action: onStartTracking
        )
    }
}

// MARK: - Preview
#Preview {
    EmptyStateView(
        icon: "moon.stars.fill",
        title: "No Sleep Data",
        message: "Start tracking your sleep to see insights and improve your rest.",
        actionTitle: "Start Tracking",
        action: {}
    )
}
