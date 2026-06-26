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

        // Calculate based on variance in bedtime — handle overnight times
        // Hours before noon get +24 so 1AM=25, 2AM=26, etc. to average with 22-23 PM
        let bedtimes = records.map { record -> Int in
            let hour = record.startTime.hour
            let adjustedHour = hour < 12 ? hour + 24 : hour
            return adjustedHour * 60 + record.startTime.minute
        }
        let avgBedtime = bedtimes.reduce(0, +) / bedtimes.count

        let variance = bedtimes.reduce(0) { sum, time in
            sum + abs(time - avgBedtime)
        } / bedtimes.count

        // Lower variance = higher consistency (30 min variance = ~100%, 2h = ~0%)
        let score = max(0, min(100, 100 - (variance * 100 / 60)))
        return score
    }

    var sleepGoalHours: Double {
        storageService.sleepGoalHours
    }

    var sleepGoalProgress: Double {
        guard let stats = statistics else { return 0 }
        let avgHours = stats.averageDuration / 3600
        return min(avgHours / sleepGoalHours, 1.0)
    }

    var daysMetGoal: Int {
        let goalSeconds = sleepGoalHours * 3600
        return records.filter { $0.totalDuration >= goalSeconds }.count
    }

    var totalDaysTracked: Int {
        records.count
    }

    // MARK: - Private Properties
    private var hasLoadedOnce = false
    private var isCurrentlyLoading = false
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init
    init(
        healthKitService: HealthKitService = .shared,
        storageService: StorageService = .shared
    ) {
        self.healthKitService = healthKitService
        self.storageService = storageService
        observeNotifications()
    }

    // MARK: - Public Methods
    /// Estatísticas analyzes the nights tracked inside Soninho (the Sleep tab).
    /// It reads only the local tracker cache — never HealthKit — so this screen
    /// is purely the app's own sleep analysis.
    func loadData() async {
        guard !isCurrentlyLoading else { return }
        isCurrentlyLoading = true

        if !hasLoadedOnce {
            isLoading = true
        }

        let cutoffDate = Date().addingTimeInterval(-Double(selectedPeriod.days) * 86400)

        records = storageService.loadCachedSleepRecords()
            .filter { $0.startTime > cutoffDate }
            .sorted { $0.endTime > $1.endTime }

        statistics = records.isEmpty ? nil : SleepStatistics(records: records)
        isLoading = false
        hasLoadedOnce = true
        isCurrentlyLoading = false
    }

    func changePeriod(_ period: TimePeriod) {
        selectedPeriod = period
        Task {
            await loadData()
        }
    }

    private func observeNotifications() {
        NotificationCenter.default.publisher(for: StorageService.sleepRecordsDidChangeNotification)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { [weak self] in
                    await self?.loadData()
                }
            }
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: .didSwitchToDataTab)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                Task { [weak self] in
                    await self?.loadData()
                }
            }
            .store(in: &cancellables)
    }
}
