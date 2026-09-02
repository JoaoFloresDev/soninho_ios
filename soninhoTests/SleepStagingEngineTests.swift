//
//  SleepStagingEngineTests.swift
//  soninhoTests
//
//  The engine's predecessor reported João's whole night as one flat block of
//  light sleep and never surfaced a wake-readiness score the smart alarm
//  could act on. These tests pin the staging semantics: stillness runs read
//  as deep, movement events punctuate the night with light, sustained motion
//  is wake, gaps are honest, and the whole state survives Codable.
//

import Foundation
import Testing
@testable import soninho

struct SleepStagingEngineTests {

    private var start: Date { SyntheticNight.sessionStart }

    private func makeEngine() -> SleepStagingEngine {
        SleepStagingEngine(sessionStart: start)
    }

    // MARK: - Calibration

    @Test func uncalibratedNightStaysNeutral() {
        var engine = makeEngine()
        for date in EpochFactory.minuteDates(from: start, count: 4) {
            engine.record(EpochFactory.still(at: date))
        }

        #expect(engine.isCalibrated == false)
        #expect(engine.currentPhase == .light)
        #expect(engine.wakeReadiness() == 0)
    }

    // MARK: - Regression: the flat-light night

    @Test func wholeStillNightIsNotAllLight() {
        // The old engine reported an entire still night as flat light sleep.
        // Unbroken stillness IS the best available evidence of deep sleep.
        var engine = makeEngine()
        for date in EpochFactory.minuteDates(from: start, count: 60) {
            engine.record(EpochFactory.still(at: date))
        }

        let phases = Set(engine.epochs.map(\.phase))
        #expect(phases.contains(.deep))
        #expect(phases.count >= 2)
    }

    @Test func turnsCreateStructure() {
        // still 20 / turn / still 20 / turn / still 20 — the two turns must
        // punctuate the night: deep inside the long runs, light at the events.
        var engine = makeEngine()
        var minute = 0
        func advance(_ count: Int, _ features: (Date) -> MovementFeatures) {
            for _ in 0..<count {
                engine.record(features(start.addingTimeInterval(Double(minute) * 60)))
                minute += 1
            }
        }

        advance(20) { EpochFactory.still(at: $0) }
        advance(1) { EpochFactory.turn(at: $0) }
        advance(20) { EpochFactory.still(at: $0) }
        advance(1) { EpochFactory.turn(at: $0) }
        advance(20) { EpochFactory.still(at: $0) }

        let phases = engine.epochs.map(\.phase)
        #expect(phases.contains(.deep))
        #expect(phases.contains(.light))
        #expect(!phases.contains(.awake))

        // The turn minutes themselves must not be deep.
        #expect(engine.epochs[safe: 20]?.phase != .deep)
        #expect(engine.epochs[safe: 41]?.phase != .deep)

        // And the night must have real phase transitions — never one flat span.
        let spans = engine.phaseSpans(now: start.addingTimeInterval(Double(minute) * 60))
        #expect(spans.count >= 4)
    }

    // MARK: - Wake

    @Test func isolatedTurnDoesNotWake() {
        var engine = makeEngine()
        let dates = EpochFactory.minuteDates(from: start, count: 30)
        for (index, date) in dates.enumerated() {
            if index == 15 {
                engine.record(EpochFactory.turn(at: date))
            } else {
                engine.record(EpochFactory.still(at: date))
            }
        }

        #expect(!engine.epochs.map(\.phase).contains(.awake))
    }

    @Test func sustainedMovementWakes() {
        var engine = makeEngine()
        let dates = EpochFactory.minuteDates(from: start, count: 30)
        for (index, date) in dates.enumerated() {
            if (12...17).contains(index) {
                engine.record(EpochFactory.storm(at: date))
            } else {
                engine.record(EpochFactory.still(at: date))
            }
        }

        let awakeCount = engine.epochs.filter { $0.phase == .awake }.count
        #expect(awakeCount >= 3)
    }

    @Test func snoreVetoesWake() {
        // Same storm minutes, but the microphone heard snoring through them:
        // people do not snore while awake, so wake must be vetoed.
        var engine = makeEngine()
        let dates = EpochFactory.minuteDates(from: start, count: 30)
        let snoring = SoundMinute(sleepSoundSeconds: 30, disturbanceSeconds: 0)
        for (index, date) in dates.enumerated() {
            if (12...17).contains(index) {
                engine.record(EpochFactory.storm(at: date), sound: snoring)
            } else {
                engine.record(EpochFactory.still(at: date))
            }
        }

        #expect(!engine.epochs.map(\.phase).contains(.awake))
    }

    // MARK: - Depth Semantics

