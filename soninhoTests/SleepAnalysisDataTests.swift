//
//  SleepAnalysisDataTests.swift
//  soninhoTests
//
//  Pins the analysis-layer semantics fixed in the 2026-09-02 review: gaps are
//  holes (not light sleep), the post-alarm tail is not deep sleep, adopted
//  sessions cannot push percentages past 100%, legacy flat records stay out
//  of the averages, and wake times around midnight average to midnight.
//

import Foundation
import Testing
@testable import soninho

// MARK: - Record Gap Math
struct SleepRecordGapTests {

    private let start = SyntheticNight.sessionStart

    private func span(_ phase: SleepPhase, minutes: Double, from offset: Double, gap: Bool = false) -> SleepPhaseData {
        SleepPhaseData(
            phase: phase,
            startTime: start.addingTimeInterval(offset * 60),
            endTime: start.addingTimeInterval((offset + minutes) * 60),
            isGap: gap ? true : nil
        )
    }

    @Test func gapSpansAreHolesNotSleep() {
        // 2h light, 3h gap, 2h deep, 1h awake — 8h in bed.
        let record = SleepRecord(
            startTime: start,
            endTime: start.addingTimeInterval(8 * 3600),
            phases: [
                span(.light, minutes: 120, from: 0),
                span(.light, minutes: 180, from: 120, gap: true),
                span(.deep, minutes: 120, from: 300),
                span(.awake, minutes: 60, from: 420),
            ],
            qualityScore: 50
        )

        #expect(record.gapDuration == 3 * 3600)
        #expect(record.observedDuration == 5 * 3600)
        // The gap is unknown time — it must be neither asleep nor awake.
        #expect(record.timeAsleep == 4 * 3600)
        #expect(abs(record.efficiency - 4.0 / 5.0) < 0.001)
        // Gap staged as light must not inflate light duration.
        #expect(record.lightSleepDuration == 2 * 3600)
    }

    @Test func legacyRecordsDecodeWithoutGapField() throws {
        // Records saved before isGap/engineVersion existed must keep loading.
        let legacyJSON = """
        [{"id":"\(UUID().uuidString)","startTime":700000000,"endTime":700028800,
        "phases":[{"id":"\(UUID().uuidString)","phase":"light","startTime":700000000,"endTime":700028800}],
        "qualityScore":72,"createdAt":700028800}]
        """
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        let records = try decoder.decode([SleepRecord].self, from: Data(legacyJSON.utf8))

        #expect(records.count == 1)
        #expect(records[safe: 0]?.engineVersion == nil)
        #expect(records[safe: 0]?.phases[safe: 0]?.isMissingData == false)
    }
}

// MARK: - Engine Span Semantics
struct EngineSpanSemanticsTests {

    private let start = SyntheticNight.sessionStart

    @Test func gapsBecomeTheirOwnFlaggedSpans() {
        var engine = SleepStagingEngine(sessionStart: start)
        var cursor = start
        for _ in 0..<12 {
            engine.record(EpochFactory.still(at: cursor))
            cursor = cursor.addingTimeInterval(60)
        }
        let gapEnd = cursor.addingTimeInterval(20 * 60)
        engine.recordGap(from: cursor, to: gapEnd)
        cursor = gapEnd
        for _ in 0..<12 {
            engine.record(EpochFactory.still(at: cursor))
            cursor = cursor.addingTimeInterval(60)
        }

        let spans = engine.phaseSpans(now: cursor)
        let gapSpans = spans.filter(\.isMissingData)
        #expect(gapSpans.count == 1)
        if let gap = gapSpans[safe: 0] {
            #expect(abs(gap.duration - 20 * 60) < 120)
        }
        // Observed spans must NOT carry the flag.
        #expect(spans.filter { !$0.isMissingData }.count >= 2)
    }

