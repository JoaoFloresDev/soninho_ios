//
//  SyntheticNight.swift
//  soninhoTests
//
//  Deterministic synthetic-night generator: scripted scenarios rendered as raw
//  50 Hz accelerometer samples and fed through the REAL extractor into the
//  REAL engine. Seeded RNG on purpose — a flaky sleep test is worse than none.
//

import Foundation
@testable import soninho

// MARK: - Seeded Random
/// SplitMix64 — deterministic, good enough statistical quality for noise.
struct SeededRandom {
    private var state: UInt64

    init(seed: UInt64 = 42) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }

    /// Uniform in [0, 1).
    mutating func uniform() -> Double {
        Double(next() >> 11) * (1.0 / 9007199254740992.0)
    }

    /// Gaussian via Box-Muller.
    mutating func gaussian(sigma: Double) -> Double {
        let u1 = max(uniform(), 1e-12)
        let u2 = uniform()
        return sigma * (-2 * Foundation.log(u1)).squareRoot() * Foundation.cos(2 * .pi * u2)
    }
}

// MARK: - Synthetic Night
/// Renders a scripted night and runs it through extractor + engine.
struct SyntheticNight {

    // MARK: - Script Events
    enum Event {
        /// Minutes of pure stillness — gravity plus sensor noise only.
        case still(minutes: Int)
        /// A body turn: a burst of movement, optionally leaving the phone at a
        /// slightly different resting angle (a real turn deforms the mattress).
        case turn(seconds: Int, amplitude: Double, tiltDegrees: Double)
        /// Minutes of near-continuous movement — restless or awake.
        case restless(minutes: Int, amplitude: Double)
        /// Minutes with no samples at all — the process was dead.
        case gap(minutes: Int)
    }

    // MARK: - Result
    struct Result {
        var engine: SleepStagingEngine
        var extractor: MovementFeatureExtractor
        var minutes: [MovementFeatures]
        var now: Date
    }

    // MARK: - Constants
    static let sampleRate = 50.0
    static let defaultNoiseSigma = 0.0025
    static let sessionStart = Date(timeIntervalSince1970: 1_760_000_000)

    // MARK: - Properties
    private(set) var random: SeededRandom
    private(set) var extractor = MovementFeatureExtractor()
    private(set) var engine: SleepStagingEngine
    private(set) var minutes: [MovementFeatures] = []
    private(set) var now: Date
    private var tiltDegrees = 0.0
    let noiseSigma: Double

    // MARK: - Init
    init(seed: UInt64 = 42, noiseSigma: Double = SyntheticNight.defaultNoiseSigma) {
        random = SeededRandom(seed: seed)
        engine = SleepStagingEngine(sessionStart: Self.sessionStart)
        now = Self.sessionStart
        self.noiseSigma = noiseSigma
    }

    // MARK: - Public Methods

    static func run(
        _ events: [Event],
        seed: UInt64 = 42,
        noiseSigma: Double = SyntheticNight.defaultNoiseSigma
    ) -> Result {
        var night = SyntheticNight(seed: seed, noiseSigma: noiseSigma)
        for event in events { night.play(event) }
        return Result(
            engine: night.engine,
            extractor: night.extractor,
            minutes: night.minutes,
            now: night.now
        )
    }

    mutating func play(_ event: Event) {
        switch event {
        case .still(let minutes):
            emitSamples(seconds: minutes * 60, burstAmplitude: 0)
        case .turn(let seconds, let amplitude, let tilt):
            emitSamples(seconds: seconds, burstAmplitude: amplitude)
            tiltDegrees += tilt
        case .restless(let minutes, let amplitude):
            for _ in 0..<(minutes * 60) {
                // Movement most seconds, brief pauses — a person shifting about.
                let moving = random.uniform() < 0.8
                emitSamples(seconds: 1, burstAmplitude: moving ? amplitude : 0)
            }
        case .gap(let minutes):
            let gapStart = now
            now = now.addingTimeInterval(Double(minutes) * 60)
            engine.recordGap(from: gapStart, to: now)
            extractor.resetWindow(at: now)
        }
    }

    /// Feeds one live second of the given amplitude WITHOUT closing the
    /// current minute — for smart-alarm live-readiness checks.
    mutating func liveSecond(amplitude: Double) {
        emitSamples(seconds: 1, burstAmplitude: amplitude)
    }

    // MARK: - Private Methods

    /// Renders raw samples: gravity at the current tilt, gaussian sensor noise
    /// on each axis, plus an optional movement burst.
    private mutating func emitSamples(seconds: Int, burstAmplitude: Double) {
        let radians = tiltDegrees * .pi / 180
        let gz = Foundation.cos(radians)
        let gx = Foundation.sin(radians)
        let dt = 1.0 / Self.sampleRate
        let samplesPerSecond = Int(Self.sampleRate)

        for _ in 0..<(seconds * samplesPerSecond) {
            var x = gx + random.gaussian(sigma: noiseSigma)
            var y = random.gaussian(sigma: noiseSigma)
            var z = gz + random.gaussian(sigma: noiseSigma)

            if burstAmplitude > 0 {
                x += random.gaussian(sigma: burstAmplitude)
                y += random.gaussian(sigma: burstAmplitude)
                z += random.gaussian(sigma: burstAmplitude)
            }

            now = now.addingTimeInterval(dt)
            if let minute = extractor.add(x: x, y: y, z: z, at: now) {
                minutes.append(minute)
                engine.record(minute)
            }
        }
    }
}

// MARK: - Direct Epoch Helpers
/// Hand-built minutes for engine-level tests that bypass the extractor.
enum EpochFactory {
    static func still(at date: Date) -> MovementFeatures {
        MovementFeatures(
            date: date, activityIndex: 0, activeSeconds: 0, maxBurst: 0,
            postureChanged: false, sampleCount: 3000
        )
    }

    static func turn(at date: Date, activity: Double = 0.1, posture: Bool = true) -> MovementFeatures {
        MovementFeatures(
            date: date, activityIndex: activity, activeSeconds: 3,
            maxBurst: activity / 2, postureChanged: posture, sampleCount: 3000
        )
    }

    static func storm(at date: Date, activity: Double = 0.6) -> MovementFeatures {
        MovementFeatures(
            date: date, activityIndex: activity, activeSeconds: 30,
            maxBurst: activity / 6, postureChanged: true, sampleCount: 3000
        )
    }

    static func starved(at date: Date) -> MovementFeatures {
        MovementFeatures(
            date: date, activityIndex: 0, activeSeconds: 0, maxBurst: 0,
            postureChanged: false, sampleCount: 40
        )
    }

    /// Feeds a scripted sequence of minutes straight into an engine.
    static func feed(
        _ engine: inout SleepStagingEngine,
        minutes: [(MovementFeatures, SoundMinute?)]
    ) {
        for (features, sound) in minutes {
            engine.record(features, sound: sound)
        }
    }

    static func minuteDates(from start: Date, count: Int) -> [Date] {
        (0..<count).map { start.addingTimeInterval(Double($0) * 60) }
    }
}