    @Test func shortStillRunsStayLight() {
        // Runs of 8 still minutes between turns: below the deep threshold.
        var engine = makeEngine()
        var minute = 0
        for _ in 0..<4 {
            for _ in 0..<8 {
                engine.record(EpochFactory.still(at: start.addingTimeInterval(Double(minute) * 60)))
                minute += 1
            }
            engine.record(EpochFactory.turn(at: start.addingTimeInterval(Double(minute) * 60)))
            minute += 1
        }

        #expect(!engine.epochs.map(\.phase).contains(.deep))
    }

    @Test func remOnlyAfterFirstNinetyMinutes() {
        var engine = makeEngine()
        for date in EpochFactory.minuteDates(from: start, count: 80) {
            engine.record(EpochFactory.still(at: date))
        }

        #expect(!engine.epochs.map(\.phase).contains(.rem))
    }

    @Test func longNightContainsREMLate() {
        var engine = makeEngine()
        for date in EpochFactory.minuteDates(from: start, count: 240) {
            engine.record(EpochFactory.still(at: date))
        }

        let firstHalf = engine.epochs.prefix(90).map(\.phase)
        let secondHalf = engine.epochs.suffix(120).map(\.phase)
        #expect(!firstHalf.contains(.rem))
        #expect(secondHalf.contains(.rem))
    }

    // MARK: - Gaps

    @Test func gapBreaksStillnessRuns() {
        // 6 still + 20 dead + 6 still: neither side is long enough for deep,
        // and the gap itself must never read as deep — a suspension is not
        // evidence of deep sleep.
        var engine = makeEngine()
        var cursor = start
        for _ in 0..<6 {
            engine.record(EpochFactory.still(at: cursor))
            cursor = cursor.addingTimeInterval(60)
        }
        let gapEnd = cursor.addingTimeInterval(20 * 60)
        engine.recordGap(from: cursor, to: gapEnd)
        cursor = gapEnd
        for _ in 0..<6 {
            engine.record(EpochFactory.still(at: cursor))
            cursor = cursor.addingTimeInterval(60)
        }

        #expect(!engine.epochs.map(\.phase).contains(.deep))
        for epoch in engine.epochs where epoch.isGap {
            #expect(epoch.phase == .light)
        }
    }

    @Test func starvedMinuteBecomesGap() {
        var engine = makeEngine()
        for date in EpochFactory.minuteDates(from: start, count: 10) {
            engine.record(EpochFactory.still(at: date))
        }
        engine.record(EpochFactory.starved(at: start.addingTimeInterval(600)))

        #expect(engine.epochs.last?.isGap == true)
    }

    @Test func gapMinutesAreCountedOut() {
        var engine = makeEngine()
        let gapEnd = start.addingTimeInterval(30 * 60)
        engine.recordGap(from: start, to: gapEnd)
        for date in EpochFactory.minuteDates(from: gapEnd, count: 10) {
            engine.record(EpochFactory.still(at: date))
        }

        #expect(engine.observedMinutes == 10)
        #expect(engine.epochs.count == 40)
    }

    // MARK: - Calibration of Scale

    @Test func turnScaleTracksTheNightsOwnTurns() {
        var engine = makeEngine()
        let dates = EpochFactory.minuteDates(from: start, count: 40)
        for (index, date) in dates.enumerated() {
            if index % 10 == 5 {
                engine.record(EpochFactory.turn(at: date, activity: 0.2, posture: false))
            } else {
                engine.record(EpochFactory.still(at: date))
            }
        }

        #expect(abs(engine.turnScale - 0.2) < 0.05)
        #expect(engine.eventCount == 4)
    }

    @Test func sustainedMovementDoesNotInflateTurnScale() {
        // An hour of scrolling moves the phone hugely; the scale must stay
        // anchored to the sleep turns or they stop registering as events.
        var engine = makeEngine()
        var minute = 0
        func advance(_ count: Int, _ features: (Date) -> MovementFeatures) {
            for _ in 0..<count {
                engine.record(features(start.addingTimeInterval(Double(minute) * 60)))
                minute += 1
            }
        }

        advance(20) { EpochFactory.storm(at: $0, activity: 0.6) }
        advance(10) { EpochFactory.still(at: $0) }
        advance(1) { EpochFactory.turn(at: $0, activity: 0.12, posture: false) }
        advance(10) { EpochFactory.still(at: $0) }
        advance(1) { EpochFactory.turn(at: $0, activity: 0.10, posture: false) }
        advance(10) { EpochFactory.still(at: $0) }
        advance(1) { EpochFactory.turn(at: $0, activity: 0.14, posture: false) }
        advance(5) { EpochFactory.still(at: $0) }

        #expect(engine.turnScale < 0.2)
        #expect(engine.turnScale > 0.05)
    }

