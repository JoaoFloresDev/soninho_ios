//
//  MovementFeatureExtractor.swift
//  soninho
//

import Foundation

// MARK: - Movement Features
/// One minute of movement, reduced to the features actigraphy can actually use.
///
/// The failed implementation averaged |acceleration - 1g| over the whole minute.
/// A two-second turn in bed, averaged across sixty seconds, dilutes thirty-fold
/// and sinks below the accelerometer's noise floor — every minute of the night
/// came out identical. Proven pipelines (ActiGraph counts, Bai 2016 Activity
/// Index) are all deadband-then-SUM designs: remove what is provably noise at
/// the one-second level, keep the sum and the peak of what survives. A still
/// minute is then exactly zero and a turn keeps its full amplitude.
struct MovementFeatures: Codable {
    /// Wall-clock start of the minute.
    let date: Date
    /// Bai-style activity index summed over the minute's one-second windows:
    /// sqrt(max(0, variance - noise variance)), in g. Zero for a still minute.
    let activityIndex: Double
    /// Seconds of the minute with movement clearly above the noise floor.
    let activeSeconds: Int
    /// The largest one-second activity index — a brief turn keeps its size here.
    let maxBurst: Double
    /// Whether the device's resting angle shifted this minute. The angle is a
    /// ratio of axes, so it is immune to the noise floor: 2-3 mg of sensor noise
    /// moves it ~0.1°, while a body turn deforming the mattress tilts the phone
    /// by 0.5° or more — and the tilt persists, which a noise spike cannot fake.
    let postureChanged: Bool
    /// Raw samples that fed the minute. A starved minute must not be mistaken
    /// for a still one.
    let sampleCount: Int

    /// Whether the sensor actually covered this minute.
    var hasEnoughData: Bool {
        sampleCount >= MovementFeatureExtractor.Tuning.minimumSamplesPerMinute
    }
}

// MARK: - Movement Feature Extractor
/// Turns raw accelerometer samples into per-minute `MovementFeatures`.
/// Pure Foundation on purpose: the whole pipeline is exercised offline by the
/// simulation harness before any night is risked on it.
struct MovementFeatureExtractor {

    // MARK: - Constants
    enum Tuning {
        /// One-second analysis window, per Bai 2016.
        static let secondWindow: TimeInterval = 1.0
        static let secondsPerMinute = 60
        /// Below this many samples a one-second window is unusable.
        static let minimumSamplesPerSecond = 8
        /// Below this many samples the minute is reported as data-starved.
        static let minimumSamplesPerMinute = 600

        /// Noise variance multiplier subtracted before anything counts as
        /// movement. The calibrated floor tracks each minute's QUIETEST second,
        /// which sits near half the mean noise variance, while the noisiest
        /// second of a whole night reaches roughly twice it — so the margin
        /// must cover a 4x spread or noise seconds flicker across the line.
        static let deadbandMargin: Double = 4.0
        /// A second is "active" when its variance clears the floor by this much.
        static let activeMargin: Double = 8.0
        /// The floor can never calibrate below the physical sensor noise.
        static let minimumNoiseVariance: Double = 1e-7
        /// Starting estimate (~2.5 mg RMS per axis) until the night teaches us.
        static let initialNoiseVariance: Double = 8e-6
        /// How fast the floor follows the night's quietest seconds.
        static let noiseAdaptationRate: Double = 0.1

        /// Posture is judged on medians of 5-second blocks.
        static let postureBlockSeconds = 5
        /// Degrees the resting angle must move to count as a posture change.
        static let postureAngleThreshold: Double = 0.75
    }

    // MARK: - Second Accumulator
    /// Running sums for the one-second window currently being filled.
    private struct SecondAccumulator {
        var count = 0
        var sumX = 0.0, sumY = 0.0, sumZ = 0.0
        var sumSqX = 0.0, sumSqY = 0.0, sumSqZ = 0.0

        mutating func add(x: Double, y: Double, z: Double) {
            count += 1
            sumX += x; sumY += y; sumZ += z
            sumSqX += x * x; sumSqY += y * y; sumSqZ += z * z
        }

        /// Mean of the three per-axis variances, per Bai 2016.
        var meanAxisVariance: Double {
            guard count > 1 else { return 0 }
            let n = Double(count)
            let vx = max(0, sumSqX / n - (sumX / n) * (sumX / n))
            let vy = max(0, sumSqY / n - (sumY / n) * (sumY / n))
            let vz = max(0, sumSqZ / n - (sumZ / n) * (sumZ / n))
            return (vx + vy + vz) / 3
        }

        var meanAxes: (x: Double, y: Double, z: Double) {
            guard count > 0 else { return (0, 0, 1) }
            let n = Double(count)
            return (sumX / n, sumY / n, sumZ / n)
        }
    }

    // MARK: - Properties
    /// Calibrated noise variance for THIS phone on THIS surface tonight.
    private(set) var noiseVariance = Tuning.initialNoiseVariance
    private var noiseCalibrated = false

    private var currentSecond = SecondAccumulator()
    private var currentSecondStart: Date?

    /// Finished one-second variances of the minute in progress.
    private var secondVariances: [Double] = []
    private var minuteSampleCount = 0
    private var minuteStart: Date?

    /// Posture tracking: per-block mean axes and the last settled angle.
    private var blockAxes: [(x: Double, y: Double, z: Double)] = []
    private var settledAngle: Double?
    private var minutePostureChanged = false

    /// The most recent one-second activity index, for live UI feedback.
    private(set) var liveActivity: Double = 0

