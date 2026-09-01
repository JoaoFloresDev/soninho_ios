//
//  SmartWakeDecider.swift
//  soninho
//

import Foundation

// MARK: - Smart Wake Decider
/// Decides, minute by minute, whether the smart alarm should ring now.
///
/// The window is a budget, not a green light: ringing at minute one of a
/// 30-minute window throws away 29 minutes of sleep for a moment that is
/// probably no better than the next one. So the bar starts near "plainly
/// awake" and decays towards "light sleep is good enough" as the fixed time
/// approaches — and if nothing ever qualifies, the AlarmKit alarm at the fixed
/// time is the guaranteed fallback. Nothing rings at the start of the window.
///
/// Codable on purpose: the decider persists with the sleep session, so a
/// mid-window relaunch neither forgets that it already fired nor loses the
/// confirmation count.
struct SmartWakeDecider: Codable {

    // MARK: - Constants
    enum Tuning {
        /// Qualifying minutes required — one good minute can just be a turn.
        static let confirmationMinutes = 2
        /// Nothing fires in the first slice of the window unless the sleeper
        /// is plainly awake.
        static let earliestProgress: Double = 0.15
        /// Readiness demanded at the start of the window (essentially awake).
        static let startingBar: Double = 0.92
        /// Readiness demanded at the very end (light sleep is good enough).
        static let endingBar: Double = 0.40
        /// At or above this the sleeper is treated as already awake.
        static let awakeScore: Double = 0.92
    }

    // MARK: - Properties
    let windowStart: Date
    let windowEnd: Date
    /// The alarm this window belongs to.
    let alarmId: String

    private(set) var qualifyingMinutes = 0
    private(set) var hasFired = false

    // MARK: - Init
    init(windowStart: Date, windowEnd: Date, alarmId: String) {
        self.windowStart = windowStart
        self.windowEnd = windowEnd
        self.alarmId = alarmId
    }

    // MARK: - Computed Properties

    /// The bar the readiness score must clear right now.
    func bar(at now: Date) -> Double {
        let total = windowEnd.timeIntervalSince(windowStart)
        guard total > 0 else { return Tuning.startingBar }
        let progress = min(1, max(0, now.timeIntervalSince(windowStart) / total))
        return Tuning.startingBar - (Tuning.startingBar - Tuning.endingBar) * progress
    }

    func isInsideWindow(_ now: Date) -> Bool {
        now >= windowStart && now <= windowEnd
    }

    // MARK: - Public Methods

    /// Feeds one readiness evaluation. Returns true exactly once, at the
    /// moment the alarm should ring.
    mutating func evaluate(score: Double, calibrated: Bool, at now: Date) -> Bool {
        guard !hasFired, isInsideWindow(now) else { return false }

        // An uncalibrated engine has no idea — judging on it is what used to
        // make the alarm fire the moment the window opened.
        guard calibrated else {
            qualifyingMinutes = 0
            return false
        }

        let total = windowEnd.timeIntervalSince(windowStart)
        guard total > 0 else { return false }
        let progress = min(1, max(0, now.timeIntervalSince(windowStart) / total))
        let isAwake = score >= Tuning.awakeScore

        // Early in the window only a sleeper who is plainly awake is worth
        // ringing for — everyone else still has sleep to gain.
        guard progress >= Tuning.earliestProgress || isAwake else {
            qualifyingMinutes = 0
            return false
        }

        qualifyingMinutes = score >= bar(at: now) ? qualifyingMinutes + 1 : 0

        let needed = isAwake ? 1 : Tuning.confirmationMinutes
        guard qualifyingMinutes >= needed else { return false }

        hasFired = true
        return true
    }
}
