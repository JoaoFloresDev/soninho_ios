//
//  HomeViewModel.swift
//  soninho
//
//  Created by João Flores on 28/01/26.
//

import Foundation
import Combine
import UIKit

// MARK: - Home ViewModel
@MainActor
final class HomeViewModel: ObservableObject {
    // MARK: - Dependencies
    private let healthKitService: HealthKitService
    private let storageService: StorageService

    // MARK: - Published Properties
    @Published private(set) var todaySleep: SleepRecord?
    @Published private(set) var weeklyRecords: [SleepRecord] = []
    @Published private(set) var statistics: SleepStatistics?
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?
    @Published private(set) var greeting: String = ""

    // MARK: - Computed Properties
    var hasError: Bool { errorMessage != nil }
    var hasSleepData: Bool { !weeklyRecords.isEmpty }
    var isHealthKitAvailable: Bool { healthKitService.isHealthKitAvailable }

    var averageSleepDuration: String {
        guard let stats = statistics else { return "--" }
        return stats.averageDuration.hoursMinutesString
    }

    var averageBedtime: String {
        guard let bedtime = statistics?.averageBedtime else { return "--" }
        return bedtime.timeString
    }

    var averageQuality: Int {
        statistics?.averageQualityScore ?? 0
    }

    var sleepTrend: SleepTrend {
        statistics?.sleepTrend ?? .stable
    }

    var nextAlarm: AlarmModel? {
        storageService.loadAlarms().first { $0.isEnabled }
    }

    var currentStreak: Int {
        storageService.currentStreak
    }

    var longestStreak: Int {
        storageService.longestStreak
    }

    // MARK: - Init
    init(
        healthKitService: HealthKitService = .shared,
        storageService: StorageService = .shared
    ) {
        self.healthKitService = healthKitService
        self.storageService = storageService
        updateGreeting()
        observeNotifications()
        // Pre-load Apple Health sleep at launch so Resumo is already populated
        // by the time the user opens it (instead of waiting for the tab to appear).
        Task { await loadData() }
    }

    // MARK: - Private Properties
    private var hasLoadedOnce = false
    private var hasRequestedHealthOnLoad = false
    private var isCurrentlyLoading = false
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Public Methods
    /// Resumo shows the user's Apple Health sleep — the nights iPhone/Apple
    /// Watch/other apps recorded. It reads HealthKit directly and never touches
    /// the local tracker cache, so this screen is purely "Apple's data".
    func loadData() async {
        // Prevent re-entrant loads
        guard !isCurrentlyLoading else { return }
        isCurrentlyLoading = true

        // Show shimmer only on first load
        if !hasLoadedOnce {
            isLoading = true
        }
        errorMessage = nil

        // Ask for Apple Health access the first time Resumo opens, so the
        // permission sheet appears even when onboarding was already completed.
        if healthKitService.isHealthKitAvailable && !hasRequestedHealthOnLoad {
            hasRequestedHealthOnLoad = true
            try? await healthKitService.requestAuthorization()
        }

        var appleRecords: [SleepRecord] = []
        if healthKitService.isHealthKitAvailable {
            do {
                appleRecords = try await healthKitService.fetchRecentSleepData(days: 30)
            } catch {
                print("HealthKit fetch error: \(error.localizedDescription)")
            }
        }

        appleRecords.sort { $0.endTime > $1.endTime }

        weeklyRecords = appleRecords
        statistics = appleRecords.isEmpty ? nil : SleepStatistics(records: appleRecords)
        todaySleep = appleRecords.first { $0.endTime.isToday }

        isLoading = false
        hasLoadedOnce = true
        isCurrentlyLoading = false
    }

    func requestHealthKitAccess() async {
        do {
            try await healthKitService.requestAuthorization()
            await loadData()
            // iOS shows the permission sheet only the first time. If access was
            // already decided (e.g. denied earlier) it stays silent — send the
            // user to Settings so they can flip it on manually.
            if weeklyRecords.isEmpty {
                openHealthSettings()
            }
        } catch {
            errorMessage = error.localizedDescription
            openHealthSettings()
        }
    }

    func openHealthSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }

    func refresh() async {
        await loadData()
    }

    // MARK: - Private Methods
    private func observeNotifications() {
        // Listen for tab switches to Home/Statistics
        NotificationCenter.default.publisher(for: .didSwitchToDataTab)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { [weak self] in
                    await self?.loadData()
                }
            }
            .store(in: &cancellables)
    }

    private func updateGreeting() {
        let hour = Calendar.current.component(.hour, from: Date())

        switch hour {
        case 5..<12:
            greeting = String(localized: "greeting_morning")
        case 12..<17:
            greeting = String(localized: "greeting_afternoon")
        case 17..<21:
            greeting = String(localized: "greeting_evening")
        default:
            greeting = String(localized: "greeting_night")
        }
    }
}
