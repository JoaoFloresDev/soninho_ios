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

    // MARK: - Computed Properties

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

    /// Schedules `alarm` to ring at `date`. Returns whether AlarmKit took it —
    /// a false means the caller must keep the notification burst armed.
    @discardableResult
    static func schedule(_ alarm: AlarmModel, at date: Date) async -> Bool {
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
                schedule: schedule(for: alarm, at: date),
                attributes: attributes,
                stopIntent: StopAlarmIntent(alarmId: alarm.id.uuidString)
            )

            do {
                _ = try await AlarmManager.shared.schedule(id: alarm.id, configuration: configuration)
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

    static func cancel(_ alarm: AlarmModel) {
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
