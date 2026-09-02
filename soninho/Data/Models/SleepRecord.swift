//
//  SleepRecord.swift
//  soninho
//
//  Created by João Flores on 28/01/26.
//

import Foundation
import SwiftUI

// MARK: - Sleep Phase
enum SleepPhase: String, Codable, CaseIterable {
    case awake = "awake"
    case light = "light"
    case deep = "deep"
    case rem = "rem"

    // MARK: - Properties
    var displayName: String {
        switch self {
        case .awake: return "Awake"
        case .light: return "Light Sleep"
        case .deep: return "Deep Sleep"
        case .rem: return "REM"
        }
    }

    var localizedName: String {
        switch self {
        case .awake: return String(localized: "sleep_phase_awake")
        case .light: return String(localized: "sleep_phase_light")
        case .deep: return String(localized: "sleep_phase_deep")
        case .rem: return String(localized: "sleep_phase_rem")
        }
    }

    var color: Color {
        switch self {
        case .awake: return AppColors.awake
        case .light: return AppColors.lightSleep
        case .deep: return AppColors.deepSleep
        case .rem: return AppColors.remSleep
        }
    }

    var icon: String {
        switch self {
        case .awake: return "sun.max.fill"
        case .light: return "moon.fill"
        case .deep: return "moon.zzz.fill"
        case .rem: return "sparkles"
        }
    }
}

// MARK: - Sleep Quality
enum SleepQuality: String, Codable, CaseIterable {
    case excellent = "excellent"
    case good = "good"
    case fair = "fair"
    case poor = "poor"

    // MARK: - Init from Score
    init(score: Int) {
        switch score {
        case 85...100:
            self = .excellent
        case 70..<85:
            self = .good
        case 50..<70:
            self = .fair
        default:
            self = .poor
        }
    }

    // MARK: - Properties
    var displayName: String {
        switch self {
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .fair: return "Fair"
        case .poor: return "Poor"
        }
    }

    var localizedName: String {
        switch self {
        case .excellent: return String(localized: "sleep_quality_excellent")
        case .good: return String(localized: "sleep_quality_good")
        case .fair: return String(localized: "sleep_quality_fair")
        case .poor: return String(localized: "sleep_quality_poor")
        }
    }

    var color: Color {
        switch self {
        case .excellent: return AppColors.success
        case .good: return AppColors.primary
        case .fair: return AppColors.warning
        case .poor: return AppColors.error
        }
    }

    var icon: String {
        switch self {
        case .excellent: return "star.fill"
        case .good: return "hand.thumbsup.fill"
        case .fair: return "hand.raised.fill"
        case .poor: return "exclamationmark.triangle.fill"
        }
    }

    var emoji: String {
        switch self {
        case .excellent: return "🌟"
        case .good: return "😊"
        case .fair: return "😐"
        case .poor: return "😔"
        }
    }
}

// MARK: - Sleep Phase Data
struct SleepPhaseData: Codable, Identifiable {
    let id: UUID
    let phase: SleepPhase
    let startTime: Date
    let endTime: Date
    /// True when the app was NOT observing during this span (process dead,
    /// sensor starved). Optional so records saved before the field existed
    /// keep decoding — nil means "observed", like every old span.
    let isGap: Bool?

    // MARK: - Computed Properties
    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }

    var durationMinutes: Int {
        Int(duration / 60)
    }

    /// Whether this span is a hole in the data rather than staged sleep.
    var isMissingData: Bool {
        isGap == true
    }

    // MARK: - Init
    init(id: UUID = UUID(), phase: SleepPhase, startTime: Date, endTime: Date, isGap: Bool? = nil) {
        self.id = id
        self.phase = phase
        self.startTime = startTime
        self.endTime = endTime
        self.isGap = isGap
    }
}

// MARK: - Sleep Record
struct SleepRecord: Codable, Identifiable {
    /// Version stamped on records produced by the event-based staging engine
    /// (2026-09). Older records (nil) carry a single flat light span and a
    /// score from a different algorithm — statistics must not mix the two.
    static let currentEngineVersion = 2

