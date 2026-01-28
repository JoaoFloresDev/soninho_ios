//
//  PurchaseService.swift
//  soninho
//
//  Created by João Flores on 28/01/26.
//

import Foundation
import StoreKit

// MARK: - Store Error
enum StoreError: LocalizedError {
    case failedVerification
    case productNotFound
    case purchaseFailed

    var errorDescription: String? {
        switch self {
        case .failedVerification:
            return String(localized: "store_error_verification")
        case .productNotFound:
            return String(localized: "store_error_not_found")
        case .purchaseFailed:
            return String(localized: "store_error_failed")
        }
    }
}

// MARK: - Purchase Service
@MainActor
final class PurchaseService: ObservableObject {
    // MARK: - Singleton
    static let shared = PurchaseService()

    // MARK: - Published Properties
    @Published private(set) var isPremium = false
    @Published private(set) var products: [Product] = []
    @Published private(set) var purchasedProductIDs: Set<String> = []
    @Published private(set) var isLoading = false

    // MARK: - Constants
    private let productIDs = [
        AppConstants.monthlyProductId,
        AppConstants.annualProductId
    ]

    // MARK: - Private Properties
    private var updateListenerTask: Task<Void, Error>?

    // MARK: - Computed Properties
    var monthlyProduct: Product? {
        products.first { $0.id == AppConstants.monthlyProductId }
    }

    var annualProduct: Product? {
        products.first { $0.id == AppConstants.annualProductId }
    }

    // MARK: - Init
    private init() {
        // Only setup purchases if feature flag is enabled
        guard AppConstants.isPurchasesEnabled else { return }

        updateListenerTask = listenForTransactions()

        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // MARK: - Public Methods
    func loadProducts() async {
        isLoading = true

        do {
            products = try await Product.products(for: productIDs)
                .sorted { $0.price < $1.price }
        } catch {
            print("Failed to load products: \(error)")
        }

        isLoading = false
    }

    func purchase(_ product: Product) async throws -> Bool {
        isLoading = true
        defer { isLoading = false }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await updatePurchasedProducts()
            await transaction.finish()
            return true

        case .userCancelled:
            return false

        case .pending:
            return false

        @unknown default:
            return false
        }
    }

    func restorePurchases() async throws {
        isLoading = true
        defer { isLoading = false }

        try await AppStore.sync()
        await updatePurchasedProducts()
    }

    func checkPurchaseStatus() async {
        await updatePurchasedProducts()
    }

    // MARK: - Private Methods
    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                do {
                    let transaction = try self?.checkVerified(result)
                    await self?.updatePurchasedProducts()
                    await transaction?.finish()
                } catch {
                    print("Transaction failed verification: \(error)")
                }
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }

    private func updatePurchasedProducts() async {
        var purchased: Set<String> = []

        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                if transaction.revocationDate == nil {
                    purchased.insert(transaction.productID)
                }
            }
        }

        purchasedProductIDs = purchased
        isPremium = !purchased.isEmpty

        // Update storage
        StorageService.shared.isPremiumUser = isPremium
    }
}

// MARK: - Product Extension
extension Product {
    var formattedPrice: String {
        displayPrice
    }

    var periodDescription: String {
        guard let subscription = subscription else { return "" }

        switch subscription.subscriptionPeriod.unit {
        case .month:
            if subscription.subscriptionPeriod.value == 1 {
                return String(localized: "subscription_monthly")
            }
            return String(localized: "subscription_months \(subscription.subscriptionPeriod.value)")
        case .year:
            if subscription.subscriptionPeriod.value == 1 {
                return String(localized: "subscription_yearly")
            }
            return String(localized: "subscription_years \(subscription.subscriptionPeriod.value)")
        case .week:
            return String(localized: "subscription_weekly")
        case .day:
            return String(localized: "subscription_daily")
        @unknown default:
            return ""
        }
    }
}
