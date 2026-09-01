//
//  SleepNightIntegrationTests.swift
//  soninhoTests
//
//  End-to-end: raw 50 Hz samples → extractor → engine → smart-wake decider,
//  over whole scripted nights. These are the scenarios that failed in the
//  field: a night that came out as one flat light-sleep block, and a smart
//  alarm that only ever rang at the fixed time.
//

import Foundation
import Testing
@testable import soninho

struct SleepNightIntegrationTests {

    // MARK: - Night Scripts

    /// A plausible calm night, compressed to ~2h20: descent, turns every
    /// 15-30 minutes, long still stretches between them.
    private func calmNightScript() -> [SyntheticNight.Event] {
        [
            .still(minutes: 4),
            .turn(seconds: 3, amplitude: 0.05, tiltDegrees: 1.5),
            .still(minutes: 8),
            .turn(seconds: 2, amplitude: 0.04, tiltDegrees: 0),
            .still(minutes: 25),
            .turn(seconds: 4, amplitude: 0.06, tiltDegrees: 2.0),
            .still(minutes: 18),
            .turn(seconds: 2, amplitude: 0.05, tiltDegrees: 0),
            .still(minutes: 30),
            .turn(seconds: 3, amplitude: 0.05, tiltDegrees: 1.0),
            .still(minutes: 14),
            .turn(seconds: 2, amplitude: 0.04, tiltDegrees: 0),
            .still(minutes: 22),
            .turn(seconds: 3, amplitude: 0.06, tiltDegrees: 1.5),
            .still(minutes: 12),
        ]
    }

    // MARK: - Regression: João's flat night

    @Test func calmNightIsNeverOneFlatSpan() {
        let result = SyntheticNight.run(calmNightScript())

        let spans = result.engine.phaseSpans(now: result.now)
        let phases = Set(result.engine.epochs.map(\.phase))

        // The field bug: one span, all light, zero variation.
        #expect(spans.count >= 5)
        #expect(phases.contains(.deep))
        #expect(phases.contains(.light))
        #expect(result.engine.eventCount >= 5)
    }

    @Test func calmNightHasPlausibleArchitecture() {
        let result = SyntheticNight.run(calmNightScript())

        let total = Double(result.engine.epochs.count)
        let deep = Double(result.engine.epochs.filter { $0.phase == .deep }.count)
        let awake = Double(result.engine.epochs.filter { $0.phase == .awake }.count)

        // Long still stretches must register meaningful deep sleep, and a calm
        // night must not be scored as substantially awake.
        #expect(deep / total > 0.15)
        #expect(deep / total < 0.80)
        #expect(awake / total < 0.10)
    }

    @Test func restlessNightScoresMoreMovementThanCalmNight() {
        let calm = SyntheticNight.run(calmNightScript())

        let restless = SyntheticNight.run([
            .still(minutes: 6),
            .restless(minutes: 3, amplitude: 0.05),
            .still(minutes: 8),
            .turn(seconds: 3, amplitude: 0.05, tiltDegrees: 1.0),
            .restless(minutes: 4, amplitude: 0.06),
            .still(minutes: 10),
            .restless(minutes: 3, amplitude: 0.05),
            .still(minutes: 7),
            .restless(minutes: 2, amplitude: 0.05),
            .still(minutes: 9),
        ])

        let calmAwake = calm.engine.epochs.filter { $0.phase == .awake }.count
        let restlessAwake = restless.engine.epochs.filter { $0.phase == .awake }.count
        #expect(restlessAwake > calmAwake)
        #expect(restlessAwake >= 3)
    }

    // MARK: - Smart Alarm over Whole Nights

    /// Runs a wake window minute by minute on top of an existing night,
    /// playing extra events, and reports when (if ever) the decider fires.
    private func runWindow(
        night: inout SyntheticNight,
        minutes: Int = 30,
        eventsAt: [Int: SyntheticNight.Event] = [:]
    ) -> Int? {
        var decider = SmartWakeDecider(
            windowStart: night.now,
            windowEnd: night.now.addingTimeInterval(Double(minutes) * 60),
            alarmId: "integration"
        )

        for minute in 0..<minutes {
            if let event = eventsAt[minute] {
                night.play(event)
            } else {
                night.play(.still(minutes: 1))
            }
            let score = night.engine.wakeReadiness(liveActivity: night.extractor.liveActivity)
            if decider.evaluate(score: score, calibrated: night.engine.isCalibrated, at: night.now) {
                return minute
            }
        }
        return nil
    }

