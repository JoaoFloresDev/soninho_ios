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
        let skipOnboarding = StorageService.shared.hasCompletedOnboarding
        _isOnboardingComplete = State(initialValue: skipOnboarding)
        configureAppearance()
        configureNotifications()
        AlarmSoundGenerator.generateAlarmSoundsIfNeeded()
        // Prepare audio session early so background audio works immediately
        BackgroundAlarmPlayer.shared.prepare()
    }

    // MARK: - View Body
    var body: some Scene {
        WindowGroup {
            ZStack {
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

                // Full-screen alarm overlay
                if notificationService.isAlarmRinging {
                    AlarmRingingView()
                        .environmentObject(notificationService)
                        .transition(.opacity.combined(with: .scale(scale: 1.05)))
                        .zIndex(100)
                }
            }
            .animation(.spring(response: 0.4), value: notificationService.isAlarmRinging)
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
        // Attach the hidden volume control so the alarm can blast at max volume.
        SystemVolume.prepare()

        // Auto-start the sleep night at bedtime while the app is in foreground.
        SleepAutoStart.startForegroundMonitor()

        // Increment app open count
        reviewService.incrementAppOpenCount()

        // Schedule all enabled alarms on every app launch
        Task {
            await notificationService.scheduleAllEnabledAlarms()
        }

        // Request review if appropriate (between 5th and 10th launch)
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            reviewService.requestReviewIfAppropriate()
        }
    }

    private func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .active:
            // Stop background keep-alive when app is fully in foreground
            BackgroundAlarmPlayer.shared.stopBackgroundKeepAlive()
            Task {
                await notificationService.checkAuthorizationStatus()
                await notificationService.scheduleAllEnabledAlarms()
            }
        case .inactive:
            // Phone is being locked or app is switching — start background keep-alive NOW
            // This is critical: must start BEFORE .background to ensure audio session is ready
            BackgroundAlarmPlayer.shared.startBackgroundKeepAlive()
        case .background:
            // Ensure background keep-alive is running
            if !BackgroundAlarmPlayer.shared.isBackgroundActive {
                BackgroundAlarmPlayer.shared.startBackgroundKeepAlive()
            }
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
        navigationBarAppearance.shadowColor = .clear
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
