//
//  SleepStagingEngine.swift
//  soninho
//

import Foundation

// MARK: - Sound Minute
/// One minute of microphone evidence, produced by the sound monitor.
struct SoundMinute: Codable {
    /// Seconds of the minute the classifier heard snoring or steady breathing.
    let sleepSoundSeconds: Int
    /// Seconds of speech or loud disturbance — evidence of being awake.
    let disturbanceSeconds: Int
}

// MARK: - Sleep Staging Engine
/// Turns per-minute movement features into sleep stages and a wake-readiness
/// score for the smart alarm.
///
/// Movement honestly separates **sleep from wake**; within sleep, all a mattress
/// phone can grade is stillness. So wake is decided by a Cole-Kripke-style
/// weighted kernel over the surrounding minutes, depth is read from how long
/// the sleeper has been still (deep sleep is long unbroken stillness; light
/// sleep surrounds movement events), and the 90-minute cycle acts only as a
/// weak tiebreaker for labelling REM. Everything is scaled to THIS night's own
/// typical turn, because phones, mattresses and sleepers differ by more than
/// any fixed constant could absorb.
///
/// The engine is Codable: the whole night survives a relaunch, and minutes the
/// process was dead are recorded as gaps — a gap must never masquerade as
/// stillness, or a suspension would fake a block of deep sleep.
struct SleepStagingEngine: Codable {

    // MARK: - Epoch
    /// One staged minute of the night.
    struct Epoch: Codable {
        let date: Date
        let activityIndex: Double
        let activeSeconds: Int
        let maxBurst: Double
        let postureChanged: Bool
        let sleepSoundSeconds: Int
        let disturbanceSeconds: Int
        /// True when the process was dead and no data exists for this minute.
        let isGap: Bool
        var phase: SleepPhase = .light

        /// Whether this minute contains a real movement event.
        func isEvent(turnScale: Double) -> Bool {
            guard !isGap else { return false }
            return postureChanged || activityIndex > turnScale * Tuning.eventFraction
        }
    }

    // MARK: - Constants
    enum Tuning {
        /// Cole-Kripke (1992) one-minute weights: four minutes back, the
        /// current minute, two ahead. The published decision constant is
        /// calibrated for wrist-worn ActiGraph counts, so only the KERNEL is
        /// reused; the threshold is expressed in this night's own turn units.
        static let kernelWeights: [Double] = [106, 54, 58, 76, 230, 74, 67]
        static let kernelCurrentIndex = 4
        static let lookahead = 2

        /// Kernel-weighted activity (in turns) at or above which the sleeper
        /// is awake.
        static let wakeScore: Double = 1.0
        /// A minute moving for this long is wake regardless of the kernel.
        static let sustainedAwakeSeconds = 20
        /// Snoring through most of a minute vetoes a wake call — people do not
        /// snore while awake; the movement was a turn, not an awakening.
        static let snoreVetoSeconds = 20

        /// Fraction of a typical turn that still counts as a movement event.
        static let eventFraction: Double = 0.15
        /// Normalized activity is capped so one violent minute cannot dominate
        /// the kernel for its whole window.
        static let activityCap: Double = 4.0
        /// Fallback scale (g·s of activity in a minute) for a typical turn,
        /// used until the night has produced turns of its own to measure.
        static let fallbackTurnScale: Double = 0.05
        static let minimumTurnScale: Double = 0.01

        /// Unbroken stillness this long reads as deep sleep (or REM, late in a
        /// cycle); the first minutes after a movement event are the descent.
        static let deepRunMinutes = 10
        static let descentMinutes = 3

        static let minimumEpochsForCalibration = 8
        /// Staged sleep minutes required before the smart alarm may ring
        /// early at all.
        static let minimumSleepMinutesForEarlyWake = 15
        static let cycleMinutes: Double = 90
        /// REM begins to be plausible only after the first full cycle.
        static let remEarliestMinutes: Double = 90
        static let remCyclePosition: Double = 0.55
    }

    // MARK: - Properties
    private(set) var epochs: [Epoch] = []
    let sessionStart: Date

    // MARK: - Init
    init(sessionStart: Date) {
        self.sessionStart = sessionStart
    }

    // MARK: - Computed Properties

    /// This night's typical turn: the median activity of the minutes that had
    /// any. Movement is sparse, so the median of NONZERO minutes is the unit —
    /// a median over all minutes would be zero every quiet night.
    ///
    /// Minutes of SUSTAINED movement are excluded: scrolling in bed before a
    /// nap moves the phone for most of every minute, and letting that into
    /// the median inflates the scale until real sleep turns — a hundredth of
    /// the size — stop registering as events. The unit must be the turn, not
    /// the phone use.
    var turnScale: Double {
        let moving = epochs.compactMap { epoch -> Double? in
            guard !epoch.isGap,
                  epoch.activityIndex > 0,
                  epoch.activeSeconds < Tuning.sustainedAwakeSeconds else { return nil }
            return epoch.activityIndex
        }.sorted()
        guard moving.count >= 3, let median = moving[safe: moving.count / 2] else {
            return Tuning.fallbackTurnScale
        }
        return max(median, Tuning.minimumTurnScale)
    }

