//
//  PaywallViewModel.swift
//  soninho
//
//  Created by João Flores on 28/01/26.
//

import Foundation
import StoreKit

// MARK: - Subscription Plan
struct SubscriptionPlan: Identifiable {
    let id: String
    let title: String
    let price: String
    let period: String
    let savings: String?
    let isPopular: Bool
}

// MARK: - Paywall ViewModel
@MainActor
final class PaywallViewModel: ObservableObject {
    // MARK: - Dependencies
    private let storageService: StorageService

    // MARK: - Published Properties
    @Published var selectedPlan: String = AppConstants.annualProductId
    @Published var isLoading = false
    @Published var isPurchasing = false
    @Published var errorMessage: String?
    @Published var purchaseSuccess = false

    // MARK: - Properties
    let plans: [SubscriptionPlan] = [
        SubscriptionPlan(
            id: AppConstants.annualProductId,
            title: "paywall_annual_title",
            price: "R$ 99,90",
            period: "paywall_annual_period",
            savings: "paywall_annual_savings",
            isPopular: true
        ),
        SubscriptionPlan(
            id: AppConstants.monthlyProductId,
            title: "paywall_monthly_title",
            price: "R$ 15,90",
            period: "paywall_monthly_period",
            savings: nil,
            isPopular: false
        )
    ]

    let features: [(icon: String, title: String, description: String)] = [
        ("chart.bar.fill", "paywall_feature_1_title", "paywall_feature_1_desc"),
        ("brain.head.profile", "paywall_feature_2_title", "paywall_feature_2_desc"),
        ("bell.badge.fill", "paywall_feature_3_title", "paywall_feature_3_desc"),
        ("heart.text.square.fill", "paywall_feature_4_title", "paywall_feature_4_desc"),
        ("icloud.fill", "paywall_feature_5_title", "paywall_feature_5_desc")
    ]

    // MARK: - Init
    init(storageService: StorageService = .shared) {
        self.storageService = storageService
    }

    // MARK: - Public Methods
    func selectPlan(_ planId: String) {
        HapticManager.selection()
        selectedPlan = planId
    }

    func purchase() async {
        HapticManager.mediumImpact()
        isPurchasing = true
        errorMessage = nil

        // Simulate purchase (replace with actual StoreKit implementation)
        do {
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds

            // In production, use StoreKit 2:
            // let product = try await Product.products(for: [selectedPlan]).first
            // let result = try await product?.purchase()

            // For demo, just mark as premium
            storageService.isPremiumUser = true
            purchaseSuccess = true
            HapticManager.success()
        } catch {
            errorMessage = error.localizedDescription
            HapticManager.error()
        }

        isPurchasing = false
    }

    func restorePurchases() async {
        HapticManager.mediumImpact()
        isLoading = true
        errorMessage = nil

        do {
            try await Task.sleep(nanoseconds: 1_500_000_000)

            // In production:
            // try await AppStore.sync()

            // Check if user has active subscription
            // For demo:
            // storageService.isPremiumUser = true
            HapticManager.success()
        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
