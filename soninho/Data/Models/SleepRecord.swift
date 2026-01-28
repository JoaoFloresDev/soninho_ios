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

    // MARK: - Computed Properties
    var duration: TimeInterval {
        endTime.timeIntervalSince(startTime)
    }

    var durationMinutes: Int {
        Int(duration / 60)
    }

    // MARK: - Init
    init(id: UUID = UUID(), phase: SleepPhase, startTime: Date, endTime: Date) {
        self.id = id
        self.phase = phase
        self.startTime = startTime
        self.endTime = endTime
    }
}

// MARK: - Sleep Record
struct SleepRecord: Codable, Identifiable {
    let id: UUID
    let startTime: Date
    let endTime: Date
    let phases: [SleepPhaseData]
    let qualityScore: Int
    let notes: String?
    let createdAt: Date

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
        phases.filter { $0.phase == .deep }.reduce(0) { $0 + $1.duration }
    }

    var lightSleepDuration: TimeInterval {
        phases.filter { $0.phase == .light }.reduce(0) { $0 + $1.duration }
    }

    var remSleepDuration: TimeInterval {
        phases.filter { $0.phase == .rem }.reduce(0) { $0 + $1.duration }
    }

    var awakeDuration: TimeInterval {
        phases.filter { $0.phase == .awake }.reduce(0) { $0 + $1.duration }
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
        createdAt: Date = Date()
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.phases = phases
        self.qualityScore = qualityScore
        self.notes = notes
        self.createdAt = createdAt
    }
}

// MARK: - Sleep Statistics
struct SleepStatistics {
    let records: [SleepRecord]

    // MARK: - Computed Properties
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
        guard !records.isEmpty else { return 0 }
        let total = records.reduce(0) { $0 + $1.deepSleepDuration }
        return total / Double(records.count)
    }

    var averageLightSleep: TimeInterval {
        guard !records.isEmpty else { return 0 }
        let total = records.reduce(0) { $0 + $1.lightSleepDuration }
        return total / Double(records.count)
    }

    var averageRemSleep: TimeInterval {
        guard !records.isEmpty else { return 0 }
        let total = records.reduce(0) { $0 + $1.remSleepDuration }
        return total / Double(records.count)
    }

    var averageBedtime: Date? {
        guard !records.isEmpty else { return nil }
        let totalMinutes = records.reduce(0) { total, record in
            let hour = record.startTime.hour
            let minute = record.startTime.minute
            // Handle overnight bedtimes
            let adjustedHour = hour < 12 ? hour + 24 : hour
            return total + (adjustedHour * 60 + minute)
        }
        let averageMinutes = totalMinutes / records.count
        let hour = (averageMinutes / 60) % 24
        let minute = averageMinutes % 60

        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components)
    }

    var averageWakeTime: Date? {
        guard !records.isEmpty else { return nil }
        let totalMinutes = records.reduce(0) { total, record in
            let hour = record.endTime.hour
            let minute = record.endTime.minute
            return total + (hour * 60 + minute)
        }
        let averageMinutes = totalMinutes / records.count
        let hour = averageMinutes / 60
        let minute = averageMinutes % 60

        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components)
    }

    var thisWeekRecords: [SleepRecord] {
        records.filter { $0.startTime.isThisWeek }
    }

    var sleepTrend: SleepTrend {
        guard records.count >= 7 else { return .stable }

        let recentRecords = Array(records.prefix(7))
        let olderRecords = Array(records.dropFirst(7).prefix(7))

        guard !olderRecords.isEmpty else { return .stable }

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

// MARK: - Sample Data
extension SleepRecord {
    static var sampleRecords: [SleepRecord] {
        let calendar = Calendar.current
        var records: [SleepRecord] = []

        for dayOffset in 0..<14 {
            let baseDate = calendar.date(byAdding: .day, value: -dayOffset, to: Date())!
            let bedtime = calendar.date(bySettingHour: 23, minute: Int.random(in: 0...59), second: 0, of: baseDate)!
            let wakeTime = calendar.date(byAdding: .hour, value: Int.random(in: 6...9), to: bedtime)!

            let phases = generateSamplePhases(from: bedtime, to: wakeTime)
            let qualityScore = Int.random(in: 55...95)

            let record = SleepRecord(
                startTime: bedtime,
                endTime: wakeTime,
                phases: phases,
                qualityScore: qualityScore,
                createdAt: wakeTime
            )
            records.append(record)
        }

        return records.sorted { $0.startTime > $1.startTime }
    }

    private static func generateSamplePhases(from start: Date, to end: Date) -> [SleepPhaseData] {
        var phases: [SleepPhaseData] = []
        var currentTime = start
        let totalDuration = end.timeIntervalSince(start)

        // Simulate sleep cycles (typically 90 minutes each)
        let cycleCount = Int(totalDuration / 5400) // 5400 seconds = 90 minutes

        for cycle in 0..<max(cycleCount, 1) {
            // Light sleep (longer at start)
            let lightDuration = Double.random(in: 15...25) * 60
            let lightEnd = currentTime.addingTimeInterval(lightDuration)
            phases.append(SleepPhaseData(phase: .light, startTime: currentTime, endTime: lightEnd))
            currentTime = lightEnd

            // Deep sleep (more in first half of night)
            let deepMultiplier = cycle < cycleCount / 2 ? 1.5 : 0.5
            let deepDuration = Double.random(in: 15...30) * 60 * deepMultiplier
            let deepEnd = currentTime.addingTimeInterval(deepDuration)
            if deepEnd < end {
                phases.append(SleepPhaseData(phase: .deep, startTime: currentTime, endTime: deepEnd))
                currentTime = deepEnd
            }

            // REM sleep (more in second half of night)
            let remMultiplier = cycle >= cycleCount / 2 ? 1.5 : 0.5
            let remDuration = Double.random(in: 10...25) * 60 * remMultiplier
            let remEnd = currentTime.addingTimeInterval(remDuration)
            if remEnd < end {
                phases.append(SleepPhaseData(phase: .rem, startTime: currentTime, endTime: remEnd))
                currentTime = remEnd
            }

            // Brief awake period
            if Bool.random() && currentTime < end {
                let awakeDuration = Double.random(in: 1...5) * 60
                let awakeEnd = currentTime.addingTimeInterval(awakeDuration)
                if awakeEnd < end {
                    phases.append(SleepPhaseData(phase: .awake, startTime: currentTime, endTime: awakeEnd))
                    currentTime = awakeEnd
                }
            }
        }

        // Fill remaining time with light sleep
        if currentTime < end {
            phases.append(SleepPhaseData(phase: .light, startTime: currentTime, endTime: end))
        }

        return phases
    }
}