    /// Whether the night has actually contained sleep yet. Someone who has
    /// not slept is not "surfacing from sleep" — before this is true the
    /// early ring must stay silent and the fixed time do the waking. (Without
    /// it, a sleeper still settling down when the wake window opens reads as
    /// "plainly awake" and gets rung at the window's first minute.)
    var hasSleptEnough: Bool {
        guard isCalibrated else { return false }
        let sleepMinutes = epochs.filter { !$0.isGap && $0.phase != .awake }.count
        return sleepMinutes >= Tuning.minimumSleepMinutesForEarlyWake
    }

    var isCalibrated: Bool {
        epochs.filter { !$0.isGap }.count >= Tuning.minimumEpochsForCalibration
    }

    /// The most recently settled stage (the kernel needs two minutes of
    /// lookahead before a minute stops moving).
    var currentPhase: SleepPhase {
        let index = epochs.count - 1 - Tuning.lookahead
        guard let epoch = epochs[safe: max(index, 0)] else { return .light }
        return epoch.phase
    }

    /// Minutes with real data — for judging whether the night produced any
    /// usable signal at all.
    var observedMinutes: Int {
        epochs.filter { !$0.isGap }.count
    }

    /// Movement events seen tonight. A whole night at zero means the phone was
    /// not coupled to the sleeper (nightstand) or the sensor was dead.
    var eventCount: Int {
        let scale = turnScale
        return epochs.filter { $0.isEvent(turnScale: scale) }.count
    }

    // MARK: - Public Methods

    /// Records a minute and restages the night. Returns the settled stage.
    @discardableResult
    mutating func record(_ features: MovementFeatures, sound: SoundMinute? = nil) -> SleepPhase {
        if features.hasEnoughData {
            epochs.append(Epoch(
                date: features.date,
                activityIndex: features.activityIndex,
                activeSeconds: features.activeSeconds,
                maxBurst: features.maxBurst,
                postureChanged: features.postureChanged,
                sleepSoundSeconds: sound?.sleepSoundSeconds ?? 0,
                disturbanceSeconds: sound?.disturbanceSeconds ?? 0,
                isGap: false
            ))
        } else {
            // A starved minute must not read as stillness.
            epochs.append(gapEpoch(at: features.date))
        }
        restage()
        return currentPhase
    }

    /// Registers minutes the process was dead. They break stillness runs and
    /// carry no movement information.
    mutating func recordGap(from start: Date, to end: Date) {
        var minute = start
        while minute < end {
            epochs.append(gapEpoch(at: minute))
            minute = minute.addingTimeInterval(60)
        }
        restage()
    }

    /// Replaces gap epochs with real minutes recovered later (the system's
    /// sensor recorder keeps logging while the app is dead). Only minutes that
    /// land on an existing gap are accepted — real observations never get
    /// overwritten by a backfill.
    mutating func fillGaps(with minutes: [MovementFeatures]) {
        guard !minutes.isEmpty else { return }

        for features in minutes where features.hasEnoughData {
            guard let index = epochs.firstIndex(where: {
                $0.isGap && abs($0.date.timeIntervalSince(features.date)) < 45
            }) else { continue }

            epochs[index] = Epoch(
                date: epochs[index].date,
                activityIndex: features.activityIndex,
                activeSeconds: features.activeSeconds,
                maxBurst: features.maxBurst,
                postureChanged: features.postureChanged,
                sleepSoundSeconds: 0,
                disturbanceSeconds: 0,
                isGap: false
            )
        }
        restage()
    }

    /// How close to the surface the sleeper is right now, 0 (deep) to 1
    /// (awake). `liveActivity` is the current one-second activity index from
    /// the extractor, so a stir registers before its minute closes.
    func wakeReadiness(liveActivity: Double = 0) -> Double {
        guard isCalibrated else { return 0 }

        let settledIndex = epochs.count - 1 - Tuning.lookahead
        guard settledIndex >= 0 else { return 0 }

        // Settled stages, most recent counting most.
        var weighted = 0.0
        var weightSum = 0.0
        for (offset, epoch) in epochs[max(0, settledIndex - 2)...settledIndex].enumerated() {
            let weight = Double(offset + 1)
            weighted += phaseReadiness(epoch.phase) * weight
            weightSum += weight
        }
        let stageComponent = weightSum > 0 ? weighted / weightSum : 0

        // Arousal: movement in the last minutes plus what is happening right
        // now. A posture change is the strongest sign the sleeper surfaced.
        let scale = turnScale
        var arousal = 0.0
        for (offset, epoch) in epochs.suffix(3).enumerated() {
            guard !epoch.isGap else { continue }
            let recency = Double(offset + 1) / 3.0
            if epoch.postureChanged { arousal = max(arousal, 0.8 * recency) }
            else if epoch.isEvent(turnScale: scale) { arousal = max(arousal, 0.5 * recency) }
        }
        let liveComponent = min(liveActivity / (scale / 4), 1.0)
        arousal = min(1.0, max(arousal, liveComponent))

        return min(1.0, stageComponent * 0.55 + arousal * 0.45)
    }

