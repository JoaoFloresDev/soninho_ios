//
//  soninhoApp.swift
//  soninho
//
//  Created by João Flores on 28/01/26.
//

import SwiftUI
import UserNotifications

@main
struct SoninhoApp: App {
    // MARK: - Properties
    @StateObject private var storageService = StorageService.shared
    @StateObject private var purchaseService = PurchaseService.shared
    @StateObject private var notificationService = NotificationService.shared
    @StateObject private var reviewService = ReviewService.shared
    @State private var isOnboardingComplete: Bool
    @Environment(\.scenePhase) private var scenePhase

    // MARK: - Init
    init() {
        _isOnboardingComplete = State(initialValue: StorageService.shared.hasCompletedOnboarding)
        configureAppearance()
        configureNotifications()
    }

    // MARK: - View Body
    var body: some Scene {
        WindowGroup {
            Group {
                if isOnboardingComplete {
                    MainTabView()
                        .environmentObject(storageService)
                        .environmentObject(purchaseService)
                        .environmentObject(notificationService)
                } else {
                    OnboardingView(isOnboardingComplete: $isOnboardingComplete)
                        .environmentObject(storageService)
                }
            }
            .preferredColorScheme(.dark)
            .onChange(of: isOnboardingComplete) { _, newValue in
                storageService.hasCompletedOnboarding = newValue
            }
            .onChange(of: scenePhase) { _, newPhase in
                handleScenePhaseChange(newPhase)
            }
            .onAppear {
                handleAppLaunch()
            }
        }
    }

    // MARK: - App Lifecycle
    private func handleAppLaunch() {
        // Increment app open count
        reviewService.incrementAppOpenCount()

        // Request review if appropriate (between 5th and 10th launch)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            reviewService.requestReviewIfAppropriate()
        }
    }

    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .active:
            // App became active
            Task {
                await notificationService.checkAuthorizationStatus()
            }
        case .inactive:
            break
        case .background:
            break
        @unknown default:
            break
        }
    }

    // MARK: - Configuration
    private func configureNotifications() {
        // Set notification delegate
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }

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
