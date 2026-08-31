//
//  OnboardingViewModel.swift
//  soninho
//
//  Created by João Flores on 28/01/26.
//

import Foundation
import SwiftUI

// MARK: - Onboarding Page
struct OnboardingPage: Identifiable {
    let id = UUID()
    let heroImage: String
    let title: String
    let subtitle: String
}

// MARK: - Onboarding ViewModel
@MainActor
final class OnboardingViewModel: ObservableObject {
    // MARK: - Dependencies
    private let storageService: StorageService

    // MARK: - Published Properties
    @Published var currentPage = 0

    // MARK: - Properties
    let pages: [OnboardingPage] = [
        OnboardingPage(
            heroImage: "onbHero1",
            title: "onboarding_title_3",
            subtitle: "onboarding_subtitle_3"
        ),
        OnboardingPage(
            heroImage: "onbHero2",
            title: "onboarding_title_1",
            subtitle: "onboarding_subtitle_1"
        ),
        OnboardingPage(
            heroImage: "onbHero3",
            title: "onboarding_title_2",
            subtitle: "onboarding_subtitle_2"
        )
    ]

    var isLastPage: Bool {
        currentPage == pages.count - 1
    }

    // MARK: - Init
    init(storageService: StorageService = .shared) {
        self.storageService = storageService
    }

    // MARK: - Public Methods
    func nextPage() {
        if currentPage < pages.count - 1 {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                currentPage += 1
            }
        }
    }

    func previousPage() {
        if currentPage > 0 {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                currentPage -= 1
            }
        }
    }

    func skipToEnd() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
            currentPage = pages.count - 1
        }
    }

    func completeOnboarding() {
        storageService.hasCompletedOnboarding = true
        storageService.incrementSessionCount()
    }
}
