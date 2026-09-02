//
//  SleepNightRecorder.swift
//  soninho
//

import Foundation

// MARK: - Sleep Night Recorder
/// Ends a tracked night and writes the SleepRecord. Extracted from the
/// tracker ViewModel because the ViewModel only exists once the Sleep tab has
/// been opened — a night dismissed from the alarm screen on a fresh launch
/// used to stay "tracking" for hours and then be discarded. Idempotent: the
/// first caller wins, everyone else finds the flag already cleared.
@MainActor
enum SleepNightRecorder {

    // MARK: - Constants
    /// Below this the "night" was a mis-tap: no record, no streak, no
    /// analytics — a 3-second session must not consume a streak day.
    static let minimumDuration: TimeInterval = 15 * 60

    // MARK: - Public Methods

    /// Finishes the tracked night if one is running. Returns the record it
    /// saved, nil when there was nothing to finish or too little to keep.
    @discardableResult
    static func finishTrackedNight(endTime: Date = Date()) -> SleepRecord? {
        let defaults = UserDefaults.standard
        guard defaults.bool(forKey: StorageKeys.isCurrentlyTracking),
              let startTime = defaults.object(forKey: StorageKeys.trackingStartTime) as? Date else {
            return nil
        }

        // Claim the night before doing anything — a second observer arriving
        // a beat later must not save it twice.
        defaults.set(false, forKey: StorageKeys.isCurrentlyTracking)
        defaults.removeObject(forKey: StorageKeys.trackingStartTime)

        let monitor = MotionSleepMonitor.shared
        let duration = endTime.timeIntervalSince(startTime)

        guard duration >= minimumDuration else {
            monitor.stopMonitoring()
            return nil
        }

        // A night with zero observed minutes was never measured — save the
        // duration honestly, with no fabricated flat-light phases.
        let observed = monitor.observedMinutes
        let phases = observed > 0 ? monitor.getRecordedPhases() : []
        let qualityScore = SleepQualityScorer.score(phases: phases, totalDuration: duration)

        monitor.stopMonitoring()

        let record = SleepRecord(
            startTime: startTime,
            endTime: endTime,
            phases: phases,
            qualityScore: qualityScore
        )

        var records = StorageService.shared.loadCachedSleepRecords()
        records.insert(record, at: 0)
        StorageService.shared.saveSleepRecords(records)
        StorageService.shared.updateStreak(for: record.endTime)

        Analytics.coreAction("night_tracked")
        _ = RatingGateService.shared.recordPositiveEvent()

        return record
    }
}
