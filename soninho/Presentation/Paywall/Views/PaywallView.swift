//
//  PaywallView.swift
//  soninho
//
//  Sunrise Premium paywall: unlocks the shake, typing and memory wake-up
//  missions. Same layout as the lab's App Locker paywall (gradient, pulsing
//  hero, benefit rows, radio plan cards, white CTA), in the sunrise palette.
//  StoreKit comes from PaywallKit's StoreKitManager.
//

import SwiftUI
import StoreKit
import PaywallKit

// MARK: - Paywall View
struct PaywallView: View {
    // MARK: - Types
    private enum Plan {
        case yearly
        case weekly
    }

    // MARK: - Constants
    private static let closeDelay: TimeInterval = 3.0
    private static let gradient = LinearGradient(
        colors: [Color(hex: "FF8A50"), Color(hex: "F4511E"), Color(hex: "A8320C")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    private static let badgeColor = Color(hex: "FFD54F")

    // MARK: - Properties
    @Binding var isPresented: Bool
    @ObservedObject private var store = StoreKitManager.shared
    @Environment(\.openURL) private var openURL

    // MARK: - State
    @State private var selectedPlan: Plan = .yearly
    @State private var showClose = false
    @State private var showHeader = false
    @State private var showBenefits = false
    @State private var showPlans = false
    @State private var showButton = false
    @State private var iconPulse = false
    @State private var errorMessage: String?
    @State private var showNothingRestored = false

    // MARK: - Computed Properties
    private var selectedProduct: Product? {
        selectedPlan == .yearly ? store.yearlyProduct : store.weeklyProduct
    }

    private var ctaTitle: String {
        guard let product = selectedProduct, Self.trialDays(of: product) != nil else {
            return String(localized: "paywall.continue")
        }
        return String(localized: "paywall.startTrial")
    }

    // MARK: - View Body
    var body: some View {
        ZStack(alignment: .topLeading) {
            Self.gradient.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    header
                    benefits
                    plans
                    ctaButton
                    footer
                }
                .frame(maxWidth: 520)
                .frame(maxWidth: .infinity)
            }

            if showClose {
                closeButton
                    .transition(.opacity)
            }
        }
        .preferredColorScheme(.dark)
        .alert(String(localized: "paywall.purchaseFailed"), isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage ?? "")
        }
        .alert(String(localized: "paywall.nothingRestored"), isPresented: $showNothingRestored) {
            Button("OK", role: .cancel) { }
        }
        .onAppear(perform: handleAppear)
        .onChange(of: store.isPremium) { _, premium in
            if premium { isPresented = false }
        }
    }

    // MARK: - Header
    private var header: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Self.badgeColor.opacity(0.22))
                    .frame(width: 96, height: 96)
                    .scaleEffect(iconPulse ? 1.08 : 1.0)
                    // A few beats, then still: an endless animation keeps the UI from ever
                    // settling, which stalls UI test drivers on this screen.
                    .animation(.easeInOut(duration: 1.2).repeatCount(5, autoreverses: true), value: iconPulse)

                Image(systemName: "sunrise.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(Self.badgeColor)
            }
            .padding(.top, 52)

            Text(String(localized: "paywall.title"))
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 28)
        }
        .opacity(showHeader ? 1 : 0)
        .offset(y: showHeader ? 0 : 20)
        .padding(.bottom, 24)
    }

    // MARK: - Benefits
    private var benefits: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(PaywallContent.features) { feature in
                HStack(alignment: .top, spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(.white.opacity(0.2))
                            .frame(width: 36, height: 36)
                        Image(systemName: feature.icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                    }

                    Text(feature.title)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, minHeight: 36, alignment: .leading)
                }
            }
        }
        .padding(.horizontal, 28)
        .padding(.bottom, 26)
        .opacity(showBenefits ? 1 : 0)
        .offset(y: showBenefits ? 0 : 20)
    }

    // MARK: - Plans
    private var plans: some View {
        VStack(spacing: 10) {
            if store.products.isEmpty && store.isLoading {
                VStack(spacing: 16) {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.2)
                    Text(String(localized: "paywall.loading"))
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.8))
                }
                .frame(height: 160)
            } else if store.products.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 28))
                        .foregroundStyle(.white.opacity(0.8))
                    Text(String(localized: "paywall.plansUnavailable"))
                        .font(.system(size: 14))
                        .foregroundStyle(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                    Button {
                        Task { await store.loadProducts() }
                    } label: {
                        Text(String(localized: "paywall.retry"))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 22)
                            .frame(minHeight: 44)
                            .background(Capsule().fill(.white.opacity(0.2)))
                    }
                    .accessibilityIdentifier("paywall.retry")
                }
                .frame(minHeight: 160)
            } else {
                if let yearly = store.yearlyProduct {
                    planCard(
                        plan: .yearly,
                        title: String(localized: "paywall.plan.yearly"),
                        product: yearly,
                        period: String(localized: "paywall.price.perYear")
                    )
                }
                if let weekly = store.weeklyProduct {
                    planCard(
                        plan: .weekly,
                        title: String(localized: "paywall.plan.weekly"),
                        product: weekly,
                        period: String(localized: "paywall.price.perWeek")
                    )
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 28)
        .opacity(showPlans ? 1 : 0)
        .offset(y: showPlans ? 0 : 20)
    }

    private func planCard(plan: Plan, title: String, product: Product, period: String) -> some View {
        let isSelected = selectedPlan == plan
        let trial = Self.trialDays(of: product)
        return Button {
            HapticManager.selection()
            selectedPlan = plan
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .stroke(.white, lineWidth: 2)
                        .frame(width: 24, height: 24)
                    if isSelected {
                        Circle()
                            .fill(.white)
                            .frame(width: 12, height: 12)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)

                    // Only the plan that really has a free trial gets a badge.
                    if let trial {
                        Text(String(localized: "paywall.badge.trial \(trial)"))
                            .font(.system(size: 11, weight: .heavy))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Self.badgeColor))
                    }
                }

                Spacer(minLength: 8)

                // Charged amount is the most prominent price element (Guideline 3.1.2(c)).
                VStack(alignment: .trailing, spacing: 2) {
                    Text(product.displayPrice)
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white)
                    Text(period)
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.85))
                }
            }
            .padding(20)
            .frame(minHeight: 44)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(.white.opacity(isSelected ? 0.25 : 0.14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.white, lineWidth: isSelected ? 2 : 0)
                    )
            )
            .contentShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("paywall.plan.\(plan == .yearly ? "yearly" : "weekly")")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    // MARK: - CTA
    private var ctaButton: some View {
        Button(action: purchase) {
            ZStack {
                if store.isLoading {
                    ProgressView()
                        .tint(AppColors.primaryDark)
                } else {
                    Text(ctaTitle)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(AppColors.primaryDark)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(RoundedRectangle(cornerRadius: 14).fill(.white))
        }
        .buttonStyle(.plain)
        .disabled(store.isLoading || selectedProduct == nil)
        .opacity(store.isLoading || selectedProduct == nil ? 0.6 : 1)
        .accessibilityIdentifier("paywall.purchase")
        .padding(.horizontal, 20)
        .padding(.bottom, 14)
        .opacity(showButton ? 1 : 0)
        .offset(y: showButton ? 0 : 20)
    }

    // MARK: - Footer
    private var footer: some View {
        HStack(spacing: 10) {
            footerLink(String(localized: "paywall.restore"), id: "paywall.restore", action: restore)
            dot
            footerLink(String(localized: "paywall.privacy"), id: "paywall.privacy") {
                if let url = URL(string: AppConstants.privacyPolicyURL) { openURL(url) }
            }
            dot
            footerLink(String(localized: "paywall.termsOfUse"), id: "paywall.terms") {
                if let url = URL(string: AppConstants.termsOfUseURL) { openURL(url) }
            }
        }
        .padding(.bottom, 24)
        .opacity(showButton ? 1 : 0)
    }

    private var dot: some View {
        Text("·").foregroundStyle(.white.opacity(0.5))
    }

    private func footerLink(_ title: String, id: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.8))
                .frame(minHeight: 44)
        }
        .disabled(store.isLoading)
        .accessibilityIdentifier(id)
    }

    // MARK: - Close
    private var closeButton: some View {
        Button {
            Analytics.log("paywall_dismissed", ["placement": "sunrise_paywall", "source": PaywallAnalytics.source])
            isPresented = false
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white.opacity(0.6))
                .frame(width: 44, height: 44)
        }
        .padding(.leading, 8)
        .padding(.top, 4)
        .accessibilityIdentifier("paywall.close")
        .accessibilityLabel(String(localized: "paywall.close"))
    }

    // MARK: - Actions
    private func handleAppear() {
        Analytics.screen("paywall")
        if !store.isPremium {
            Analytics.log("paywall_shown", ["placement": "sunrise_paywall", "source": PaywallAnalytics.source])
        }
        if store.products.isEmpty && !store.isLoading {
            Task { await store.loadProducts() }
        }
        withAnimation(.easeOut(duration: 0.5)) { showHeader = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeOut(duration: 0.5)) { showBenefits = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeOut(duration: 0.5)) { showPlans = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            withAnimation(.easeOut(duration: 0.5)) { showButton = true }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            iconPulse = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.closeDelay) {
            withAnimation(.easeIn(duration: 0.3)) { showClose = true }
        }
    }

    private func purchase() {
        guard let product = selectedProduct else { return }
        HapticManager.mediumImpact()
        Task {
            do {
                // Success flips store.isPremium, which dismisses the paywall.
                _ = try await store.purchase(product)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func restore() {
        Task {
            await store.restorePurchases()
            if !store.isPremium { showNothingRestored = true }
        }
    }

    // MARK: - Helpers
    /// Free-trial length in days, or nil when the product has no free trial.
    private static func trialDays(of product: Product) -> Int? {
        guard let offer = product.subscription?.introductoryOffer,
              offer.paymentMode == .freeTrial else { return nil }
        let value = offer.period.value
        switch offer.period.unit {
        case .day: return value
        case .week: return value * 7
        case .month: return value * 30
        case .year: return value * 365
        @unknown default: return nil
        }
    }
}

// MARK: - Paywall Content
enum PaywallContent {
    // MARK: - Types
    struct Feature: Identifiable {
        let id = UUID()
        let title: String
        let icon: String
    }

    // MARK: - Computed Properties
    static var features: [Feature] {
        [
            Feature(title: String(localized: "paywall.feature.1"), icon: WakeMission.shake.icon),
            Feature(title: String(localized: "paywall.feature.2"), icon: WakeMission.typing.icon),
            Feature(title: String(localized: "paywall.feature.3"), icon: WakeMission.memory.icon),
            Feature(title: String(localized: "paywall.feature.4"), icon: "alarm.fill")
        ]
    }
}
