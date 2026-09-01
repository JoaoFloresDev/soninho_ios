//
//  NotificationService+Bedtime.swift
//  soninho
//
//  The bedtime reminder shares nothing with the alarm's ringing state, so it
//  lives on its own rather than adding to a file that is already too large to
//  reason about.
//

import Foundation
import UserNotifications

extension NotificationService {
    // MARK: - Constants
    private static let bedtimeReminderIdentifier = "BEDTIME_REMINDER"

    func scheduleBedtimeReminder(bedtime: Date, minutesBefore: Int) async {
        if !isAuthorized {
            let granted = await requestAuthorization()
            if !granted { return }
        }

        await cancelBedtimeReminder()

        let reminderTime = bedtime.addingTimeInterval(-Double(minutesBefore * 60))

        let content = UNMutableNotificationContent()
        content.title = String(localized: "bedtime_reminder_title")
        content.body = String(localized: "bedtime_reminder_body \(minutesBefore)")
        content.sound = .default
        content.interruptionLevel = .timeSensitive

        let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(
            identifier: Self.bedtimeReminderIdentifier,
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
            print("Bedtime reminder scheduled for \(components.hour ?? 0):\(components.minute ?? 0)")
        } catch {
            print("Failed to schedule bedtime reminder: \(error)")
        }
    }

    /// Schedules a daily bedtime reminder at the exact time the user picked.
    func scheduleBedtimeReminder(at time: Date) async {
        if !isAuthorized {
            let granted = await requestAuthorization()
            if !granted { return }
        }

        await cancelBedtimeReminder()

        let content = UNMutableNotificationContent()
        content.title = String(localized: "bedtime_reminder_title")
        content.body = String(localized: "bedtime_reminder_message")
        content.sound = .default
        content.interruptionLevel = .timeSensitive
        content.categoryIdentifier = "BEDTIME_CATEGORY"

        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: Self.bedtimeReminderIdentifier, content: content, trigger: trigger)
        try? await notificationCenter.add(request)
    }

    func cancelBedtimeReminder() async {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [Self.bedtimeReminderIdentifier])
    }

    /// Immediate confirmation that the sleep night auto-started.
    func notifySleepAutoStarted() {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "bedtime_reminder_title")
        content.body = String(localized: "bedtime_autostart_message")
        content.sound = .default
        content.interruptionLevel = .timeSensitive
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: "SLEEP_AUTOSTARTED", content: content, trigger: trigger)
        Task { try? await notificationCenter.add(request) }
    }
}
