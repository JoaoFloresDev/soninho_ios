//
//  SmartAlarmAutoArm.swift
//  soninho
//

import Foundation

// MARK: - Smart Alarm Auto Arm
/// Decides when a smart alarm justifies switching the motion monitor on by
/// itself.
///
/// The field failure this exists for: the user set a smart alarm, locked the
/// phone and went to sleep — and the alarm rang at the fixed time, because the
/// smart window only armed inside a manually started sleep-tracking session.
/// Nothing told them that. A smart alarm must not depend on the user
/// remembering a second step: while the alarm keep-alive holds the process
/// open overnight, it asks this type whether monitoring should be running and
/// starts an alarm-only session when the answer is yes.
enum SmartAlarmAutoArm {

    // MARK: - Constants
    enum Tuning {
        /// Minutes of monitoring wanted BEFORE the wake window opens: enough
        /// for noise calibration plus a full sleep cycle of context, so the
        /// window opens with the sleeper's depth already known.
        static let leadMinutes = 90
    }

    // MARK: - Public Methods

    /// The enabled smart alarm with the NEAREST upcoming occurrence, or nil.
    /// Nearest matters: with a daily alarm for tomorrow and a one-off in
    /// twenty minutes, arming the daily one's window would sleep through the
    /// one that is about to ring.
    static func earliestSmartAlarm(
        alarms: [AlarmModel],
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> (alarm: AlarmModel, occurrence: Date)? {
        alarms
            .filter { $0.isEnabled && $0.isSmartAlarm }
            .compactMap { alarm -> (AlarmModel, Date)? in
                guard let scheduled = AlarmOccurrenceLedger.scheduledDate(
                    for: alarm, now: now, defaults: defaults
                ) else { return nil }
                return (alarm, scheduled.date)
            }
            .min { $0.1 < $1.1 }
    }

    /// The enabled smart alarm whose upcoming occurrence wants monitoring
    /// right now, or nil. Pure — the callers own the side effects.
    static func alarmNeedingMonitoring(
        alarms: [AlarmModel],
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> (alarm: AlarmModel, occurrence: Date)? {
        guard let (alarm, occurrence) = earliestSmartAlarm(
            alarms: alarms, now: now, defaults: defaults
        ) else { return nil }

        let armFrom = occurrence.addingTimeInterval(
            -Double((alarm.smartAlarmWindow + Tuning.leadMinutes) * 60)
        )
        guard now >= armFrom && now < occurrence else { return nil }
        return (alarm, occurrence)
    }

    /// Starts the alarm-only session when one is due. Safe to call every few
    /// seconds from the keep-alive tick and the foreground timer.
    @MainActor
    static func checkAndArmIfDue() {
        let monitor = MotionSleepMonitor.shared
        guard !monitor.isMonitoring else { return }
        guard !UserDefaults.standard.bool(forKey: StorageKeys.isCurrentlyTracking) else { return }

        guard alarmNeedingMonitoring(alarms: StorageService.shared.loadAlarms()) != nil else { return }
        monitor.startAlarmOnlyMonitoring()
    }
}
