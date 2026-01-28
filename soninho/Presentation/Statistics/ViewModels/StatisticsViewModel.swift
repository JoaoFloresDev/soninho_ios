//
//  StatisticsViewModel.swift
//  soninho
//
//  Created by João Flores on 28/01/26.
//

import Foundation
import Combine

// MARK: - Time Period
enum TimePeriod: String, CaseIterable, Identifiable {
    case week = "week"
    case month = "month"
    case year = "year"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .week: return String(localized: "period_week")
        case .month: return String(localized: "period_month")
        case .year: return String(localized: "period_year")
        }
    }

    var days: Int {
        switch self {
        case .week: return 7
        case .month: return 30
        case .year: return 365
        }
    }
}

// MARK: - Statistics ViewModel
@MainActor
final class StatisticsViewModel: ObservableObject {
    // MARK: - Dependencies
    private let healthKitService: HealthKitService
    private let storageService: StorageService

    // MARK: - Published Properties
    @Published var selectedPeriod: TimePeriod = .week
    @Published var records: [SleepRecord] = []
    @Published var statistics: SleepStatistics?
    @Published var isLoading = false

    // MARK: - Computed Properties
    var averageDuration: String {
        guard let stats = statistics else { return "--" }
        return stats.averageDuration.hoursMinutesString
    }

    var averageQuality: Int {
        statistics?.averageQualityScore ?? 0
    }

    var averageBedtime: String {
        guard let bedtime = statistics?.averageBedtime else { return "--" }
        return bedtime.timeString
    }

    var averageWakeTime: String {
        guard let wakeTime = statistics?.averageWakeTime else { return "--" }
        return wakeTime.timeString
    }

    var averageDeepSleep: String {
        guard let stats = statistics else { return "--" }
        return stats.averageDeepSleep.hoursMinutesString
    }

    var averageLightSleep: String {
        guard let stats = statistics else { return "--" }
        return stats.averageLightSleep.hoursMinutesString
    }

    var averageRemSleep: String {
        guard let stats = statistics else { return "--" }
        return stats.averageRemSleep.hoursMinutesString
    }

    var sleepTrend: SleepTrend {
        statistics?.sleepTrend ?? .stable
    }

    var consistencyScore: Int {
        guard records.count >= 3 else { return 0 }

        // Calculate based on variance in bedtime and wake time
        let bedtimes = records.map { $0.startTime.hour * 60 + $0.startTime.minute }
        let avgBedtime = bedtimes.reduce(0, +) / bedtimes.count

        let variance = bedtimes.reduce(0) { sum, time in
            sum + abs(time - avgBedtime)
        } / bedtimes.count

        // Lower variance = higher consistency
        let score = max(0, 100 - (variance * 2))
        return score
    }

    // MARK: - Init
    init(
        healthKitService: HealthKitService = .shared,
        storageService: StorageService = .shared
    ) {
        self.healthKitService = healthKitService
        self.storageService = storageService
    }

    // MARK: - Public Methods
    func loadData() async {
        isLoading = true

        do {
            if healthKitService.isAuthorized {
                records = try await healthKitService.fetchRecentSleepData(days: selectedPeriod.days)
            } else {
                records = storageService.loadCachedSleepRecords()
                    .filter { $0.startTime > Date().addingTimeInterval(-Double(selectedPeriod.days) * 86400) }

                if records.isEmpty {
                    records = SleepRecord.sampleRecords
                        .filter { $0.startTime > Date().addingTimeInterval(-Double(selectedPeriod.days) * 86400) }
                }
            }

            statistics = SleepStatistics(records: records)
        } catch {
            print("Error loading statistics: \(error)")
            records = SleepRecord.sampleRecords
            statistics = SleepStatistics(records: records)
        }

        isLoading = false
    }

    func changePeriod(_ period: TimePeriod) {
        selectedPeriod = period
        Task {
            await loadData()
        }
    }
}
