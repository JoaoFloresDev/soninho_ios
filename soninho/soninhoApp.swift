//
//  soninhoApp.swift
//  soninho
//
//  Created by João Flores on 28/01/26.
//

import SwiftUI

@main
struct SoninhoApp: App {
    // MARK: - Properties
    @StateObject private var storageService = StorageService.shared
    @StateObject private var purchaseService = PurchaseService.shared
    @State private var isOnboardingComplete: Bool

    // MARK: - Init
    init() {
        _isOnboardingComplete = State(initialValue: StorageService.shared.hasCompletedOnboarding)
        configureAppearance()
    }

    // MARK: - View Body
    var body: some Scene {
        WindowGroup {
            Group {
                if isOnboardingComplete {
                    MainTabView()
                        .environmentObject(storageService)
                        .environmentObject(purchaseService)
                } else {
                    OnboardingView(isOnboardingComplete: $isOnboardingComplete)
                        .environmentObject(storageService)
                }
            }
            .preferredColorScheme(.dark)
            .onChange(of: isOnboardingComplete) { _, newValue in
                storageService.hasCompletedOnboarding = newValue
            }
        }
    }

    // MARK: - Private Methods
    private func configureAppearance() {
        // Configure navigation bar appearance
        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithOpaqueBackground()
        navigationBarAppearance.backgroundColor = UIColor(AppColors.background)
        navigationBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navigationBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]

        UINavigationBar.appearance().standardAppearance = navigationBarAppearance
        UINavigationBar.appearance().compactAppearance = navigationBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance

        // Configure tab bar appearance
        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(AppColors.surface)

        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance

        // Configure page control
        UIPageControl.appearance().currentPageIndicatorTintColor = UIColor(AppColors.primary)
        UIPageControl.appearance().pageIndicatorTintColor = UIColor(AppColors.surfaceSecondary)
    }
}
