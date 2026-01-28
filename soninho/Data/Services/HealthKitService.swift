//
//  HealthKitService.swift
//  soninho
//
//  Created by João Flores on 28/01/26.
//

import Foundation
import HealthKit
import Combine

// MARK: - HealthKit Service
@MainActor
final class HealthKitService: ObservableObject {
    // MARK: - Singleton
    static let shared = HealthKitService()

    // MARK: - Properties
    private let healthStore = HKHealthStore()

    // MARK: - Published Properties
    @Published private(set) var isAuthorized = false
    @Published private(set) var sleepRecords: [SleepRecord] = []
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    // MARK: - Health Data Types
    private let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
    private let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
    private let respiratoryRateType = HKObjectType.quantityType(forIdentifier: .respiratoryRate)!
    private let oxygenSatType = HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!
    private let restingHeartRateType = HKObjectType.quantityType(forIdentifier: .restingHeartRate)!
    private let heartRateVariabilityType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!

    private var readTypes: Set<HKObjectType> {
        [
            sleepType,
            heartRateType,
            respiratoryRateType,
            oxygenSatType,
            restingHeartRateType,
            heartRateVariabilityType
        ]
    }

    private var writeTypes: Set<HKSampleType> {
        [sleepType]
    }

    // MARK: - Init
    private init() {
        checkAuthorizationStatus()
    }

    // MARK: - Authorization
    var isHealthKitAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    func checkAuthorizationStatus() {
        guard isHealthKitAvailable else {
            isAuthorized = false
            return
        }

        let status = healthStore.authorizationStatus(for: sleepType)
        isAuthorized = status == .sharingAuthorized
    }

    func requestAuthorization() async throws {
        guard isHealthKitAvailable else {
            throw HealthKitError.notAvailable
        }

        try await healthStore.requestAuthorization(toShare: writeTypes, read: readTypes)
        checkAuthorizationStatus()
    }

    // MARK: - Fetch Sleep Data
    func fetchSleepData(from startDate: Date, to endDate: Date) async throws -> [SleepRecord] {
        guard isAuthorized else {
            throw HealthKitError.notAuthorized
        }

        isLoading = true
        defer { isLoading = false }

        let predicate = HKQuery.predicateForSamples(
            withStart: startDate,
            end: endDate,
            options: .strictStartDate
        )

        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierStartDate,
            ascending: false
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { [weak self] _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let samples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: [])
                    return
                }

