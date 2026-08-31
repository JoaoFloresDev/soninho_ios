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
    @State private var isOnboardingComplete: Bool
    @Environment(\.scenePhase) private var scenePhase

    // MARK: - Init
    init() {
        Analytics.configure()

        let skipOnboarding = StorageService.shared.hasCompletedOnboarding
        _isOnboardingComplete = State(initialValue: skipOnboarding)
        configureAppearance()
        configureNotifications()
        // Generating the 10 alarm WAVs takes seconds on first launch — off the
        // main thread, or the launch screen hangs. Alarms fire much later, so
        // the files are ready long before any notification needs them.
        Task.detached(priority: .userInitiated) {
            AlarmSoundGenerator.generateAlarmSoundsIfNeeded()
        }
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
                            .transition(.move(edge: .trailing))
                    } else {
                        OnboardingView(isOnboardingComplete: $isOnboardingComplete)
                            .environmentObject(storageService)
                            .transition(.move(edge: .leading))
                    }
                }
                // Leaving onboarding reads as a push forward, not a cross-fade.
                .animation(.easeInOut(duration: 0.45), value: isOnboardingComplete)

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
            .ratingGate()
            .onChange(of: isOnboardingComplete) { _, newValue in
                storageService.hasCompletedOnboarding = newValue
            }
            .onChange(of: scenePhase) { _, newPhase in
                handleScenePhaseChange(newPhase)
            }
            .onReceive(NotificationCenter.default.publisher(for: .didCompleteAlarm)) { _ in
                // Waking up with the alarm is the aha-moment — count it towards
                // the rating gate once the ringing screen has gone away.
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    RatingGateService.shared.recordPositiveEvent()
                }
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

        // Schedule all enabled alarms on every app launch
        Task {
            await notificationService.scheduleAllEnabledAlarms()
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
        // Page control
        UIPageControl.appearance().currentPageIndicatorTintColor = UIColor(AppColors.primary)
        UIPageControl.appearance().pageIndicatorTintColor = UIColor(AppColors.surfaceSecondary)

        // iOS 26 draws the navigation and tab bars in Liquid Glass; an opaque
        // custom appearance would replace the glass with a flat bar.
        if #available(iOS 26.0, *) { return }

        let navigationBarAppearance = UINavigationBarAppearance()
        navigationBarAppearance.configureWithOpaqueBackground()
        navigationBarAppearance.backgroundColor = UIColor(AppColors.background)
        navigationBarAppearance.shadowColor = .clear
        navigationBarAppearance.titleTextAttributes = [.foregroundColor: UIColor(AppColors.textPrimary)]
        navigationBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor(AppColors.textPrimary)]

        UINavigationBar.appearance().standardAppearance = navigationBarAppearance
        UINavigationBar.appearance().compactAppearance = navigationBarAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navigationBarAppearance

        let tabBarAppearance = UITabBarAppearance()
        tabBarAppearance.configureWithOpaqueBackground()
        tabBarAppearance.backgroundColor = UIColor(AppColors.surface)

        UITabBar.appearance().standardAppearance = tabBarAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabBarAppearance
    }
}
