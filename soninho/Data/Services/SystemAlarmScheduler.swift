//
//  SystemAlarmScheduler.swift
//  soninho
//

import Foundation
#if canImport(AlarmKit)
import AlarmKit
import SwiftUI
#endif

// MARK: - System Alarm Scheduler
/// Rings the alarm through AlarmKit on iOS 26 and later.
///
/// Everywhere else the app has to fake a persistent alarm with a burst of local
/// notifications spaced roughly thirty seconds apart, because a plain
/// notification is silenced by a Focus or the ringer switch — the two states a
/// sleeping person's phone is most likely to be in. AlarmKit is the supported
/// way to break through both, so where it exists it becomes the source of truth
/// and the burst is left as the fallback for older systems.
///
/// The app keeps the wake-up experience: AlarmKit guarantees the alarm sounds,
/// and its buttons hand control back here for the mission and the greeting.
@MainActor
enum SystemAlarmScheduler {

    // MARK: - Constants
    /// Alarms AlarmKit currently owns. Persisted because the background keep-alive
    /// runs in a fresh process after a relaunch and must still know to stay quiet.
    private static let ownedKey = "systemAlarm.ownedIds"

    // MARK: - Computed Properties

    /// Whether the system will ring this alarm on its own. The app's other ring
    /// paths — the notification burst and the background keep-alive — must stand
    /// down for these, or the sleeper gets two alarms at once.
    static func owns(_ alarmId: String) -> Bool {
        ownedIds().contains(alarmId)
    }

    private static func ownedIds() -> Set<String> {
        Set(UserDefaults.standard.stringArray(forKey: ownedKey) ?? [])
    }

    private static func setOwned(_ alarmId: String, _ owned: Bool) {
        var ids = ownedIds()
        if owned { ids.insert(alarmId) } else { ids.remove(alarmId) }
        UserDefaults.standard.set(Array(ids), forKey: ownedKey)
    }


    /// Whether this device can ring through Focus and the ringer switch.
    static var isAvailable: Bool {
        #if canImport(AlarmKit)
        if #available(iOS 26.0, *) { return true }
        #endif
        return false
    }

    // MARK: - Public Methods

