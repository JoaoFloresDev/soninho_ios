//
//  OnboardingView.swift
//  soninho
//
//  Created by João Flores on 28/01/26.
//

import SwiftUI
import PaywallKit

// MARK: - Onboarding View
struct OnboardingView: View {
    // MARK: - Properties
    @StateObject private var viewModel = OnboardingViewModel()
    @Binding var isOnboardingComplete: Bool
    @State private var showPaywall = false

    // MARK: - Constants
    /// One curve for every stage change: onboarding → paywall → app all push sideways.
    private static let stageTransition: Animation = .easeInOut(duration: 0.35)

    // MARK: - View Body
    var body: some View {
        ZStack {
            if showPaywall {
                PaywallView(isPresented: paywallPresented)
                    .transition(.push(from: .trailing))
            } else {
                pages
                    .transition(.push(from: .trailing))
            }
        }
        .animation(Self.stageTransition, value: showPaywall)
    }

    // MARK: - Subviews
    private var pages: some View {
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
                            finishOnboarding()
                        }
                        .accessibilityIdentifier("onboarding.getStarted")
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

    /// The paywall closes itself (X, purchase or restore) by setting this to false;
    /// that is the moment onboarding ends.
    private var paywallPresented: Binding<Bool> {
        Binding(
            get: { showPaywall },
            set: { presented in
                if !presented { completeOnboarding() }
            }
        )
    }

    // MARK: - Actions
    /// The paywall comes right after the last step; whatever the user does
    /// there (buy, restore or close), onboarding ends when it goes away.
    private func finishOnboarding() {
        guard !StoreKitManager.shared.isPremium else {
            completeOnboarding()
            return
        }
        PaywallAnalytics.source = "onboarding"
        withAnimation(Self.stageTransition) { showPaywall = true }
    }

    private func completeOnboarding() {
        viewModel.completeOnboarding()
        isOnboardingComplete = true
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

            // Hero illustration (carries its own baked halo glow)
            Image(page.heroImage)
                .resizable()
                .scaledToFit()
                .frame(width: 300, height: 300)
                .scaleEffect(isAnimating ? 1.03 : 1.0)
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
                    .fixedSize(horizontal: false, vertical: true)
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