    /// Stages assembled into contiguous spans for the night's report.
    func phaseSpans(now: Date = Date()) -> [SleepPhaseData] {
        guard let first = epochs.first else {
            return [SleepPhaseData(phase: .light, startTime: sessionStart, endTime: now)]
        }

        var spans: [SleepPhaseData] = []
        var spanStart = first.date
        var spanPhase = first.phase

        for epoch in epochs.dropFirst() where epoch.phase != spanPhase {
            spans.append(SleepPhaseData(phase: spanPhase, startTime: spanStart, endTime: epoch.date))
            spanStart = epoch.date
            spanPhase = epoch.phase
        }
        spans.append(SleepPhaseData(phase: spanPhase, startTime: spanStart, endTime: now))
        return spans
    }

    // MARK: - Private Methods

    private func gapEpoch(at date: Date) -> Epoch {
        Epoch(
            date: date, activityIndex: 0, activeSeconds: 0, maxBurst: 0,
            postureChanged: false, sleepSoundSeconds: 0, disturbanceSeconds: 0,
            isGap: true
        )
    }

    private func phaseReadiness(_ phase: SleepPhase) -> Double {
        switch phase {
        case .awake: return 1.0
        case .light: return 0.7
        case .rem:   return 0.45
        case .deep:  return 0.0
        }
    }

    /// Restages the whole night. At one epoch per minute this is at most a few
    /// hundred elements — recomputing everything beats managing incremental
    /// state, and lets stillness runs upgrade to deep retroactively.
    private mutating func restage() {
        guard isCalibrated else { return }

        let scale = turnScale
        let normalized: [Double] = epochs.map { epoch in
            guard !epoch.isGap else { return 0 }
            let value = min(epoch.activityIndex / scale, Tuning.activityCap)
            // Movement WHILE snoring is sleep movement — a turn, not an
            // awakening. Dampening it here keeps the kernel from smearing a
            // snoring toss into "awake" on the silent minutes around it.
            if epoch.sleepSoundSeconds >= Tuning.snoreVetoSeconds {
                return min(value, 1.0)
            }
            return value
        }

        // Pass 1 — sleep/wake via the kernel (gaps neither wake nor sleep).
        var wake = [Bool](repeating: false, count: epochs.count)
        for index in epochs.indices where !epochs[index].isGap {
            var weighted = 0.0
            var weightSum = 0.0
            for (offset, weight) in Tuning.kernelWeights.enumerated() {
                let neighbour = index + offset - Tuning.kernelCurrentIndex
                guard let value = normalized[safe: neighbour],
                      epochs[safe: neighbour]?.isGap == false else { continue }
                weighted += value * weight
                weightSum += weight
            }
            let score = weightSum > 0 ? weighted / weightSum : 0

            var isAwake = score >= Tuning.wakeScore
                || epochs[index].activeSeconds >= Tuning.sustainedAwakeSeconds
            if epochs[index].sleepSoundSeconds >= Tuning.snoreVetoSeconds {
                isAwake = false
            }
            wake[index] = isAwake
        }

        // Pass 2 — depth from stillness runs between events, wake and gaps.
        var runStart: Int? = nil
        for index in epochs.indices {
            let breaksRun = epochs[index].isGap || wake[index] || epochs[index].isEvent(turnScale: scale)

            if breaksRun {
                if let start = runStart { stageRun(from: start, to: index - 1) }
                runStart = nil
                epochs[index].phase = wake[index] ? .awake : .light
            } else if runStart == nil {
                runStart = index
            }
        }
        if let start = runStart { stageRun(from: start, to: epochs.count - 1) }
    }

    /// Stages one unbroken run of still sleep minutes. Long runs read as deep
    /// (or REM late in a cycle); short ones stay light. The first minutes are
    /// the descent and stay light.
    private mutating func stageRun(from start: Int, to end: Int) {
        let length = end - start + 1

        guard length >= Tuning.deepRunMinutes else {
            for index in start...end { epochs[index].phase = .light }
            return
        }

        for index in start...end {
            if index < start + Tuning.descentMinutes {
                epochs[index].phase = .light
            } else {
                epochs[index].phase = looksLikeREMWindow(at: index) ? .rem : .deep
            }
        }
    }

    /// Weak prior: REM lengthens as the night goes on, so stillness late in a
    /// cycle is more likely REM than deep — never before the first full cycle.
    private func looksLikeREMWindow(at index: Int) -> Bool {
        guard let epoch = epochs[safe: index] else { return false }
        let elapsed = epoch.date.timeIntervalSince(sessionStart) / 60
        guard elapsed > Tuning.remEarliestMinutes else { return false }

        let position = elapsed.truncatingRemainder(dividingBy: Tuning.cycleMinutes) / Tuning.cycleMinutes
        return position > Tuning.remCyclePosition
    }
}