    /// Asks for permission to schedule system alarms. Returns false when the
    /// framework is unavailable, so callers fall back to notifications.
    @discardableResult
    static func requestAuthorization() async -> Bool {
        #if canImport(AlarmKit)
        if #available(iOS 26.0, *) {
            let manager = AlarmManager.shared
            switch manager.authorizationState {
            case .authorized:
                return true
            case .denied:
                return false
            default:
                let state = try? await manager.requestAuthorization()
                return state == .authorized
            }
        }
        #endif
        return false
    }

    /// Rings `alarm` through the system RIGHT NOW — the smart-wake actuator.
    ///
    /// The in-app audio path plays sound from a black locked screen; AlarmKit
    /// puts the real alarm alert on the lock screen and breaks through Focus
    /// and the ringer switch. So when light sleep is detected, the pending
    /// fixed-time occurrence is cancelled and replaced by a fixed alarm a few
    /// seconds out. If the replacement cannot be scheduled, the original is
    /// restored — losing the fixed-time alarm is the one unacceptable outcome.
    static func fireNow(_ alarm: AlarmModel, originalOccurrence: Date) async -> Bool {
        #if canImport(AlarmKit)
        if #available(iOS 26.0, *) {
            guard owns(alarm.id.uuidString) else { return false }

            try? AlarmManager.shared.cancel(id: alarm.id)
            if await schedule(alarm, at: Date().addingTimeInterval(3), forceFixed: true) {
                return true
            }
            // Could not ring early — put the fixed-time alarm back.
            _ = await schedule(alarm, at: originalOccurrence)
            return false
        }
        #endif
        return false
    }

    /// Schedules `alarm` to ring at `date`. Returns whether AlarmKit took it —
    /// a false means the caller must keep the notification burst armed.
    /// `forceFixed` schedules a one-off at `date` even for a repeating alarm —
    /// used to ring early and to skip an occurrence that already rang (a
    /// weekly relative schedule cannot skip a single week).
    @discardableResult
    static func schedule(_ alarm: AlarmModel, at date: Date, forceFixed: Bool = false) async -> Bool {
        #if canImport(AlarmKit)
        if #available(iOS 26.0, *) {
            guard await requestAuthorization() else { return false }

            let stop = AlarmButton(
                text: LocalizedStringResource(stringLiteral: String(localized: "alarm_dismiss")),
                textColor: .white,
                systemImageName: "sun.max.fill"
            )
            let snooze = AlarmButton(
                text: LocalizedStringResource(stringLiteral: String(localized: "alarm_snooze")),
                textColor: .white,
                systemImageName: "clock"
            )

            // Snooze stays a system button only when the user allowed snoozing;
            // an alarm set to have none should not offer one on the lock screen.
            let alert = AlarmPresentation.Alert(
                title: LocalizedStringResource(stringLiteral: alarm.label ?? String(localized: "alarm_notification_title")),
                stopButton: stop,
                secondaryButton: alarm.snoozeLimit > 0 ? snooze : nil,
                secondaryButtonBehavior: alarm.snoozeLimit > 0 ? .countdown : nil
            )

            let attributes = AlarmAttributes<SunriseAlarmMetadata>(
                presentation: AlarmPresentation(alert: alert),
                metadata: SunriseAlarmMetadata(alarmId: alarm.id.uuidString),
                tintColor: AppColors.primary
            )

            // Stop hands control back to the app rather than ending the
            // wake-up, so the mission still stands between the sleeper and
            // going back to bed.
            let configuration = AlarmManager.AlarmConfiguration(
                countdownDuration: alarm.snoozeLimit > 0
                    ? Alarm.CountdownDuration(preAlert: nil, postAlert: TimeInterval(alarm.snoozeDuration * 60))
                    : nil,
                schedule: forceFixed ? .fixed(date) : schedule(for: alarm, at: date),
                attributes: attributes,
                stopIntent: StopAlarmIntent(alarmId: alarm.id.uuidString)
            )

            do {
                _ = try await AlarmManager.shared.schedule(id: alarm.id, configuration: configuration)
                setOwned(alarm.id.uuidString, true)
                return true
            } catch {
                // Falling back is safer than failing loudly: a missed alarm is a
                // far worse outcome than a duplicated one.
                return false
            }
        }
        #endif
        return false
    }

    /// A one-off alarm is a fixed date; a repeating one is a weekly recurrence,
    /// which AlarmKit renews on its own. Scheduling a repeating alarm as a fixed
    /// date would cover only its next occurrence and go quiet after that.
    @available(iOS 26.0, *)
    private static func schedule(for alarm: AlarmModel, at date: Date) -> Alarm.Schedule {
        guard !alarm.repeatDays.isEmpty else { return .fixed(date) }

        let components = Calendar.current.dateComponents([.hour, .minute], from: alarm.time)
        let time = Alarm.Schedule.Relative.Time(
            hour: components.hour ?? 0,
            minute: components.minute ?? 0
        )
        let days = alarm.repeatDays.sorted { $0.rawValue < $1.rawValue }.map(\.systemWeekday)
        return .relative(.init(time: time, repeats: .weekly(days)))
    }

    /// Schedules the snooze as a system alarm too. A snooze delivered only as a
    /// notification is silenced by exactly the same Focus that AlarmKit exists
    /// to get past — the sleeper would tap Snooze and simply never be woken.
    @discardableResult
    static func scheduleSnooze(for alarm: AlarmModel, minutes: Int) async -> Bool {
        #if canImport(AlarmKit)
        if #available(iOS 26.0, *) {
            guard await requestAuthorization() else { return false }

            let stop = AlarmButton(
                text: LocalizedStringResource(stringLiteral: String(localized: "alarm_dismiss")),
                textColor: .white,
                systemImageName: "sun.max.fill"
            )
            let alert = AlarmPresentation.Alert(
                title: LocalizedStringResource(stringLiteral: String(localized: "alarm_notification_title")),
                stopButton: stop
            )
            let attributes = AlarmAttributes<SunriseAlarmMetadata>(
                presentation: AlarmPresentation(alert: alert),
                metadata: SunriseAlarmMetadata(alarmId: alarm.id.uuidString),
                tintColor: AppColors.primary
            )
            let configuration = AlarmManager.AlarmConfiguration(
                schedule: .fixed(Date().addingTimeInterval(TimeInterval(minutes * 60))),
                attributes: attributes,
                stopIntent: StopAlarmIntent(alarmId: alarm.id.uuidString)
            )
            do {
                _ = try await AlarmManager.shared.schedule(id: snoozeId(for: alarm), configuration: configuration)
                return true
            } catch {
                return false
            }
        }
        #endif
        return false
    }

    static func cancelSnooze(_ alarm: AlarmModel) {
        #if canImport(AlarmKit)
        if #available(iOS 26.0, *) {
            try? AlarmManager.shared.cancel(id: snoozeId(for: alarm))
        }
        #endif
    }

    /// A snooze needs its own identifier: reusing the alarm's would replace the
    /// recurring schedule with a one-off nine minutes from now.
    private static func snoozeId(for alarm: AlarmModel) -> UUID {
        var bytes = alarm.id.uuid
        bytes.0 = bytes.0 ^ 0xFF
        return UUID(uuid: bytes)
    }

    static func cancel(_ alarm: AlarmModel) {
        setOwned(alarm.id.uuidString, false)
        #if canImport(AlarmKit)
        if #available(iOS 26.0, *) {
            try? AlarmManager.shared.cancel(id: alarm.id)
        }
        #endif
    }
}

#if canImport(AlarmKit)
// MARK: - Metadata
/// Carries the alarm's identity through the system alert, so the app knows which
/// alarm was stopped when it is handed control back.
@available(iOS 26.0, *)
struct SunriseAlarmMetadata: AlarmMetadata {
    let alarmId: String
}
#endif

#if canImport(AlarmKit)
// MARK: - Weekday Bridging
@available(iOS 26.0, *)
private extension Weekday {
    /// The app stores weekdays the Calendar way (1 = Sunday); AlarmKit wants
    /// Foundation's own enum.
    var systemWeekday: Locale.Weekday {
        switch self {
        case .sunday: return .sunday
        case .monday: return .monday
        case .tuesday: return .tuesday
        case .wednesday: return .wednesday
        case .thursday: return .thursday
        case .friday: return .friday
        case .saturday: return .saturday
        }
    }
}
#endif
