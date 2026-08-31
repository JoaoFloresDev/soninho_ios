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
            GlassBackdrop()

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
                                .foregroundStyle(AppColors.textSecondary)
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
                            icon: "arrow.right"
                        ) {
                            viewModel.completeOnboarding()
                            isOnboardingComplete = true
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

            // Hero illustration
            ZStack {
                // Soft brand glow behind the artwork
                Circle()
                    .fill(AppColors.primary.opacity(0.22))
                    .frame(width: 230, height: 230)
                    .blur(radius: 40)
                    .scaleEffect(isAnimating ? 1.12 : 1.0)

                Image(page.heroImage)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 260, height: 260)
            }
            .animation(
                .easeInOut(duration: 2).repeatForever(autoreverses: true),
                value: isAnimating
            )

            // Text
            VStack(spacing: 16) {
                Text(String(localized: String.LocalizationValue(page.title)))
                    .font(AppFonts.title())
                    .foregroundStyle(AppColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(String(localized: String.LocalizationValue(page.subtitle)))
                    .font(AppFonts.body())
                    .foregroundStyle(AppColors.textSecondary)
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