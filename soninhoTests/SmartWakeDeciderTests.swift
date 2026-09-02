//
//  SmartWakeDeciderTests.swift
//  soninhoTests
//
//  The decider is the gate between "the engine thinks the sleeper stirred"
//  and "the alarm rings". Its predecessor fired the moment the window opened
//  (a full-volume notification was scheduled AT window start); these tests
//  pin every rule that prevents a relapse.
//

import Foundation
import Testing
@testable import soninho

struct SmartWakeDeciderTests {

    private let windowStart = Date(timeIntervalSince1970: 1_760_030_000)
    private var windowEnd: Date { windowStart.addingTimeInterval(30 * 60) }

    private func makeDecider() -> SmartWakeDecider {
        SmartWakeDecider(windowStart: windowStart, windowEnd: windowEnd, alarmId: "test-alarm")
    }

    private func minute(_ offset: Double) -> Date {
        windowStart.addingTimeInterval(offset * 60)
    }

    // MARK: - Window Boundaries

    @Test func neverFiresBeforeWindow() {
        var decider = makeDecider()
        // Plainly awake, but the window has not opened.
        let fired = decider.evaluate(score: 1.0, calibrated: true, at: minute(-5))
        #expect(fired == false)
    }

    @Test func neverFiresAfterWindow() {
        var decider = makeDecider()
        let fired = decider.evaluate(score: 1.0, calibrated: true, at: minute(31))
        #expect(fired == false)
    }

    // MARK: - Regression: window opening is not a trigger

    @Test func uncalibratedEngineNeverFires() {
        // The original sin: judging before the night taught us anything.
        var decider = makeDecider()
        for offset in 0..<30 {
            let fired = decider.evaluate(score: 1.0, calibrated: false, at: minute(Double(offset)))
            #expect(fired == false)
        }
    }

    @Test func windowStartRequiresPlainlyAwake() {
        var decider = makeDecider()
        // High-but-not-awake readiness in the earliest slice: must not fire.
        let fired1 = decider.evaluate(score: 0.85, calibrated: true, at: minute(1))
        let fired2 = decider.evaluate(score: 0.85, calibrated: true, at: minute(2))
        let fired3 = decider.evaluate(score: 0.85, calibrated: true, at: minute(3))
        #expect(fired1 == false)
        #expect(fired2 == false)
        #expect(fired3 == false)
    }

    @Test func plainlyAwakeFiresEvenAtWindowStart() {
        var decider = makeDecider()
        let fired = decider.evaluate(score: 0.95, calibrated: true, at: minute(1))
        #expect(fired == true)
    }

    // MARK: - Confirmation

    @Test func midWindowNeedsTwoQualifyingMinutes() {
        var decider = makeDecider()
        // At 60% of the window the bar is 0.92 - 0.52 * 0.6 = 0.608.
        let first = decider.evaluate(score: 0.7, calibrated: true, at: minute(18))
        #expect(first == false)
        let second = decider.evaluate(score: 0.7, calibrated: true, at: minute(19))
        #expect(second == true)
    }

    @Test func dipResetsConfirmation() {
        var decider = makeDecider()
        #expect(decider.evaluate(score: 0.7, calibrated: true, at: minute(18)) == false)
        // The stir faded — back to sleep.
        #expect(decider.evaluate(score: 0.1, calibrated: true, at: minute(19)) == false)
        // A single later qualifying minute must not be enough on its own.
        #expect(decider.evaluate(score: 0.7, calibrated: true, at: minute(20)) == false)
        #expect(decider.evaluate(score: 0.7, calibrated: true, at: minute(21)) == true)
    }

    @Test func firesExactlyOnce() {
        var decider = makeDecider()
        #expect(decider.evaluate(score: 0.95, calibrated: true, at: minute(10)) == true)
        #expect(decider.evaluate(score: 0.95, calibrated: true, at: minute(11)) == false)
        #expect(decider.hasFired == true)
    }

    @Test func neverFiresBeforeAnySleep() {
        // Settling down when the window opens reads as "plainly awake" — but
        // there is no sleep to surface from yet, so nothing may ring.
        var decider = makeDecider()
        for offset in 0..<30 {
            let fired = decider.evaluate(
                score: 1.0, calibrated: true, hasSlept: false, at: minute(Double(offset))
            )
            #expect(fired == false)
        }
    }

    @Test func sleepArrivingMidWindowUnlocksTheRing() {
        var decider = makeDecider()
        #expect(decider.evaluate(score: 1.0, calibrated: true, hasSlept: false, at: minute(10)) == false)
        // Twenty minutes later the sleeper has slept and is surfacing.
        #expect(decider.evaluate(score: 0.95, calibrated: true, hasSlept: true, at: minute(28)) == true)
    }

    // MARK: - Bar Shape

    @Test func barDecaysMonotonicallyTowardsLightSleep() {
        let decider = makeDecider()
        var previous = Double.infinity
        for offset in stride(from: 0.0, through: 30.0, by: 5.0) {
            let bar = decider.bar(at: minute(offset))
            #expect(bar <= previous)
            previous = bar
        }
        #expect(abs(decider.bar(at: windowStart) - SmartWakeDecider.Tuning.startingBar) < 0.001)
        #expect(abs(decider.bar(at: windowEnd) - SmartWakeDecider.Tuning.endingBar) < 0.001)
    }

    @Test func deepSleepNeverClearsAnyBar() {
        var decider = makeDecider()
        // Deep-sleep readiness is ~0; even the end-of-window bar must hold.
        for offset in 0..<30 {
            let fired = decider.evaluate(score: 0.15, calibrated: true, at: minute(Double(offset)))
            #expect(fired == false)
        }
    }

    // MARK: - Persistence

    @Test func codableRoundTripKeepsFiredState() throws {
        var decider = makeDecider()
        _ = decider.evaluate(score: 0.95, calibrated: true, at: minute(10))
        #expect(decider.hasFired == true)

        let data = try JSONEncoder().encode(decider)
        var restored = try JSONDecoder().decode(SmartWakeDecider.self, from: data)

        // A mid-window relaunch must remember it already rang.
        #expect(restored.hasFired == true)
        #expect(restored.evaluate(score: 0.95, calibrated: true, at: minute(12)) == false)
    }

    @Test func codableRoundTripKeepsConfirmationCount() throws {
        var decider = makeDecider()
        _ = decider.evaluate(score: 0.7, calibrated: true, at: minute(18))
        #expect(decider.qualifyingMinutes == 1)

        let data = try JSONEncoder().encode(decider)
        var restored = try JSONDecoder().decode(SmartWakeDecider.self, from: data)

        #expect(restored.qualifyingMinutes == 1)
        #expect(restored.evaluate(score: 0.7, calibrated: true, at: minute(19)) == true)
    }
}
