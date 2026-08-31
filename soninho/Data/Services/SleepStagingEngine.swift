//
//  SleepStagingEngine.swift
//  soninho
//

import Foundation

// MARK: - Sleep Staging Engine
/// Turns a night of one-minute movement readings into sleep stages, and finds
/// the best moment to wake the sleeper inside the smart-alarm window.
///
/// What actigraphy can and cannot know is worth stating plainly, because the
/// previous implementation got it backwards. Movement reliably separates
/// **sleep from wake** — that is what decades of actigraphy research supports.
/// It cannot truly resolve deep vs REM vs light, especially from a phone lying
/// on a mattress rather than a wrist. So here sleep/wake is decided from the
/// data, depth is a graded estimate of how still the sleeper is, and the
/// 90-minute cycle is used only as a weak tiebreaker for labelling REM. The old
/// code derived the phase from elapsed time and let movement merely nudge it,
/// which meant the phase was mostly fiction and the smart alarm fired on it.
///
/// Two adaptations are deliberate:
///
/// 1. **Cole-Kripke's weighting kernel, not its constant.** The 1992 weights
///    are used to smooth each minute against its neighbours, so a single turn
///    in bed cannot read as waking up. The published decision constant is
///    calibrated for ActiGraph wrist counts, which a phone on a mattress does
///    not produce, so it is not reused.
/// 2. **Self-calibration.** Thresholds are expressed as multiples of *this
///    night's own* typical movement. Phones, mattresses and sleeping positions
///    differ by more than any fixed threshold could absorb.
struct SleepStagingEngine {

    // MARK: - Epoch
    /// One aggregated minute of movement.
    struct Epoch {
        let date: Date
        /// Mean deviation from rest over the minute, in g. Device-dependent.
        let activity: Double
        /// Movement smoothed against neighbouring minutes.
        var smoothed: Double = 0
        var phase: SleepPhase = .light
    }

    // MARK: - Constants
    private enum Tuning {
        /// Cole-Kripke (1992) one-minute weights: four minutes back, the current
        /// minute, two minutes forward. The current minute dominates; the
        /// neighbours damp isolated spikes.
        static let weights: [Double] = [404, 598, 326, 441, 1408, 508, 350]
        static let currentIndex = 4
        /// Minutes of lookahead the kernel needs. A stage is therefore settled
        /// two minutes late, which is immaterial inside a 30-minute window.
        static let lookahead = 2

        /// A minute this many times the night's typical movement is real motion,
        /// not breathing — the sleeper is awake or close to it.
        static let awakeFactor: Double = 3.5
        /// Below this multiple of the night's typical movement the sleeper is
        /// unusually still, which is the best proxy for deep sleep available.
        static let deepFactor: Double = 0.65

        /// Until this many minutes are recorded the reference is too noisy to
        /// calibrate against, so everything is reported as light sleep.
        static let minimumEpochsForReference = 8
        /// Guards against dividing by an essentially motionless reference.
        static let activityFloor: Double = 0.0015

        static let cycleMinutes: Double = 90
    }

    // MARK: - Properties
    private(set) var epochs: [Epoch] = []
    private let sessionStart: Date

    // MARK: - Init
    init(sessionStart: Date) {
        self.sessionStart = sessionStart
    }

    // MARK: - Computed Properties

    /// This night's typical movement — the median smoothed minute. Median
    /// rather than mean so a few restless minutes cannot drag the baseline up.
    private var reference: Double {
        let settled = epochs.compactMap { $0.smoothed > 0 ? $0.smoothed : nil }.sorted()
        guard !settled.isEmpty else { return Tuning.activityFloor }
        let median = settled[settled.count / 2]
        return max(median, Tuning.activityFloor)
    }

    /// Whether enough of the night has been observed to judge anything.
    var isCalibrated: Bool {
        epochs.count >= Tuning.minimumEpochsForReference
    }

    /// The most recently settled stage, or light sleep before the lookahead
    /// has enough minutes to settle anything.
    var currentPhase: SleepPhase {
        let index = epochs.count - 1 - Tuning.lookahead
        guard index >= 0 else { return .light }
        return epochs[index].phase
    }

    // MARK: - Public Methods

    /// Records a minute of movement and restages the epochs that the new
    /// lookahead now settles. Returns the stage that just became final.
    @discardableResult
    mutating func record(activity: Double, at date: Date = Date()) -> SleepPhase {
        epochs.append(Epoch(date: date, activity: activity))
        smoothRecentEpochs()
        stageRecentEpochs()
        return currentPhase
    }

