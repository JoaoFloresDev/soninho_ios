//
//  MovementFeatureExtractorTests.swift
//  soninhoTests
//
//  The extractor is the layer whose predecessor caused the flat-light night:
//  averaging |a - 1g| over a minute diluted a two-second turn below the sensor
//  noise floor. Every test here pins a property of the deadband-then-sum
//  design that the mean-based design provably lacked.
//

import Foundation
import Testing
@testable import soninho

struct MovementFeatureExtractorTests {

    // MARK: - Stillness

    @Test func stillMinutesProduceExactlyZeroActivity() {
        let result = SyntheticNight.run([.still(minutes: 5)])

        // First minute calibrates; every later still minute must be a hard 0,
        // not "small" — deep-sleep detection depends on exact zeroes.
        let settled = result.minutes.dropFirst()
        #expect(settled.count >= 3)
        for minute in settled {
            #expect(minute.activityIndex == 0)
            #expect(minute.activeSeconds == 0)
            #expect(minute.postureChanged == false)
        }
    }

    @Test func noisierSensorStillProducesZeroWhenStill() {
        // Twice the typical sensor noise: auto-calibration must absorb it.
        let result = SyntheticNight.run([.still(minutes: 5)], noiseSigma: 0.005)

        for minute in result.minutes.dropFirst() {
            #expect(minute.activityIndex == 0)
            #expect(minute.activeSeconds == 0)
        }
    }

    @Test func pureNoiseNeverFlagsPosture() {
        let result = SyntheticNight.run([.still(minutes: 20)])

        for minute in result.minutes {
            #expect(minute.postureChanged == false)
        }
    }

    // MARK: - The Regression: brief movement must survive the minute

    @Test func twoSecondTurnSurvivesTheMinute() {
        // THE original bug: a 2 s turn averaged over 60 s vanished into noise
        // and the whole night came out flat. The activity index must keep the
        // turn at (near) full amplitude instead.
        var night = SyntheticNight()
        night.play(.still(minutes: 3))
        night.play(.turn(seconds: 2, amplitude: 0.05, tiltDegrees: 0))
        night.play(.still(minutes: 3))

        let turnMinutes = night.minutes.filter { $0.activityIndex > 0 }
        #expect(turnMinutes.count == 1)

        guard let turn = turnMinutes.first else { return }
        // A 2 s burst at ~50 mg RMS carries ~0.1 g·s of activity — orders of
        // magnitude above anything noise can produce.
        #expect(turn.activityIndex > 0.05)
        #expect(turn.maxBurst > 0.02)
        #expect(turn.activeSeconds >= 1)
    }

    @Test func turnRegistersActiveSeconds() {
        var night = SyntheticNight()
        night.play(.still(minutes: 2))
        night.play(.turn(seconds: 4, amplitude: 0.05, tiltDegrees: 0))
        night.play(.still(minutes: 2))

        let turn = night.minutes.first { $0.activityIndex > 0 }
        #expect(turn != nil)
        #expect((turn?.activeSeconds ?? 0) >= 3)
    }

    @Test func microTwitchRegistersButSmallerThanTurn() {
        var night = SyntheticNight()
        night.play(.still(minutes: 2))
        night.play(.turn(seconds: 1, amplitude: 0.01, tiltDegrees: 0))
        night.play(.still(minutes: 2))
        night.play(.turn(seconds: 3, amplitude: 0.05, tiltDegrees: 0))
        night.play(.still(minutes: 2))

        let moving = night.minutes.filter { $0.activityIndex > 0 }
        #expect(moving.count == 2)
        guard moving.count == 2, let twitch = moving[safe: 0], let turn = moving[safe: 1] else { return }
        #expect(twitch.activityIndex > 0)
        #expect(turn.activityIndex > twitch.activityIndex * 3)
    }

    // MARK: - Posture Channel

    @Test func persistentTiltFlagsPostureChange() {
        var night = SyntheticNight()
        night.play(.still(minutes: 3))
        night.play(.turn(seconds: 3, amplitude: 0.05, tiltDegrees: 2.0))
        night.play(.still(minutes: 2))

        #expect(night.minutes.contains { $0.postureChanged })
    }

    @Test func turnWithoutTiltDoesNotFlagPosture() {
        var night = SyntheticNight()
        night.play(.still(minutes: 3))
        night.play(.turn(seconds: 3, amplitude: 0.05, tiltDegrees: 0))
        night.play(.still(minutes: 2))

        #expect(!night.minutes.contains { $0.postureChanged })
    }

    // MARK: - Data Integrity

    @Test func starvedMinuteIsFlaggedAsNotEnoughData() {
        var extractor = MovementFeatureExtractor()
        var random = SeededRandom(seed: 7)
        let start = SyntheticNight.sessionStart

        // Only 5 seconds of samples, then the stream dies.
        var now = start
        for _ in 0..<250 {
            now = now.addingTimeInterval(0.02)
            _ = extractor.add(
                x: random.gaussian(sigma: 0.0025),
                y: random.gaussian(sigma: 0.0025),
                z: 1 + random.gaussian(sigma: 0.0025),
                at: now
            )
        }
        let minute = extractor.flush(at: now.addingTimeInterval(55))

        #expect(minute != nil)
        #expect(minute?.hasEnoughData == false)
    }

    @Test func minuteCadenceIsSixtySeconds() {
        let result = SyntheticNight.run([.still(minutes: 10)])

        #expect(result.minutes.count >= 9)
        for (first, second) in zip(result.minutes, result.minutes.dropFirst()) {
            let gap = second.date.timeIntervalSince(first.date)
            #expect(abs(gap - 60) < 2.0)
        }
    }

    @Test func liveActivityTracksCurrentSecond() {
        var night = SyntheticNight()
        night.play(.still(minutes: 2))
        #expect(night.extractor.liveActivity == 0)

        night.liveSecond(amplitude: 0.05)
        night.liveSecond(amplitude: 0.05)
        #expect(night.extractor.liveActivity > 0.01)

        night.play(.still(minutes: 1))
        #expect(night.extractor.liveActivity == 0)
    }

    @Test func resetWindowKeepsCalibrationButDropsPartialMinute() {
        var night = SyntheticNight()
        night.play(.still(minutes: 3))
        let calibratedFloor = night.extractor.noiseVariance
        #expect(calibratedFloor != MovementFeatureExtractor.Tuning.initialNoiseVariance)

        night.play(.gap(minutes: 30))
        #expect(night.extractor.noiseVariance == calibratedFloor)

        // Post-gap stillness must keep reading as exact zero.
        night.play(.still(minutes: 3))
        let postGap = night.minutes.suffix(2)
        for minute in postGap {
            #expect(minute.activityIndex == 0)
        }
    }
}
