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

    // The app only READS sleep — it no longer writes to HealthKit and doesn't
    // use heart-rate/HRV here, so request the minimal read scope.
    private var readTypes: Set<HKObjectType> { [sleepType] }

    // MARK: - Init
    private init() {
        checkAuthorizationStatus()
    }

    // MARK: - Authorization
    var isHealthKitAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    /// HealthKit does NOT expose read authorization status (privacy).
    /// We check write authorization as a proxy, but also allow data fetching
    /// when the user has been through the authorization flow at least once.
    func checkAuthorizationStatus() {
        guard isHealthKitAvailable else {
            isAuthorized = false
            return
        }

        // Apple intentionally hides read-only authorization, so we can't truly
        // know if reading is granted — only whether WRITE is. Don't fake it via
        // a "has requested before" flag (that lies "authorized" forever).
        isAuthorized = healthStore.authorizationStatus(for: sleepType) == .sharingAuthorized
    }

    /// Track whether we've ever gone through the authorization flow
    private var hasRequestedAuthorization: Bool {
        get { UserDefaults.standard.bool(forKey: "healthkit_authorization_requested") }
        set { UserDefaults.standard.set(newValue, forKey: "healthkit_authorization_requested") }
    }

    func requestAuthorization() async throws {
        guard isHealthKitAvailable else {
            throw HealthKitError.notAvailable
        }

        try await healthStore.requestAuthorization(toShare: [], read: readTypes)
        hasRequestedAuthorization = true
        checkAuthorizationStatus()
    }

    // MARK: - Fetch Sleep Data
    /// Fetches sleep data from HealthKit. Attempts to fetch even if authorization
    /// status is uncertain, since Apple doesn't expose read-only authorization.
    func fetchSleepData(from startDate: Date, to endDate: Date) async throws -> [SleepRecord] {
        guard isHealthKitAvailable else {
            throw HealthKitError.notAvailable
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

                // Resumo reflects sleep recorded BY the device/other apps — not
                // the sessions this app tracked and wrote back to HealthKit.
                // Exclude our own writes so Resumo ≠ the in-app tracker.
                let ownBundleId = Bundle.main.bundleIdentifier
                let external = samples.filter { $0.sourceRevision.source.bundleIdentifier != ownBundleId }

                let records = self?.processSleepSamples(external) ?? []
                continuation.resume(returning: records)
            }

            healthStore.execute(query)
        }
    }

    func fetchRecentSleepData(days: Int = 14) async throws -> [SleepRecord] {
        let endDate = Date()
        guard let startDate = Calendar.current.date(byAdding: .day, value: -days, to: endDate) else {
            return []
        }
        return try await fetchSleepData(from: startDate, to: endDate)
    }

    // MARK: - Process Sleep Samples
    nonisolated private func processSleepSamples(_ samples: [HKCategorySample]) -> [SleepRecord] {
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
            guard !sessionSamples.isEmpty else { return nil }

            // Bound the session by the earliest start and latest end across all
            // its samples — samples are sorted by start, but the last-starting
            // sample isn't necessarily the last-ending one.
            let startTime = sessionSamples.map(\.startDate).min() ?? sessionSamples[0].startDate
            let endTime = sessionSamples.map(\.endDate).max() ?? sessionSamples[0].endDate
            let duration = endTime.timeIntervalSince(startTime)

            // Skip very short sessions (naps under 1 hour).
            guard duration >= 3600 else { return nil }

            // iPhone-only sleep (no Apple Watch) is recorded as "In Bed" with no
            // detailed stages. If this session has no real asleep stages, treat
            // In Bed as light sleep so the night isn't classified as all-awake.
            let hasRealStages = sessionSamples.contains { sample in
                let v = sample.value
                return v == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue
                    || v == HKCategoryValueSleepAnalysis.asleepCore.rawValue
                    || v == HKCategoryValueSleepAnalysis.asleepDeep.rawValue
                    || v == HKCategoryValueSleepAnalysis.asleepREM.rawValue
            }

            let phases = convertToPhases(sessionSamples, treatInBedAsLight: !hasRealStages)
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

    nonisolated private func convertToPhases(_ samples: [HKCategorySample], treatInBedAsLight: Bool = false) -> [SleepPhaseData] {
        samples.compactMap { sample in
            let phase: SleepPhase
            switch sample.value {
            case HKCategoryValueSleepAnalysis.inBed.rawValue:
                phase = treatInBedAsLight ? .light : .awake
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

    nonisolated private func calculateQualityScore(phases: [SleepPhaseData], duration: TimeInterval) -> Int {
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

    // MARK: - Fetch Apple Watch Sleep Phases
    /// Fetches sleep phase data from HealthKit for a specific time range.
    /// Returns nil if no data found (e.g. user doesn't have Apple Watch).
    /// Returns phases if Apple Watch recorded sleep during this period.
    func fetchSleepPhases(from start: Date, to end: Date) async -> [SleepPhaseData]? {
        guard isHealthKitAvailable else { return nil }

        let predicate = HKQuery.predicateForSamples(
            withStart: start,
            end: end,
            options: .strictStartDate
        )

        let sortDescriptor = NSSortDescriptor(
            key: HKSampleSortIdentifierStartDate,
            ascending: true
        )

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [sortDescriptor]
            ) { [weak self] _, samples, error in
                guard error == nil,
                      let samples = samples as? [HKCategorySample],
                      !samples.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }

                // Filter out "inBed" samples — we only want actual sleep phase data
                let sleepSamples = samples.filter { sample in
                    sample.value != HKCategoryValueSleepAnalysis.inBed.rawValue
                }

                guard !sleepSamples.isEmpty else {
                    continuation.resume(returning: nil)
                    return
                }

                let phases = self?.convertToPhases(sleepSamples) ?? []
                continuation.resume(returning: phases.isEmpty ? nil : phases)
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