    @Test func hasSleptEnoughOnlyAfterRealSleep() {
        // A night that is all phone use is not sleep — and quiet minutes
        // after it must accumulate before the early ring is allowed.
        var engine = makeEngine()
        var minute = 0
        for _ in 0..<30 {
            engine.record(EpochFactory.storm(at: start.addingTimeInterval(Double(minute) * 60)))
            minute += 1
        }
        #expect(engine.hasSleptEnough == false)

        for _ in 0..<20 {
            engine.record(EpochFactory.still(at: start.addingTimeInterval(Double(minute) * 60)))
            minute += 1
        }
        #expect(engine.hasSleptEnough == true)
    }

    // MARK: - Persistence

    @Test func codableRoundTripPreservesEverything() throws {
        var engine = makeEngine()
        var minute = 0
        for _ in 0..<25 {
            engine.record(EpochFactory.still(at: start.addingTimeInterval(Double(minute) * 60)))
            minute += 1
        }
        engine.record(EpochFactory.turn(at: start.addingTimeInterval(Double(minute) * 60)))

        let data = try JSONEncoder().encode(engine)
        let restored = try JSONDecoder().decode(SleepStagingEngine.self, from: data)

        #expect(restored.sessionStart == engine.sessionStart)
        #expect(restored.epochs.count == engine.epochs.count)
        #expect(restored.epochs.map(\.phase) == engine.epochs.map(\.phase))
        #expect(restored.turnScale == engine.turnScale)
        #expect(restored.isCalibrated == engine.isCalibrated)
    }

    // MARK: - Spans

    @Test func phaseSpansAreContiguous() {
        var engine = makeEngine()
        var minute = 0
        for block in 0..<5 {
            for _ in 0..<12 {
                engine.record(EpochFactory.still(at: start.addingTimeInterval(Double(minute) * 60)))
                minute += 1
            }
            if block < 4 {
                engine.record(EpochFactory.turn(at: start.addingTimeInterval(Double(minute) * 60)))
                minute += 1
            }
        }

        let end = start.addingTimeInterval(Double(minute) * 60)
        let spans = engine.phaseSpans(now: end)

        #expect(spans.first?.startTime == engine.epochs.first?.date)
        #expect(spans.last?.endTime == end)
        for (span, next) in zip(spans, spans.dropFirst()) {
            #expect(span.endTime == next.startTime)
        }
    }

    // MARK: - Wake Readiness

    @Test func deepSleepReadinessNearZero() {
        var engine = makeEngine()
        for date in EpochFactory.minuteDates(from: start, count: 40) {
            engine.record(EpochFactory.still(at: date))
        }

        #expect(engine.wakeReadiness() < 0.2)
    }

    @Test func postureArousalRaisesReadiness() {
        var engine = makeEngine()
        for date in EpochFactory.minuteDates(from: start, count: 40) {
            engine.record(EpochFactory.still(at: date))
        }
        let quiet = engine.wakeReadiness()

        engine.record(EpochFactory.turn(at: start.addingTimeInterval(40 * 60)))
        engine.record(EpochFactory.turn(at: start.addingTimeInterval(41 * 60)))
        let stirred = engine.wakeReadiness()

        #expect(stirred > quiet + 0.3)
    }

    @Test func liveMovementRaisesReadiness() {
        var engine = makeEngine()
        for date in EpochFactory.minuteDates(from: start, count: 40) {
            engine.record(EpochFactory.still(at: date))
        }

        let still = engine.wakeReadiness(liveActivity: 0)
        let stirring = engine.wakeReadiness(liveActivity: 0.05)
        #expect(stirring > still + 0.3)
    }

    @Test func quietLightSleepStaysBelowEndBar() {
        // Documented fallback: a night of light sleep with NO movement events
        // in the window does not fire early — the fixed-time alarm handles it.
        // (Light stage alone scores 0.55 * 0.7 = 0.385 < 0.40 end bar.)
        var engine = makeEngine()
        var minute = 0
        for block in 0..<8 {
            for _ in 0..<7 {
                engine.record(EpochFactory.still(at: start.addingTimeInterval(Double(minute) * 60)))
                minute += 1
            }
            if block < 7 {
                engine.record(EpochFactory.turn(at: start.addingTimeInterval(Double(minute) * 60)))
                minute += 1
            }
        }
        // Runs of 7 still minutes: everything stays light.
        #expect(!engine.epochs.map(\.phase).contains(.deep))

        // Three quiet minutes after the last turn: no arousal component left.
        for _ in 0..<3 {
            engine.record(EpochFactory.still(at: start.addingTimeInterval(Double(minute) * 60)))
            minute += 1
        }

        #expect(engine.wakeReadiness() < SmartWakeDecider.Tuning.endingBar)
    }
}