    /// How close to the surface the sleeper is right now, 0 (deep) to 1 (awake).
    ///
    /// Blends the settled stage with live movement, because someone stirring is
    /// nearer to waking than the stage alone suggests.
    func wakeReadiness() -> Double {
        guard isCalibrated else { return 0 }

        let index = epochs.count - 1 - Tuning.lookahead
        guard index >= 0 else { return 0 }

        // Weight the settled minutes so the most recent counts most.
        let window = epochs[max(0, index - 2)...index]
        var weighted = 0.0
        var weightSum = 0.0
        for (offset, epoch) in window.enumerated() {
            let weight = Double(offset + 1)
            weighted += phaseReadiness(epoch.phase) * weight
            weightSum += weight
        }
        let stageComponent = weightSum > 0 ? weighted / weightSum : 0

        // Live movement, as a fraction of what counts as being awake.
        let live = epochs[epochs.count - 1].activity
        let motionComponent = min(live / (reference * Tuning.awakeFactor), 1.0)

        return min(1.0, stageComponent * 0.7 + motionComponent * 0.3)
    }

    /// Stages assembled into contiguous spans, for the night's report.
    func phaseSpans(now: Date = Date()) -> [SleepPhaseData] {
        guard !epochs.isEmpty else {
            return [SleepPhaseData(phase: .light, startTime: sessionStart, endTime: now)]
        }

        var spans: [SleepPhaseData] = []
        var spanStart = epochs[0].date
        var spanPhase = epochs[0].phase

        for epoch in epochs.dropFirst() {
            guard epoch.phase != spanPhase else { continue }
            spans.append(SleepPhaseData(phase: spanPhase, startTime: spanStart, endTime: epoch.date))
            spanStart = epoch.date
            spanPhase = epoch.phase
        }
        spans.append(SleepPhaseData(phase: spanPhase, startTime: spanStart, endTime: now))
        return spans
    }

    // MARK: - Private Methods

    /// How good each stage is as a wake-up point.
    private func phaseReadiness(_ phase: SleepPhase) -> Double {
        switch phase {
        case .awake: return 1.0
        case .light: return 0.7
        case .rem:   return 0.45
        case .deep:  return 0.0
        }
    }

    /// Applies the Cole-Kripke kernel to every epoch whose neighbours are known.
    private mutating func smoothRecentEpochs() {
        let weights = Tuning.weights
        let last = epochs.count - 1

        for index in stride(from: last, through: max(0, last - weights.count), by: -1) {
            var weighted = 0.0
            var weightSum = 0.0
            for (offset, weight) in weights.enumerated() {
                let neighbour = index + offset - Tuning.currentIndex
                guard neighbour >= 0, neighbour < epochs.count else { continue }
                weighted += epochs[neighbour].activity * weight
                weightSum += weight
            }
            guard weightSum > 0 else { continue }
            epochs[index].smoothed = weighted / weightSum
        }
    }

    /// Assigns a stage to every epoch the lookahead now covers.
    private mutating func stageRecentEpochs() {
        guard isCalibrated else { return }

        let reference = self.reference
        let last = epochs.count - 1

        for index in stride(from: last, through: max(0, last - Tuning.lookahead - 1), by: -1) {
            epochs[index].phase = stage(at: index, reference: reference)
        }
    }

    private func stage(at index: Int, reference: Double) -> SleepPhase {
        let level = epochs[index].smoothed / reference

        // Sleep/wake is the one call movement can actually make.
        if level >= Tuning.awakeFactor {
            return .awake
        }

        // Within sleep, all we honestly have is how still the sleeper is.
        if level <= Tuning.deepFactor {
            // Very still. Late in the night the same stillness is more likely to
            // be REM than deep sleep, so the cycle acts as a tiebreaker here —
            // and only here.
            return looksLikeREMWindow(at: index) ? .rem : .deep
        }

        return .light
    }

    /// Weak prior: REM lengthens and deep sleep shortens as the night goes on,
    /// so still minutes late in a cycle are more likely REM than deep.
    private func looksLikeREMWindow(at index: Int) -> Bool {
        let elapsed = epochs[index].date.timeIntervalSince(sessionStart) / 60
        guard elapsed > Tuning.cycleMinutes else { return false }

        let position = elapsed.truncatingRemainder(dividingBy: Tuning.cycleMinutes) / Tuning.cycleMinutes
        return position > 0.55
    }
}
