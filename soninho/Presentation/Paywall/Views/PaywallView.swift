//
//  PaywallView.swift
//  soninho
//
//  Sunrise Premium paywall: unlocks the shake, typing and memory wake-up
//  missions. Same layout as the lab's App Locker paywall (pulsing
//  hero, benefit rows, radio plan cards), black with sunrise-orange accents.
//  StoreKit comes from PaywallKit's StoreKitManager.
//

import SwiftUI
import StoreKit
import PaywallKit

// MARK: - Paywall View
struct PaywallView: View {
    // MARK: - Types
    /// `.offer` sells; `.owned` is the premium state a subscriber opens from Settings.
    enum Mode {
        case offer
        case owned
    }

    private enum Plan {
        case yearly
        case weekly
    }

    // MARK: - Constants
    private static let closeDelay: TimeInterval = 1.0
    /// Black dominant, like the app and its icon. Orange is only an accent: a soft
    /// sunrise glow behind the icon, the selected plan and the CTA.
    private static let background = Color(hex: "0B0907")
    private static let sunriseGlow = RadialGradient(
        colors: [Color(hex: "F4511E").opacity(0.38), Color(hex: "F4511E").opacity(0.10), .clear],
        center: UnitPoint(x: 0.5, y: 0.07),
        startRadius: 10,
        endRadius: 320
    )
    private static let accent = Color(hex: "FF6E40")
    private static let badgeColor = Color(hex: "FFD54F")
    private static let mascotSize: CGFloat = 110
    private static let manageSubscriptionsURL = "https://apps.apple.com/account/subscriptions"

    // MARK: - Properties
    @Binding var isPresented: Bool
    var mode: Mode = .offer
    /// Shown as the last onboarding step: after buying, the main action leads into the app.
    var isOnboarding = false
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
    /// Set when THIS screen started a purchase: that premium flip is a new subscriber to
    /// welcome. A restore (or a renewal arriving) flips premium too and just closes.
    @State private var didStartPurchase = false
    @State private var isCelebrating = false
    @State private var celebratePop = false

    // MARK: - Computed Properties
    /// The purchased look: a subscriber opening it, or the moment right after buying.
    private var showsOwned: Bool { mode == .owned || isCelebrating }

    private var title: String {
        if isCelebrating { return String(localized: "paywall.welcome.title") }
        return mode == .owned ? String(localized: "paywall.owned.title") : String(localized: "paywall.headline")
    }

    private var subtitle: String? {
        if isCelebrating { return String(localized: "paywall.welcome.subtitle") }
        return mode == .owned ? String(localized: "paywall.owned.subtitle") : nil
    }

    private var selectedProduct: Product? {
        selectedPlan == .yearly ? store.yearlyProduct : store.weeklyProduct
    }

    private var ctaTitle: String {
        guard let product = selectedProduct, PaywallContent.trialDays(of: product) != nil else {
            return String(localized: "paywall.continue")
        }
        return String(localized: "paywall.startTrial")
    }

    // MARK: - View Body
    var body: some View {
        ZStack(alignment: .topLeading) {
            Self.background.ignoresSafeArea()
            Self.sunriseGlow.ignoresSafeArea()

            // Three blocks: title pinned to the top, plans + CTA + links pinned to the
            // bottom, benefits centered in the space between. Scrolls only when the
            // screen is too short to fit everything.
            GeometryReader { geo in
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        header
                        Spacer(minLength: 24)
                        benefits
                        Spacer(minLength: 24)
                        if showsOwned {
                            ownedFooter
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                        } else {
                            VStack(spacing: 0) {
                                plans
                                ctaButton
                                footer
                            }
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                        }
                    }
                    .frame(maxWidth: 520)
                    .frame(maxWidth: .infinity, minHeight: geo.size.height)
                }
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
        // A purchase made here turns this screen into the premium state; a restore or
        // an entitlement arriving on its own just closes the offer.
        .onChange(of: store.isPremium) { _, premium in
            guard premium, mode == .offer, !isCelebrating else { return }
            if didStartPurchase {
                celebrate()
            } else {
                isPresented = false
            }
        }
    }