    @Test func deepSleeperIsNotWokenEarly() {
        // Perfectly still through the whole window: the smart alarm must NOT
        // fire and the fixed-time alarm handles the wake.
        var night = SyntheticNight()
        for event in calmNightScript() { night.play(event) }

        let fired = runWindow(night: &night)
        #expect(fired == nil)
    }

    @Test func nightstandPhoneNeverFiresEarly() {
        // Phone on a nightstand, decoupled from the sleeper: nothing but
        // noise all night. No evidence means no early ring — ever.
        var night = SyntheticNight()
        night.play(.still(minutes: 90))

        let fired = runWindow(night: &night)
        #expect(fired == nil)
        #expect(night.engine.eventCount == 0)
    }

    @Test func morningStirringFiresBeforeFixedTime() {
        // The sleeper surfaces mid-window: turns, then keeps stirring. The
        // alarm must ring before the fixed time — this is the product promise.
        var night = SyntheticNight()
        for event in calmNightScript() { night.play(event) }

        let fired = runWindow(night: &night, eventsAt: [
            14: .turn(seconds: 3, amplitude: 0.05, tiltDegrees: 1.5),
            15: .restless(minutes: 1, amplitude: 0.05),
            16: .restless(minutes: 1, amplitude: 0.05),
            17: .restless(minutes: 1, amplitude: 0.04),
            18: .restless(minutes: 1, amplitude: 0.05),
        ])

        #expect(fired != nil)
        if let fired {
            #expect(fired >= 14)
            #expect(fired < 30)
        }
    }

    @Test func singleTurnInWindowDoesNotFire() {
        // One turn early in the window is just a turn — the sleeper went
        // straight back down. No ring.
        var night = SyntheticNight()
        for event in calmNightScript() { night.play(event) }

        let fired = runWindow(night: &night, eventsAt: [
            6: .turn(seconds: 3, amplitude: 0.05, tiltDegrees: 0),
        ])

        #expect(fired == nil)
    }

    // MARK: - Suspension

    @Test func suspensionGapDoesNotFakeSleepArchitecture() {
        // The app died for two hours mid-night. The gap must be visible as
        // absence — never as a block of deep sleep.
        var night = SyntheticNight()
        night.play(.still(minutes: 20))
        night.play(.turn(seconds: 3, amplitude: 0.05, tiltDegrees: 1.0))
        night.play(.still(minutes: 5))
        night.play(.gap(minutes: 120))
        night.play(.still(minutes: 5))
        night.play(.turn(seconds: 2, amplitude: 0.05, tiltDegrees: 0))
        night.play(.still(minutes: 10))

        let gapEpochs = night.engine.epochs.filter(\.isGap)
        #expect(gapEpochs.count >= 119)
        for epoch in gapEpochs {
            #expect(epoch.phase != .deep)
            #expect(epoch.phase != .awake)
        }

        // Post-gap data still stages normally. (~42 scripted minutes; the
        // minute in flight at each boundary is pending, so a couple less.)
        #expect(night.engine.observedMinutes >= 38)
    }

    @Test func trackingResumesCleanlyAfterGap() throws {
        // Relaunch mid-night: engine state round-trips through Codable, the
        // gap is recorded, and staging continues on the restored engine.
        var night = SyntheticNight()
        night.play(.still(minutes: 25))
        night.play(.turn(seconds: 3, amplitude: 0.05, tiltDegrees: 1.0))
        night.play(.still(minutes: 10))

        let data = try JSONEncoder().encode(night.engine)
        var restored = try JSONDecoder().decode(SleepStagingEngine.self, from: data)

        let deadFrom = night.now
        let deadTo = deadFrom.addingTimeInterval(45 * 60)
        restored.recordGap(from: deadFrom, to: deadTo)

        for date in EpochFactory.minuteDates(from: deadTo, count: 15) {
            restored.record(EpochFactory.still(at: date))
        }

        // ~50 scripted minutes, minus the minute in flight at the cut.
        #expect(restored.observedMinutes >= 48)
        #expect(restored.epochs.filter(\.isGap).count >= 44)
        // The whole timeline stays ordered.
        let dates = restored.epochs.map(\.date)
        #expect(dates == dates.sorted())
    }
}