    @Test func postAlarmTailIsAwakeNotLastPhase() {
        // The sensors stop when the alarm rings; the half hour of ringing,
        // mission and getting up must not inherit "deep".
        var engine = SleepStagingEngine(sessionStart: start)
        var cursor = start
        for _ in 0..<40 {
            engine.record(EpochFactory.still(at: cursor))
            cursor = cursor.addingTimeInterval(60)
        }
        #expect(engine.epochs.map(\.phase).contains(.deep))

        let morning = cursor.addingTimeInterval(30 * 60)
        let spans = engine.phaseSpans(now: morning)

        guard let tail = spans.last else {
            Issue.record("no spans")
            return
        }
        #expect(tail.phase == .awake)
        #expect(abs(tail.duration - 30 * 60) < 120)
    }

    @Test func trimDropsPreTapEpochs() {
        var engine = SleepStagingEngine(sessionStart: start)
        var cursor = start
        for _ in 0..<60 {
            engine.record(EpochFactory.storm(at: cursor))
            cursor = cursor.addingTimeInterval(60)
        }
        let tapTime = cursor
        for _ in 0..<20 {
            engine.record(EpochFactory.still(at: cursor))
            cursor = cursor.addingTimeInterval(60)
        }

        engine.trimEpochs(before: tapTime)

        #expect(engine.epochs.count <= 21)
        #expect(engine.epochs.allSatisfy { $0.date >= tapTime.addingTimeInterval(-60) })
    }
}

// MARK: - Scorer Honesty
struct SleepScorerHonestyTests {

    private let start = SyntheticNight.sessionStart

    private func spans(_ blocks: [(SleepPhase, minutes: Double)]) -> [SleepPhaseData] {
        var cursor = start
        return blocks.map { phase, minutes in
            let end = cursor.addingTimeInterval(minutes * 60)
            defer { cursor = end }
            return SleepPhaseData(phase: phase, startTime: cursor, endTime: end)
        }
    }

    @Test func nightstandNightDoesNotScoreExcellent() {
        // One unbroken stillness run all night (phone never coupled to the
        // sleeper) → absurd deep/REM shares. Used to score 95 "Excellent".
        let night = spans([
            (.light, 20), (.deep, 260), (.rem, 190), (.light, 10),
        ])
        let score = SleepQualityScorer.score(phases: night, totalDuration: 8 * 3600)
        #expect(score <= 65)
    }

    @Test func emptyPhasesAreNeutralNotJudged() {
        // A never-observed night carries no phases — judging it as a bad
        // night blames the user for an app failure.
        #expect(SleepQualityScorer.score(phases: [], totalDuration: 8 * 3600) == 50)
    }

    @Test func gapAwareScoringUsesObservedTime() {
        // 4h observed (deep 48m = 20% of observed), 4h gap. Percentages must
        // come from the observed half, not the whole bed time.
        var night = spans([
            (.light, 96), (.deep, 48), (.light, 96),
        ])
        night.append(SleepPhaseData(
            phase: .light,
            startTime: start.addingTimeInterval(4 * 3600),
            endTime: start.addingTimeInterval(8 * 3600),
            isGap: true
        ))
        let score = SleepQualityScorer.score(phases: night, totalDuration: 8 * 3600)

        // Deep at 20% of OBSERVED gets the full ideal-band credit; computed
        // over total it would be 10% and score lower.
        let idealBandScore = SleepQualityScorer.score(
            phases: spans([(.light, 192), (.deep, 48)]),
            totalDuration: 4 * 3600
        )
        #expect(score >= idealBandScore - 15)
    }
}

// MARK: - Statistics Hygiene
struct SleepStatisticsHygieneTests {

    private let start = SyntheticNight.sessionStart

