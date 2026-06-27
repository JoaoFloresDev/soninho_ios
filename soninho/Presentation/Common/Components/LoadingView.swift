//
//  LoadingView.swift
//  soninho
//
//  Created by João Flores on 28/01/26.
//

import SwiftUI

// MARK: - Loading View
struct LoadingView: View {
    // MARK: - Properties
    let message: String?

    // MARK: - State
    @State private var isAnimating = false

    // MARK: - Init
    init(message: String? = nil) {
        self.message = message
    }

    // MARK: - View Body
    var body: some View {
        VStack(spacing: 20) {
            // Animated Moon
            ZStack {
                Circle()
                    .fill(AppColors.primary.opacity(0.2))
                    .frame(width: 80, height: 80)
                    .scaleEffect(isAnimating ? 1.2 : 1.0)
                    .animation(
                        .easeInOut(duration: 1.5).repeatForever(autoreverses: true),
                        value: isAnimating
                    )

                Image(systemName: "moon.zzz.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(AppColors.sleepGradient)
                    .rotationEffect(.degrees(isAnimating ? 10 : -10))
                    .animation(
                        .easeInOut(duration: 2).repeatForever(autoreverses: true),
                        value: isAnimating
                    )
            }

            if let message = message {
                Text(message)
                    .font(AppFonts.body())
                    .foregroundStyle(AppColors.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Shimmer Loading Card
struct ShimmerCard: View {
    // MARK: - View Body
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            RoundedRectangle(cornerRadius: 8)
                .fill(AppColors.surfaceSecondary)
                .frame(height: 20)
                .frame(maxWidth: 150)
                .shimmer()

            RoundedRectangle(cornerRadius: 8)
                .fill(AppColors.surfaceSecondary)
                .frame(height: 40)
                .shimmer()

            HStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 8)
                    .fill(AppColors.surfaceSecondary)
                    .frame(width: 60, height: 16)
                    .shimmer()

                RoundedRectangle(cornerRadius: 8)
                    .fill(AppColors.surfaceSecondary)
                    .frame(width: 80, height: 16)
                    .shimmer()
            }
        }
        .cardStyle()
    }
}

// MARK: - Inline Loading
struct InlineLoading: View {
    // MARK: - State
    @State private var rotation: Double = 0

    // MARK: - View Body
    var body: some View {
        Image(systemName: "arrow.trianglehead.2.clockwise.rotate.90")
            .font(.system(size: 16, weight: .medium))
            .foregroundStyle(AppColors.primary)
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(.linear(duration: 1).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
    }
}