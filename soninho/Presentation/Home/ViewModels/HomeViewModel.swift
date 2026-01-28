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

    // MARK: - Init
    init(
        healthKitService: HealthKitService = .shared,
        storageService: StorageService = .shared
    ) {
        self.healthKitService = healthKitService
        self.storageService = storageService
        updateGreeting()
    }

    // MARK: - Public Methods
    func loadData() async {
        isLoading = true
        errorMessage = nil

        do {
            // Try to fetch from HealthKit first
            if healthKitService.isAuthorized {
                let records = try await healthKitService.fetchRecentSleepData(days: 14)
                weeklyRecords = records
                statistics = SleepStatistics(records: records)
                todaySleep = records.first { $0.endTime.isToday }

                // Cache locally
                storageService.saveSleepRecords(records)
            } else {
                // Use cached or sample data
                let cached = storageService.loadCachedSleepRecords()
                if cached.isEmpty {
                    weeklyRecords = SleepRecord.sampleRecords
                } else {
                    weeklyRecords = cached
                }
                statistics = SleepStatistics(records: weeklyRecords)
                todaySleep = weeklyRecords.first { $0.endTime.isToday }
            }
        } catch {
            errorMessage = error.localizedDescription

            // Fall back to cached data
            let cached = storageService.loadCachedSleepRecords()
            if !cached.isEmpty {
                weeklyRecords = cached
                statistics = SleepStatistics(records: cached)
            }
        }

        isLoading = false
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