    private func structuredRecord(daysAgo: Int, deepMinutes: Double = 90) -> SleepRecord {
        let nightStart = start.addingTimeInterval(Double(-daysAgo) * 86400)
        return SleepRecord(
            startTime: nightStart,
            endTime: nightStart.addingTimeInterval(8 * 3600),
            phases: [
                SleepPhaseData(phase: .light, startTime: nightStart, endTime: nightStart.addingTimeInterval(6 * 3600)),
                SleepPhaseData(
                    phase: .deep,
                    startTime: nightStart.addingTimeInterval(6 * 3600),
                    endTime: nightStart.addingTimeInterval(6 * 3600 + deepMinutes * 60)
                ),
            ],
            qualityScore: 80
        )
    }

    private func legacyRecord(daysAgo: Int) -> SleepRecord {
        let nightStart = start.addingTimeInterval(Double(-daysAgo) * 86400)
        return SleepRecord(
            startTime: nightStart,
            endTime: nightStart.addingTimeInterval(8 * 3600),
            phases: [SleepPhaseData(phase: .light, startTime: nightStart, endTime: nightStart.addingTimeInterval(8 * 3600))],
            qualityScore: 70,
            engineVersion: nil
        )
    }

    @Test func legacyFlatRecordsStayOutOfPhaseAverages() {
        // Ten legacy nights of zero deep must not drag the average toward 0.
        var records = (0..<10).map { legacyRecord(daysAgo: $0 + 3) }
        records.insert(structuredRecord(daysAgo: 1), at: 0)
        records.insert(structuredRecord(daysAgo: 2), at: 0)

        let stats = SleepStatistics(records: records)
        #expect(abs(stats.averageDeepSleep - 90 * 60) < 60)
    }

    @Test func trendIsNilWithoutEnoughComparableNights() {
        let records = (0..<8).map { structuredRecord(daysAgo: $0) } + (0..<20).map { legacyRecord(daysAgo: $0 + 10) }
        let stats = SleepStatistics(records: records)
        // 28 records, but only 8 comparable — no trend verdict.
        #expect(stats.sleepTrend == nil)
    }

    @Test func wakeTimesAroundMidnightAverageToMidnight() {
        let calendar = Calendar.current
        let base = calendar.startOfDay(for: Date())
        // Wakes at 23:50 and 00:10 — the old linear mean said 12:00.
        let lateWake = calendar.date(byAdding: .minute, value: 23 * 60 + 50, to: base) ?? base
        let earlyWake = calendar.date(byAdding: .minute, value: 10, to: base) ?? base

        let records = [
            SleepRecord(startTime: lateWake.addingTimeInterval(-8 * 3600), endTime: lateWake, qualityScore: 70),
            SleepRecord(startTime: earlyWake.addingTimeInterval(-8 * 3600), endTime: earlyWake, qualityScore: 70),
        ]
        let stats = SleepStatistics(records: records)

        guard let mean = stats.averageWakeTime else {
            Issue.record("no wake mean")
            return
        }
        let minutes = calendar.component(.hour, from: mean) * 60 + calendar.component(.minute, from: mean)
        // Within a few minutes of midnight, on either side.
        #expect(minutes <= 5 || minutes >= 24 * 60 - 5)
    }

    @Test func napsDoNotShiftScheduleAverages() {
        let calendar = Calendar.current
        let base = calendar.startOfDay(for: Date())
        let nightBed = calendar.date(byAdding: .hour, value: 23, to: base) ?? base

        let night = SleepRecord(startTime: nightBed, endTime: nightBed.addingTimeInterval(8 * 3600), qualityScore: 70)
        // A 40-minute afternoon nap must not drag "average bedtime" to 18:50.
        let napStart = calendar.date(byAdding: .hour, value: 14, to: base) ?? base
        let nap = SleepRecord(startTime: napStart, endTime: napStart.addingTimeInterval(40 * 60), qualityScore: 60)

        let stats = SleepStatistics(records: [night, nap])
        guard let bedtime = stats.averageBedtime else {
            Issue.record("no bedtime")
            return
        }
        #expect(calendar.component(.hour, from: bedtime) == 23)
    }
}