    // MARK: - Init
    init() {}

    /// Starts with an already-known noise floor — used when resuming a night
    /// or replaying the system recorder's data, so recovered minutes are held
    /// to the same standard as the live ones.
    init(noiseVariance: Double) {
        self.noiseVariance = max(noiseVariance, Tuning.minimumNoiseVariance)
        self.noiseCalibrated = true
    }

    // MARK: - Public Methods

    /// Feeds one raw accelerometer sample (in g). Returns the finished minute
    /// when this sample closes one, nil otherwise.
    mutating func add(x: Double, y: Double, z: Double, at date: Date) -> MovementFeatures? {
        if minuteStart == nil { minuteStart = date }
        if currentSecondStart == nil { currentSecondStart = date }

        var finishedMinute: MovementFeatures?
        if let secondStart = currentSecondStart,
           date.timeIntervalSince(secondStart) >= Tuning.secondWindow {
            finishedMinute = closeSecond(endingAt: date)
        }

        currentSecond.add(x: x, y: y, z: z)
        minuteSampleCount += 1
        return finishedMinute
    }

    /// Flushes whatever is buffered as a final (possibly short) minute.
    mutating func flush(at date: Date) -> MovementFeatures? {
        guard minuteStart != nil else { return nil }
        _ = closeSecondAccumulator()
        return closeMinute(endingAt: date)
    }

    /// Discards the partially filled second and minute — used after a gap in
    /// the sample stream, so pre-gap leftovers cannot bleed into the first
    /// post-gap minute. Noise calibration is kept: the sensor did not change.
    mutating func resetWindow(at date: Date) {
        currentSecond = SecondAccumulator()
        currentSecondStart = date
        secondVariances = []
        minuteSampleCount = 0
        minuteStart = date
        blockAxes = []
        minutePostureChanged = false
        settledAngle = nil
        liveActivity = 0
    }

    /// The activity index for a single second's variance, against the current
    /// floor. Exposed so the smart-alarm path can judge live movement.
    func activityIndex(forVariance variance: Double) -> Double {
        let floor = noiseVariance * Tuning.deadbandMargin
        return variance > floor ? (variance - floor).squareRoot() : 0
    }

    // MARK: - Private Methods

    /// Closes the running one-second window and, when it completes a minute,
    /// the minute as well.
    private mutating func closeSecond(endingAt date: Date) -> MovementFeatures? {
        _ = closeSecondAccumulator()
        currentSecondStart = date

        guard secondVariances.count >= Tuning.secondsPerMinute else { return nil }
        return closeMinute(endingAt: date)
    }

    @discardableResult
    private mutating func closeSecondAccumulator() -> Double? {
        defer { currentSecond = SecondAccumulator() }
        guard currentSecond.count >= Tuning.minimumSamplesPerSecond else { return nil }

        let variance = currentSecond.meanAxisVariance
        secondVariances.append(variance)
        liveActivity = activityIndex(forVariance: variance)

        accumulatePosture(currentSecond.meanAxes)
        return variance
    }

    private mutating func closeMinute(endingAt date: Date) -> MovementFeatures? {
        defer {
            secondVariances = []
            minuteSampleCount = 0
            minuteStart = date
            minutePostureChanged = false
        }

        guard let start = minuteStart else { return nil }

        recalibrateNoise()

        var activitySum = 0.0
        var maxBurst = 0.0
        var activeSeconds = 0
        let activeFloor = noiseVariance * Tuning.activeMargin

        for variance in secondVariances {
            let index = activityIndex(forVariance: variance)
            activitySum += index
            maxBurst = max(maxBurst, index)
            if variance > activeFloor { activeSeconds += 1 }
        }

        return MovementFeatures(
            date: start,
            activityIndex: activitySum,
            activeSeconds: activeSeconds,
            maxBurst: maxBurst,
            postureChanged: minutePostureChanged,
            sampleCount: minuteSampleCount
        )
    }

    /// The floor follows the minute's QUIETEST second: even a restless minute
    /// almost always contains one still second, so this converges on sensor
    /// noise without ever learning real movement as background.
    private mutating func recalibrateNoise() {
        guard let quietest = secondVariances.min(), quietest > 0 else { return }

        if noiseCalibrated {
            noiseVariance = max(
                Tuning.minimumNoiseVariance,
                noiseVariance * (1 - Tuning.noiseAdaptationRate) + quietest * Tuning.noiseAdaptationRate
            )
        } else {
            noiseVariance = max(Tuning.minimumNoiseVariance, quietest)
            noiseCalibrated = true
        }
    }

    /// Collects per-second mean axes into 5-second blocks and flags the minute
    /// when the settled device angle steps by more than the threshold.
    private mutating func accumulatePosture(_ axes: (x: Double, y: Double, z: Double)) {
        blockAxes.append(axes)
        guard blockAxes.count >= Tuning.postureBlockSeconds else { return }
        defer { blockAxes = [] }

        let n = Double(blockAxes.count)
        let mx = blockAxes.reduce(0) { $0 + $1.x } / n
        let my = blockAxes.reduce(0) { $0 + $1.y } / n
        let mz = blockAxes.reduce(0) { $0 + $1.z } / n

        let horizontal = (mx * mx + my * my).squareRoot()
        let angle = atan2(mz, horizontal) * 180 / .pi

        if let settled = settledAngle, abs(angle - settled) > Tuning.postureAngleThreshold {
            minutePostureChanged = true
        }
        settledAngle = angle
    }
}