    // MARK: - Header
    private var header: some View {
        VStack(spacing: 14) {
            Image("heroWake2")
                .resizable()
                .scaledToFit()
                .frame(width: Self.mascotSize, height: Self.mascotSize)
                .scaleEffect(celebratePop ? 1.22 : (iconPulse ? 1.04 : 1.0))
                // A few beats, then still: an endless animation keeps the UI from ever
                // settling, which stalls UI test drivers on this screen.
                .animation(.easeInOut(duration: 1.2).repeatCount(5, autoreverses: true), value: iconPulse)
                .accessibilityHidden(true)
                .padding(.top, 8)

            Text(title)
                .font(AppFonts.display(30, weight: .heavy))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 28)
                .id(title)
                .transition(.opacity.combined(with: .scale(scale: 0.92)))

            if let subtitle {
                Text(subtitle)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 32)
                    .id(subtitle)
                    .transition(.opacity)
            }
        }
        .opacity(showHeader ? 1 : 0)
        .offset(y: showHeader ? 0 : 20)
    }

    // MARK: - Benefits
    private var benefits: some View {
        VStack(alignment: .leading, spacing: 18) {
            ForEach(PaywallContent.benefits) { benefit in
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Self.badgeColor)
                        .padding(.top, 1)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(benefit.title)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(.white)
                        if !benefit.detail.isEmpty {
                            Text(benefit.detail)
                                .font(.system(size: 14))
                                .foregroundStyle(.white.opacity(0.7))
                        }
                    }
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .padding(.horizontal, 32)
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
        .padding(.bottom, 20)
        .opacity(showPlans ? 1 : 0)
        .offset(y: showPlans ? 0 : 20)
    }

    private func planCard(plan: Plan, title: String, product: Product, period: String) -> some View {
        let isSelected = selectedPlan == plan
        let trial = PaywallContent.trialDays(of: product)
        return Button {
            HapticManager.selection()
            selectedPlan = plan
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .stroke(isSelected ? Self.accent : .white.opacity(0.5), lineWidth: 2)
                        .frame(width: 24, height: 24)
                    if isSelected {
                        Circle()
                            .fill(Self.accent)
                            .frame(width: 12, height: 12)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(AppFonts.title3(18, weight: .bold))
                        .foregroundStyle(.white)
                        .fixedSize(horizontal: false, vertical: true)

                    // Only the plan that really has a free trial gets a badge.
                    if let trial {
                        Text(String(localized: "paywall.badge.trial \(trial)"))
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
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
                        .font(AppFonts.title2(19, weight: .bold))
                        .foregroundStyle(.white)
                    Text(period)
                        .font(.system(size: 12))
                        .foregroundStyle(.white.opacity(0.85))
                }
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .frame(minHeight: 44)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? Self.accent.opacity(0.12) : .white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isSelected ? Self.accent : .white.opacity(0.10), lineWidth: isSelected ? 2 : 1)
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
        purchaseButton
            .padding(.horizontal, 20)
            .padding(.bottom, 14)
            .opacity(showButton ? 1 : 0)
            .offset(y: showButton ? 0 : 20)
    }

    private var purchaseButton: some View {
        Button(action: purchase) {
            ZStack {
                if store.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(ctaTitle)
                        .font(AppFonts.headline(17, weight: .bold))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 52)
            .background(RoundedRectangle(cornerRadius: 14).fill(AppColors.primaryButtonGradient))
        }
        .buttonStyle(.plain)
        .disabled(store.isLoading || selectedProduct == nil)
        .opacity(store.isLoading || selectedProduct == nil ? 0.6 : 1)
        .accessibilityIdentifier("paywall.purchase")
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

    // MARK: - Owned Footer
    /// Subscriber state: rating is the main action ("Get started" right after buying in the
    /// onboarding); managing the plan sits with the legal links.
    private var ownedFooter: some View {
        VStack(spacing: 0) {
            Button(action: startsApp ? startApp : openWriteReview) {
                HStack(spacing: 8) {
                    if !startsApp {
                        Image(systemName: "star.fill")
                            .font(.system(size: 15, weight: .bold))
                    }
                    Text(primaryOwnedTitle)
                        .font(AppFonts.headline(17, weight: .bold))
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, minHeight: 52)
                .background(RoundedRectangle(cornerRadius: 14).fill(AppColors.primaryButtonGradient))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier(startsApp ? "paywall.start" : "paywall.rate")
            .accessibilityLabel(primaryOwnedTitle)
            .padding(.horizontal, 20)
            .padding(.bottom, 14)

            // One row when it fits; a very long locale puts "manage" on its own line.
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 10) {
                    manageLink
                    dot
                    legalLinks
                }
                VStack(spacing: 0) {
                    manageLink
                    legalLinks
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 24)
        }
    }

    /// Just bought from the onboarding: the next step is the app, not a review.
    private var startsApp: Bool { isOnboarding && isCelebrating }

    private var primaryOwnedTitle: String {
        startsApp ? String(localized: "onboarding_get_started") : String(localized: "paywall.rate")
    }

    private var manageLink: some View {
        footerLink(String(localized: "paywall.manage.short"), id: "paywall.manage", action: openManageSubscriptions)
            .accessibilityLabel(String(localized: "paywall.manage"))
    }

    private var legalLinks: some View {
        HStack(spacing: 10) {
            footerLink(String(localized: "paywall.privacy"), id: "paywall.privacy") {
                if let url = URL(string: AppConstants.privacyPolicyURL) { openURL(url) }
            }
            dot
            footerLink(String(localized: "paywall.termsOfUse"), id: "paywall.terms") {
                if let url = URL(string: AppConstants.termsOfUseURL) { openURL(url) }
            }
        }
    }

    // MARK: - Close
    private var closeButton: some View {
        Button {
            Analytics.log("paywall_dismissed", ["placement": "sunrise_paywall", "source": PaywallAnalytics.source])
            isPresented = false
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.white.opacity(0.5))
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
        if mode == .owned {
            // Not paywall_shown: that event counts people ASKED to buy.
            Analytics.featureUsed("premium_status_shown", source: PaywallAnalytics.source)
            withAnimation(.easeIn(duration: 0.3)) { showClose = true }
        } else if !store.isPremium {
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
        didStartPurchase = true
        Task {
            do {
                _ = try await store.purchase(product)
                // The premium flip can land before or after purchase() returns.
                if store.isPremium { celebrate() } else { didStartPurchase = false }
            } catch {
                didStartPurchase = false
                errorMessage = error.localizedDescription
            }
        }
    }

    /// Turns the offer into the premium state in place instead of closing it.
    private func celebrate() {
        guard !isCelebrating else { return }
        HapticManager.success()
        Analytics.featureUsed("premium_welcome_shown", source: PaywallAnalytics.source)
        withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) {
            isCelebrating = true
            showClose = false
        }
        withAnimation(.spring(response: 0.45, dampingFraction: 0.5)) { celebratePop = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { celebratePop = false }
        }
        // No "Continue" in the subscriber state, so the X is the way back into the app.
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.closeDelay) {
            withAnimation(.easeIn(duration: 0.3)) { showClose = true }
        }
    }

    private func startApp() {
        HapticManager.selection()
        Analytics.featureUsed("premium_welcome_start", source: PaywallAnalytics.source)
        isPresented = false
    }

    private func openWriteReview() {
        HapticManager.selection()
        Analytics.featureUsed("rate_app", source: "paywall_owned")
        ReviewService.shared.openWriteReview()
    }

    private func openManageSubscriptions() {
        Analytics.featureUsed("manage_subscription", source: "paywall_owned")
        if let url = URL(string: Self.manageSubscriptionsURL) { openURL(url) }
    }

    private func restore() {
        Task {
            await store.restorePurchases()
            if !store.isPremium { showNothingRestored = true }
        }
    }
}