    let id: UUID
    let startTime: Date
    let endTime: Date
    let phases: [SleepPhaseData]
    let qualityScore: Int
    let notes: String?
    let createdAt: Date
    /// nil on records saved before the staging rewrite.
    let engineVersion: Int?

    // MARK: - Computed Properties
    var totalDuration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }

    var totalHours: Double {
        totalDuration / 3600
    }

    var durationString: String {
        Date.durationString(from: startTime, to: endTime)
    }

    var quality: SleepQuality {
        SleepQuality(score: qualityScore)
    }

    var deepSleepDuration: TimeInterval {
        phases.filter { $0.phase == .deep && !$0.isMissingData }.reduce(0) { $0 + $1.duration }
    }

    var lightSleepDuration: TimeInterval {
        phases.filter { $0.phase == .light && !$0.isMissingData }.reduce(0) { $0 + $1.duration }
    }

    var remSleepDuration: TimeInterval {
        phases.filter { $0.phase == .rem && !$0.isMissingData }.reduce(0) { $0 + $1.duration }
    }

    var awakeDuration: TimeInterval {
        phases.filter { $0.phase == .awake && !$0.isMissingData }.reduce(0) { $0 + $1.duration }
    }

    /// Minutes the app was NOT observing (process dead, sensor starved).
    var gapDuration: TimeInterval {
        phases.filter { $0.isMissingData }.reduce(0) { $0 + $1.duration }
    }

    /// The part of the night the app actually watched.
    var observedDuration: TimeInterval {
        max(0, totalDuration - gapDuration)
    }

    /// Time actually asleep among the OBSERVED minutes — a gap is unknown,
    /// not sleep. The single source both analysis cards read (they used to
    /// derive it independently and disagree on the same screen).
    var timeAsleep: TimeInterval {
        max(0, observedDuration - awakeDuration)
    }

    /// Sleep efficiency over the observed night, 0-1.
    var efficiency: Double {
        guard observedDuration > 0 else { return 0 }
        return timeAsleep / observedDuration
    }

    var deepSleepPercentage: Double {
        guard totalDuration > 0 else { return 0 }
        return (deepSleepDuration / totalDuration) * 100
    }

    var lightSleepPercentage: Double {
        guard totalDuration > 0 else { return 0 }
        return (lightSleepDuration / totalDuration) * 100
    }

    var remSleepPercentage: Double {
        guard totalDuration > 0 else { return 0 }
        return (remSleepDuration / totalDuration) * 100
    }

    var bedtimeHour: Int {
        startTime.hour
    }

    var wakeTimeHour: Int {
        endTime.hour
    }

    // MARK: - Init
    init(
        id: UUID = UUID(),
        startTime: Date,
        endTime: Date,
        phases: [SleepPhaseData] = [],
        qualityScore: Int,
        notes: String? = nil,
        createdAt: Date = Date(),
        engineVersion: Int? = SleepRecord.currentEngineVersion
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.phases = phases
        self.qualityScore = qualityScore
        self.notes = notes
        self.createdAt = createdAt
        self.engineVersion = engineVersion
    }
}

// MARK: - Sleep Statistics
struct SleepStatistics {
    let records: [SleepRecord]

    // MARK: - Computed Properties

    /// Records produced by the current staging engine. Pre-rewrite records
    /// carry one flat light span (zero deep, zero REM) and scores from a
    /// different algorithm — averaging them in drags every phase metric
    /// toward zero and turns the trend into an artifact of the deploy.
    var structuredRecords: [SleepRecord] {
        records.filter { $0.engineVersion != nil }
    }

    /// Records long enough to be nights — a nap must not shift "average
    /// bedtime" by hours.
    private var scheduleRecords: [SleepRecord] {
        records.filter { $0.totalDuration >= 3 * 3600 }
    }

    var averageDuration: TimeInterval {
        guard !records.isEmpty else { return 0 }
        let total = records.reduce(0) { $0 + $1.totalDuration }
        return total / Double(records.count)
    }

