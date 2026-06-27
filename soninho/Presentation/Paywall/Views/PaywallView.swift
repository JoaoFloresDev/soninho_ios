//
//  PaywallView.swift
//  soninho
//
//  Created by João Flores on 28/01/26.
//

import SwiftUI

// MARK: - Paywall View
struct PaywallView: View {
    // MARK: - Properties
    @StateObject private var viewModel = PaywallViewModel()
    @Environment(\.dismiss) private var dismiss

    // MARK: - View Body
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    headerSection

                    // Features
                    featuresSection

                    // Plans
                    plansSection

                    // Purchase Button
                    purchaseButton

                    // Footer
                    footerSection
                }
                .padding(.horizontal, AppSpacing.screenHorizontal)
                .padding(.bottom, 32)
            }
            .background(AppColors.background)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(AppColors.textTertiary)
                    }
                }
            }
            .alert(String(localized: "paywall_success_title"), isPresented: $viewModel.purchaseSuccess) {
                Button(String(localized: "action_ok")) {
                    dismiss()
                }
            } message: {
                Text(String(localized: "paywall_success_message"))
            }
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Crown Icon
            ZStack {
                Circle()
                    .fill(AppColors.accent.opacity(0.2))
                    .frame(width: 100, height: 100)

                Image(systemName: "crown.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppColors.accent, Color(hex: "FBBF24")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            // Text
            VStack(spacing: 8) {
                Text(String(localized: "paywall_title"))
                    .font(AppFonts.title())
                    .foregroundStyle(AppColors.textPrimary)

                Text(String(localized: "paywall_subtitle"))
                    .font(AppFonts.body())
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(.top, 20)
    }

    // MARK: - Features Section
    private var featuresSection: some View {
        VStack(spacing: 12) {
            ForEach(viewModel.features, id: \.title) { feature in
                HStack(spacing: 12) {
                    Image(systemName: feature.icon)
                        .font(.system(size: 18))
                        .foregroundStyle(AppColors.accent)
                        .frame(width: 36, height: 36)
                        .background(AppColors.accent.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(String(localized: String.LocalizationValue(feature.title)))
                            .font(AppFonts.body())
                            .foregroundStyle(AppColors.textPrimary)

                        Text(String(localized: String.LocalizationValue(feature.description)))
                            .font(AppFonts.caption())
                            .foregroundStyle(AppColors.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(AppColors.success)
                }
            }
        }
        .padding()
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Plans Section
    private var plansSection: some View {
        VStack(spacing: 12) {
            ForEach(viewModel.plans) { plan in
                PlanCard(
                    plan: plan,
                    isSelected: viewModel.selectedPlan == plan.id,
                    onTap: { viewModel.selectPlan(plan.id) }
                )
            }
        }
    }

    // MARK: - Purchase Button
    private var purchaseButton: some View {
        VStack(spacing: 12) {
            AppButton(
                title: String(localized: "paywall_subscribe"),
                style: .primary,
                isLoading: viewModel.isPurchasing
            ) {
                Task {
                    await viewModel.purchase()
                }
            }

            if let error = viewModel.errorMessage {
                Text(error)
                    .font(AppFonts.caption())
                    .foregroundStyle(AppColors.error)
            }
        }
    }

    // MARK: - Footer Section
    private var footerSection: some View {
        VStack(spacing: 16) {
            // Restore
            Button {
                Task {
                    await viewModel.restorePurchases()
                }
            } label: {
                Text(String(localized: "paywall_restore"))
                    .font(AppFonts.subheadline())
                    .foregroundStyle(AppColors.textSecondary)
            }
            .disabled(viewModel.isLoading)

            // Legal
            Link(String(localized: "settings_privacy"), destination: URL(string: AppConstants.privacyPolicyURL)!)
                .font(AppFonts.caption())
                .foregroundStyle(AppColors.textTertiary)

            // Subscription Info
            Text(String(localized: "paywall_info"))
                .font(AppFonts.caption2())
                .foregroundStyle(AppColors.textTertiary)
                .multilineTextAlignment(.center)
        }
    }
}

// MARK: - Plan Card
struct PlanCard: View {
    let plan: SubscriptionPlan
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Selection Circle
                ZStack {
                    Circle()
                        .stroke(isSelected ? AppColors.primary : AppColors.surfaceSecondary, lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(AppColors.primary)
                            .frame(width: 16, height: 16)
                    }
                }

                // Plan Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(String(localized: String.LocalizationValue(plan.title)))
                            .font(AppFonts.headline())
                            .foregroundStyle(AppColors.textPrimary)

                        if plan.isPopular {
                            Text(String(localized: "paywall_popular"))
                                .font(AppFonts.caption2())
                                .fontWeight(.bold)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(AppColors.accent)
                                .clipShape(Capsule())
                        }
                    }

                    Text(String(localized: String.LocalizationValue(plan.period)))
                        .font(AppFonts.caption())
                        .foregroundStyle(AppColors.textSecondary)
                }

                Spacer()

                // Price
                VStack(alignment: .trailing, spacing: 2) {
                    Text(plan.price)
                        .font(AppFonts.headline())
                        .foregroundStyle(AppColors.textPrimary)

                    if let savings = plan.savings {
                        Text(String(localized: String.LocalizationValue(savings)))
                            .font(AppFonts.caption())
                            .foregroundStyle(AppColors.success)
                    }
                }
            }
            .padding()
            .background(isSelected ? AppColors.primary.opacity(0.1) : AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isSelected ? AppColors.primary : .clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}