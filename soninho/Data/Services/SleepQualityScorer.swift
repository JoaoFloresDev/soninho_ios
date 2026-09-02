//
//  SleepQualityScorer.swift
//  soninho
//

import Foundation

// MARK: - Sleep Quality Scorer
/// Scores a night from its staged phases. Pure so the test harness can pin
/// the scoring against scripted nights.
///
/// Bands are symmetric: too MUCH "deep" is as suspect as too little — a
/// phone on the nightstand reads as one unbroken stillness run and used to
/// score 95 for a night the engine never actually measured.
enum SleepQualityScorer {

    // MARK: - Constants
    /// Ideal bands, shared with the UI so the badge and the ring can never
    /// disagree about the same number.
    static let deepIdealPercent = 15.0...25.0
    static let remIdealPercent = 15.0...25.0
    static let awakeOptimalFraction = 0.03

    // MARK: - Public Methods

    /// Quality score 0-100 from phase distribution and duration. Gap spans
    /// (minutes the app was not observing) count toward none of the phases.
    static func score(phases: [SleepPhaseData], totalDuration: TimeInterval) -> Int {
        guard totalDuration > 0, !phases.isEmpty else { return 50 }

        let gapDuration = phases.filter(\.isMissingData).reduce(0.0) { $0 + $1.duration }
        let observed = totalDuration - gapDuration
        guard observed > 0 else { return 50 }

        var score = 40

        let hours = totalDuration / 3600
        let deepDuration = phases.filter { $0.phase == .deep && !$0.isMissingData }.reduce(0.0) { $0 + $1.duration }
        let remDuration = phases.filter { $0.phase == .rem && !$0.isMissingData }.reduce(0.0) { $0 + $1.duration }
        let awakeDuration = phases.filter { $0.phase == .awake && !$0.isMissingData }.reduce(0.0) { $0 + $1.duration }
        let deepPct = (deepDuration / observed) * 100
        let remPct = (remDuration / observed) * 100
        let awakePct = (awakeDuration / observed) * 100

        // Duration score (7-9 hours ideal) — max +15.
        if hours >= 7 && hours <= 9 {
            score += 15
        } else if hours >= 6 && hours <= 10 {
            score += 10
        } else if hours >= 5 {
            score += 5
        }

        // Deep sleep (15-25% ideal) — max +20, penalty outside sane bounds.
        if deepIdealPercent.contains(deepPct) {
            score += 20
        } else if (10..<15).contains(deepPct) || (25...35).contains(deepPct) {
            score += 12
        } else if (5..<10).contains(deepPct) || (35...45).contains(deepPct) {
            score += 5
        } else {
            score -= 10
        }

        // REM sleep (15-25% ideal) — max +15, penalty outside sane bounds.
        if remIdealPercent.contains(remPct) {
            score += 15
        } else if (10..<15).contains(remPct) || (25...35).contains(remPct) {
            score += 8
        } else if (5..<10).contains(remPct) {
            score += 3
        } else {
            score -= 10
        }

        // Low awake time — max +10.
        if awakePct < 3 {
            score += 10
        } else if awakePct < 8 {
            score += 5
        } else if awakePct > 15 {
            score -= 10
        }

        // Both deep and REM present in plausible amounts is healthy.
        let phasesPresent = [(3.0...45.0).contains(deepPct), (3.0...45.0).contains(remPct)]
            .filter { $0 }.count
        if phasesPresent == 2 {
            score += 10
        } else if phasesPresent == 1 {
            score += 3
        }

        return min(100, max(0, score))
    }
}