    var averageQualityScore: Int {
        guard !records.isEmpty else { return 0 }
        let total = records.reduce(0) { $0 + $1.qualityScore }
        return total / records.count
    }

    var averageDeepSleep: TimeInterval {
        guard !structuredRecords.isEmpty else { return 0 }
        let total = structuredRecords.reduce(0) { $0 + $1.deepSleepDuration }
        return total / Double(structuredRecords.count)
    }

    var averageLightSleep: TimeInterval {
        guard !structuredRecords.isEmpty else { return 0 }
        let total = structuredRecords.reduce(0) { $0 + $1.lightSleepDuration }
        return total / Double(structuredRecords.count)
    }

    var averageRemSleep: TimeInterval {
        guard !structuredRecords.isEmpty else { return 0 }
        let total = structuredRecords.reduce(0) { $0 + $1.remSleepDuration }
        return total / Double(structuredRecords.count)
    }

    var averageAwake: TimeInterval {
        guard !structuredRecords.isEmpty else { return 0 }
        let total = structuredRecords.reduce(0) { $0 + $1.awakeDuration }
        return total / Double(structuredRecords.count)
    }

    var averageBedtime: Date? {
        Self.circularMeanTime(of: scheduleRecords.map(\.startTime))
    }

    var averageWakeTime: Date? {
        Self.circularMeanTime(of: scheduleRecords.map(\.endTime))
    }

    /// nil until enough same-engine nights exist to compare halves — a chip
    /// rendered from too little data presents an unavailable assessment as a
    /// finding.
    var sleepTrend: SleepTrend? {
        let comparable = structuredRecords
        guard comparable.count >= 10 else { return nil }

        let half = comparable.count / 2
        let recentRecords = Array(comparable.prefix(half))
        let olderRecords = Array(comparable.suffix(comparable.count - half))

        guard recentRecords.count >= 3, !olderRecords.isEmpty else { return nil }

        let recentAvg = recentRecords.reduce(0) { $0 + $1.qualityScore } / recentRecords.count
        let olderAvg = olderRecords.reduce(0) { $0 + $1.qualityScore } / olderRecords.count

        let difference = recentAvg - olderAvg

        if difference > 5 {
            return .improving
        } else if difference < -5 {
            return .declining
        } else {
            return .stable
        }
    }

    // MARK: - Private Methods

    /// Mean of times-of-day on the clock face (circular mean): 23:50 and
    /// 00:10 average to 00:00, not to noon. The old linear mean produced
    /// exactly that noon for wake times around midnight.
    private static func circularMeanTime(of dates: [Date]) -> Date? {
        guard !dates.isEmpty else { return nil }

        let calendar = Calendar.current
        var x = 0.0
        var y = 0.0
        for date in dates {
            let minutes = calendar.component(.hour, from: date) * 60 + calendar.component(.minute, from: date)
            let angle = Double(minutes) / (24 * 60) * 2 * .pi
            x += Foundation.cos(angle)
            y += Foundation.sin(angle)
        }
        guard abs(x) > 1e-9 || abs(y) > 1e-9 else { return nil }

        var angle = atan2(y, x)
        if angle < 0 { angle += 2 * .pi }
        let meanMinutes = Int((angle / (2 * .pi) * 24 * 60).rounded()) % (24 * 60)

        return calendar.date(bySettingHour: meanMinutes / 60, minute: meanMinutes % 60, second: 0, of: Date())
    }
}

// MARK: - Sleep Trend
enum SleepTrend {
    case improving
    case stable
    case declining

    var icon: String {
        switch self {
        case .improving: return "arrow.up.right"
        case .stable: return "arrow.right"
        case .declining: return "arrow.down.right"
        }
    }

    var color: Color {
        switch self {
        case .improving: return AppColors.success
        case .stable: return AppColors.primary
        case .declining: return AppColors.error
        }
    }

    var localizedDescription: String {
        switch self {
        case .improving: return String(localized: "sleep_trend_improving")
        case .stable: return String(localized: "sleep_trend_stable")
        case .declining: return String(localized: "sleep_trend_declining")
        }
    }
}