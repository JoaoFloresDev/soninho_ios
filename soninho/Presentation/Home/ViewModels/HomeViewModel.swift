//
//  HomeViewModel.swift
//  soninho
//
//  Created by João Flores on 28/01/26.
//

import Foundation
import Combine

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
    }

    // MARK: - Private Properties
    private var hasLoadedOnce = false
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
        } catch {
            errorMessage = error.localizedDescription
        }
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
