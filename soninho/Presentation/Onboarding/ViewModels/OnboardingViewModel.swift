//
//  OnboardingViewModel.swift
//  soninho
//
//  Created by João Flores on 28/01/26.
//

import Foundation

// MARK: - Onboarding Page
struct OnboardingPage: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let subtitle: String
    let gradient: [String]
}

// MARK: - Onboarding ViewModel
@MainActor
final class OnboardingViewModel: ObservableObject {
    // MARK: - Dependencies
    private let storageService: StorageService
    private let healthKitService: HealthKitService

    // MARK: - Published Properties
    @Published var currentPage = 0
    @Published var isRequestingHealthKit = false

    // MARK: - Properties
    let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "moon.stars.fill",
            title: "onboarding_title_1",
            subtitle: "onboarding_subtitle_1",
            gradient: ["6366F1", "8B5CF6"]
        ),
        OnboardingPage(
            icon: "chart.bar.fill",
            title: "onboarding_title_2",
            subtitle: "onboarding_subtitle_2",
            gradient: ["3B82F6", "60A5FA"]
        ),
        OnboardingPage(
            icon: "alarm.fill",
            title: "onboarding_title_3",
            subtitle: "onboarding_subtitle_3",
            gradient: ["F59E0B", "FBBF24"]
        ),
        OnboardingPage(
            icon: "heart.fill",
            title: "onboarding_title_4",
            subtitle: "onboarding_subtitle_4",
            gradient: ["22C55E", "4ADE80"]
        )
    ]

    var isLastPage: Bool {
        currentPage == pages.count - 1
    }

    // MARK: - Init
    init(
        storageService: StorageService = .shared,
        healthKitService: HealthKitService = .shared
    ) {
        self.storageService = storageService
        self.healthKitService = healthKitService
    }

    // MARK: - Public Methods
    func nextPage() {
        HapticManager.lightImpact()
        if currentPage < pages.count - 1 {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                currentPage += 1
            }
        }
    }

    func previousPage() {
        HapticManager.lightImpact()
        if currentPage > 0 {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                currentPage -= 1
            }
        }
    }

    func skipToEnd() {
        HapticManager.lightImpact()
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            currentPage = pages.count - 1
        }
    }

    func completeOnboarding() async {
        HapticManager.success()

        // Request HealthKit permission
        isRequestingHealthKit = true
        do {
            try await healthKitService.requestAuthorization()
        } catch {
            print("HealthKit authorization error: \(error)")
        }
        isRequestingHealthKit = false

        // Mark onboarding complete
        storageService.hasCompletedOnboarding = true
        storageService.incrementSessionCount()
    }
}
