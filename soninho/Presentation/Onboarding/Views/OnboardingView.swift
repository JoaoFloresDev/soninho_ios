//
//  OnboardingView.swift
//  soninho
//
//  Created by João Flores on 28/01/26.
//

import SwiftUI

// MARK: - Onboarding View
struct OnboardingView: View {
    // MARK: - Properties
    @StateObject private var viewModel = OnboardingViewModel()
    @Binding var isOnboardingComplete: Bool

    // MARK: - View Body
    var body: some View {
        ZStack {
            // Background
            AppColors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Skip Button
                HStack {
                    Spacer()

                    if !viewModel.isLastPage {
                        Button {
                            viewModel.skipToEnd()
                        } label: {
                            Text(String(localized: "onboarding_skip"))
                                .font(AppFonts.subheadline())
                                .foregroundColor(AppColors.textSecondary)
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.screenHorizontal)
                .padding(.top, 16)
                .frame(height: 44)

                // Page Content
                TabView(selection: $viewModel.currentPage) {
                    ForEach(Array(viewModel.pages.enumerated()), id: \.element.id) { index, page in
                        OnboardingPageView(page: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                // Bottom Section
                VStack(spacing: 24) {
                    // Page Indicator
                    HStack(spacing: 8) {
                        ForEach(0..<viewModel.pages.count, id: \.self) { index in
                            Capsule()
                                .fill(index == viewModel.currentPage ? AppColors.primary : AppColors.surfaceSecondary)
                                .frame(width: index == viewModel.currentPage ? 24 : 8, height: 8)
                                .animation(.spring(response: 0.3), value: viewModel.currentPage)
                        }
                    }

                    // Action Buttons
                    if viewModel.isLastPage {
                        AppButton(
                            title: String(localized: "onboarding_get_started"),
                            style: .primary,
                            icon: "arrow.right",
                            isLoading: viewModel.isRequestingHealthKit
                        ) {
                            Task {
                                await viewModel.completeOnboarding()
                                isOnboardingComplete = true
                            }
                        }
                    } else {
                        AppButton(
                            title: String(localized: "onboarding_continue"),
                            style: .primary,
                            icon: "arrow.right"
                        ) {
                            viewModel.nextPage()
                        }
                    }
                }
                .padding(.horizontal, AppSpacing.screenHorizontal)
                .padding(.bottom, 48)
            }
        }
    }
}

// MARK: - Onboarding Page View
struct OnboardingPageView: View {
    // MARK: - Properties
    let page: OnboardingPage

    // MARK: - State
    @State private var isAnimating = false

    // MARK: - View Body
    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            // Icon
            ZStack {
                // Outer glow
                Circle()
                    .fill(
                        LinearGradient(
                            colors: page.gradient.map { Color(hex: $0).opacity(0.2) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 200, height: 200)
                    .blur(radius: 30)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)

                // Inner circle
                Circle()
                    .fill(
                        LinearGradient(
                            colors: page.gradient.map { Color(hex: $0) },
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)
                    .shadow(color: Color(hex: page.gradient[0]).opacity(0.4), radius: 20)

                // Icon
                Image(systemName: page.icon)
                    .font(.system(size: 56))
                    .foregroundColor(.white)
            }
            .animation(
                .easeInOut(duration: 2).repeatForever(autoreverses: true),
                value: isAnimating
            )

            // Text
            VStack(spacing: 16) {
                Text(String(localized: String.LocalizationValue(page.title)))
                    .font(AppFonts.title())
                    .foregroundColor(AppColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(String(localized: String.LocalizationValue(page.subtitle)))
                    .font(AppFonts.body())
                    .foregroundColor(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            .padding(.horizontal, 32)

            Spacer()
            Spacer()
        }
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Preview
#Preview {
    OnboardingView(isOnboardingComplete: .constant(false))
}
