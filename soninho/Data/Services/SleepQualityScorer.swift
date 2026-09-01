//
//  SleepQualityScorer.swift
//  soninho
//

import Foundation

// MARK: - Sleep Quality Scorer
/// Scores a night from its staged phases. Pure so the test harness can pin
/// the scoring against scripted nights.
enum SleepQualityScorer {

    // MARK: - Public Methods

    /// Quality score 0-100 from phase distribution and duration.
    static func score(phases: [SleepPhaseData], totalDuration: TimeInterval) -> Int {
        guard totalDuration > 0 else { return 50 }

        var score = 40

        let hours = totalDuration / 3600
        let deepDuration = phases.filter { $0.phase == .deep }.reduce(0.0) { $0 + $1.duration }
        let remDuration = phases.filter { $0.phase == .rem }.reduce(0.0) { $0 + $1.duration }
        let awakeDuration = phases.filter { $0.phase == .awake }.reduce(0.0) { $0 + $1.duration }
        let deepPct = (deepDuration / totalDuration) * 100
        let remPct = (remDuration / totalDuration) * 100
        let awakePct = (awakeDuration / totalDuration) * 100

        // Duration score (7-9 hours ideal) — max +15.
        if hours >= 7 && hours <= 9 {
            score += 15
        } else if hours >= 6 && hours <= 10 {
            score += 10
        } else if hours >= 5 {
            score += 5
        }

        // Deep sleep (15-25% ideal) — max +20, penalty for missing.
        if deepPct >= 15 && deepPct <= 25 {
            score += 20
        } else if deepPct >= 10 {
            score += 12
        } else if deepPct >= 5 {
            score += 5
        } else {
            score -= 10
        }

        // REM sleep (15-25% ideal) — max +15, penalty for missing.
        if remPct >= 15 && remPct <= 25 {
            score += 15
        } else if remPct >= 10 {
            score += 8
        } else if remPct >= 5 {
            score += 3
        } else {
            score -= 10
        }

        // Low awake time (<5% ideal) — max +10.
        if awakePct < 3 {
            score += 10
        } else if awakePct < 8 {
            score += 5
        } else if awakePct > 15 {
            score -= 10
        }

        // Phase diversity bonus — having all phases present is healthy.
        let phasesPresent = [deepPct > 3, remPct > 3].filter { $0 }.count
        if phasesPresent == 2 {
            score += 10
        } else if phasesPresent == 1 {
            score += 3
        }

        return min(100, max(0, score))
    }
}