                let records = self?.processSleepSamples(samples) ?? []
                continuation.resume(returning: records)
            }

            healthStore.execute(query)
        }
    }

    func fetchRecentSleepData(days: Int = 14) async throws -> [SleepRecord] {
        let endDate = Date()
        let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate)!
        return try await fetchSleepData(from: startDate, to: endDate)
    }

    // MARK: - Process Sleep Samples
    private func processSleepSamples(_ samples: [HKCategorySample]) -> [SleepRecord] {
        // Group samples by sleep session (samples within 1 hour of each other)
        var sessions: [[HKCategorySample]] = []
        var currentSession: [HKCategorySample] = []

        let sortedSamples = samples.sorted { $0.startDate < $1.startDate }

        for sample in sortedSamples {
            if let lastSample = currentSession.last {
                let gap = sample.startDate.timeIntervalSince(lastSample.endDate)
                if gap > 3600 { // More than 1 hour gap = new session
                    if !currentSession.isEmpty {
                        sessions.append(currentSession)
                    }
                    currentSession = [sample]
                } else {
                    currentSession.append(sample)
                }
            } else {
                currentSession.append(sample)
            }
        }

        if !currentSession.isEmpty {
            sessions.append(currentSession)
        }

        // Convert sessions to SleepRecords
        return sessions.compactMap { sessionSamples -> SleepRecord? in
            guard let firstSample = sessionSamples.first,
                  let lastSample = sessionSamples.last else { return nil }

            let startTime = firstSample.startDate
            let endTime = lastSample.endDate
            let duration = endTime.timeIntervalSince(startTime)

            // Skip very short sessions (less than 3 hours)
            guard duration >= 3 * 3600 else { return nil }

            let phases = convertToPhases(sessionSamples)
            let qualityScore = calculateQualityScore(phases: phases, duration: duration)

            return SleepRecord(
                startTime: startTime,
                endTime: endTime,
                phases: phases,
                qualityScore: qualityScore,
                createdAt: endTime
            )
        }
    }

    private func convertToPhases(_ samples: [HKCategorySample]) -> [SleepPhaseData] {
        samples.compactMap { sample in
            let phase: SleepPhase
            switch sample.value {
            case HKCategoryValueSleepAnalysis.inBed.rawValue:
                phase = .awake
            case HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue:
                phase = .light
            case HKCategoryValueSleepAnalysis.asleepCore.rawValue:
                phase = .light
            case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                phase = .deep
            case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                phase = .rem
            case HKCategoryValueSleepAnalysis.awake.rawValue:
                phase = .awake
            default:
                phase = .light
            }

            return SleepPhaseData(
                phase: phase,
                startTime: sample.startDate,
                endTime: sample.endDate
            )
        }
    }

    private func calculateQualityScore(phases: [SleepPhaseData], duration: TimeInterval) -> Int {
        var score = 50 // Base score

        // Duration score (7-9 hours is ideal)
        let hours = duration / 3600
        if hours >= 7 && hours <= 9 {
            score += 20
        } else if hours >= 6 && hours <= 10 {
            score += 10
        } else if hours < 5 || hours > 11 {
            score -= 10
        }

        // Deep sleep percentage (ideal: 15-25%)
        let totalDuration = phases.reduce(0) { $0 + $1.duration }
        guard totalDuration > 0 else { return score }

        let deepSleep = phases.filter { $0.phase == .deep }.reduce(0) { $0 + $1.duration }
        let deepPercentage = (deepSleep / totalDuration) * 100

        if deepPercentage >= 15 && deepPercentage <= 25 {
            score += 15
        } else if deepPercentage >= 10 && deepPercentage <= 30 {
            score += 8
        } else {
            score -= 5
        }

        // REM sleep percentage (ideal: 20-25%)
        let remSleep = phases.filter { $0.phase == .rem }.reduce(0) { $0 + $1.duration }
        let remPercentage = (remSleep / totalDuration) * 100

        if remPercentage >= 20 && remPercentage <= 25 {
            score += 15
        } else if remPercentage >= 15 && remPercentage <= 30 {
            score += 8
        } else {
            score -= 5
        }

        // Awake time (less is better)
        let awakeTime = phases.filter { $0.phase == .awake }.reduce(0) { $0 + $1.duration }
        let awakePercentage = (awakeTime / totalDuration) * 100

        if awakePercentage < 5 {
            score += 10
        } else if awakePercentage < 10 {
            score += 5
        } else {
            score -= 10
        }

        return min(100, max(0, score))
    }

    // MARK: - Save Sleep Data
    func saveSleepRecord(_ record: SleepRecord) async throws {
        guard isAuthorized else {
            throw HealthKitError.notAuthorized
        }

        var samples: [HKCategorySample] = []

        for phase in record.phases {
            let value: Int
            switch phase.phase {
            case .awake:
                value = HKCategoryValueSleepAnalysis.awake.rawValue
            case .light:
                value = HKCategoryValueSleepAnalysis.asleepCore.rawValue
            case .deep:
                value = HKCategoryValueSleepAnalysis.asleepDeep.rawValue
            case .rem:
                value = HKCategoryValueSleepAnalysis.asleepREM.rawValue
            }

            let sample = HKCategorySample(
                type: sleepType,
                value: value,
                start: phase.startTime,
                end: phase.endTime
            )
            samples.append(sample)
        }

        try await healthStore.save(samples)
    }

    // MARK: - Heart Rate Data
    func fetchHeartRateDuring(start: Date, end: Date) async throws -> [Double] {
        guard isAuthorized else {
            throw HealthKitError.notAuthorized
        }

        let predicate = HKQuery.predicateForSamples(
            withStart: start,
            end: end,
            options: .strictStartDate
        )

        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierStartDate,
            ascending: true
        )

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: heartRateType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let samples = samples as? [HKQuantitySample] else {
                    continuation.resume(returning: [])
                    return
                }

                let heartRates = samples.map {
                    $0.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                }
                continuation.resume(returning: heartRates)
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Statistics
    func fetchSleepStatistics(for days: Int = 30) async throws -> SleepStatistics {
        let records = try await fetchRecentSleepData(days: days)
        return SleepStatistics(records: records)
    }
}

// MARK: - HealthKit Error
enum HealthKitError: LocalizedError {
    case notAvailable
    case notAuthorized
    case fetchFailed
    case saveFailed

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return String(localized: "healthkit_not_available")
        case .notAuthorized:
            return String(localized: "healthkit_not_authorized")
        case .fetchFailed:
            return String(localized: "healthkit_fetch_failed")
        case .saveFailed:
            return String(localized: "healthkit_save_failed")
        }
    }
}
