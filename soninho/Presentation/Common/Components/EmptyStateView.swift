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
    let imageName: String?
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?

    // MARK: - State
    @State private var isAnimating = false

    // MARK: - Init
    init(
        icon: String = "moon.stars.fill",
        imageName: String? = nil,
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.imageName = imageName
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    // MARK: - View Body
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Hero illustration or icon bubble
            if let imageName {
                ZStack {
                    Circle()
                        .fill(AppColors.primary.opacity(0.18))
                        .frame(width: 150, height: 150)
                        .blur(radius: 34)
                        .scaleEffect(isAnimating ? 1.1 : 1.0)
                        .animation(
                            .easeInOut(duration: 2).repeatForever(autoreverses: true),
                            value: isAnimating
                        )

                    Image(imageName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 180, height: 180)
                }
            } else {
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
            }

            // Text
            VStack(spacing: 8) {
                Text(title)
                    .font(AppFonts.title2())
                    .foregroundStyle(AppColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(AppFonts.body())
                    .foregroundStyle(AppColors.textSecondary)
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
        .onAppear {
            isAnimating = true
        }
    }
}
