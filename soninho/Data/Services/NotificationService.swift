//
//  NotificationService.swift
//  soninho
//
//  Created by João Flores on 28/01/26.
//

import Foundation
import UserNotifications
import AVFoundation

// MARK: - Notification Service
@MainActor
final class NotificationService: ObservableObject {
    // MARK: - Singleton
    static let shared = NotificationService()

    // MARK: - Constants
    private enum Constants {
        static let alarmCategoryIdentifier = "ALARM_CATEGORY"
        static let snoozeActionIdentifier = "SNOOZE_ACTION"
        static let dismissActionIdentifier = "DISMISS_ACTION"
    }

    // MARK: - Published Properties
    @Published private(set) var isAuthorized = false
    @Published private(set) var pendingNotifications: [UNNotificationRequest] = []

    // MARK: - Private Properties
    private let notificationCenter = UNUserNotificationCenter.current()

    // MARK: - Init
    private init() {
        Task {
            await checkAuthorizationStatus()
            await registerNotificationCategories()
        }
    }

    // MARK: - Authorization
    func requestAuthorization() async -> Bool {
        do {
            let options: UNAuthorizationOptions = [.alert, .sound, .badge, .criticalAlert]
            let granted = try await notificationCenter.requestAuthorization(options: options)
            isAuthorized = granted
            return granted
        } catch {
            print("Notification authorization error: \(error)")
            isAuthorized = false
            return false
        }
    }

    func checkAuthorizationStatus() async {
        let settings = await notificationCenter.notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
    }

    // MARK: - Category Registration
    private func registerNotificationCategories() async {
        let snoozeAction = UNNotificationAction(
            identifier: Constants.snoozeActionIdentifier,
            title: String(localized: "alarm_snooze"),
            options: []
        )

        let dismissAction = UNNotificationAction(
            identifier: Constants.dismissActionIdentifier,
            title: String(localized: "alarm_dismiss"),
            options: [.destructive]
        )

        let alarmCategory = UNNotificationCategory(
            identifier: Constants.alarmCategoryIdentifier,
            actions: [snoozeAction, dismissAction],
            intentIdentifiers: [],
            options: [.customDismissAction]
        )

        notificationCenter.setNotificationCategories([alarmCategory])
    }

    // MARK: - Schedule Alarm
    func scheduleAlarm(_ alarm: AlarmModel) async {
        if !isAuthorized {
            let granted = await requestAuthorization()
            if !granted {
                print("Notification not authorized")
                return
            }
        }

        // Cancel existing notification for this alarm
        await cancelAlarm(alarm)

        guard alarm.isEnabled, let nextDate = alarm.nextAlarmDate else {
            return
        }

        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = String(localized: "alarm_notification_title")
        content.body = alarm.label ?? String(localized: "alarm_notification_body")
        content.categoryIdentifier = Constants.alarmCategoryIdentifier
        content.interruptionLevel = .timeSensitive

        // Use default alarm sound (system will handle it)
        content.sound = .defaultCritical

        // Add alarm info to userInfo for handling
        content.userInfo = [
            "alarmId": alarm.id.uuidString,
            "isSmartAlarm": alarm.isSmartAlarm,
            "smartAlarmWindow": alarm.smartAlarmWindow
        ]

        // Calculate trigger date
        var triggerDate = nextDate
        if alarm.isSmartAlarm {
            // For smart alarms, trigger at the optimal time within the window
            // For now, we'll trigger at the start of the window
            triggerDate = nextDate.addingTimeInterval(-Double(alarm.smartAlarmWindow * 60))
        }

        // Create trigger
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: triggerDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        // Create request
        let request = UNNotificationRequest(
            identifier: alarm.id.uuidString,
            content: content,
            trigger: trigger
        )

        // Schedule
        do {
            try await notificationCenter.add(request)
            print("Alarm scheduled for: \(triggerDate)")
            await refreshPendingNotifications()
        } catch {
            print("Failed to schedule alarm: \(error)")
        }
    }

    // MARK: - Schedule Snooze
    func scheduleSnooze(for alarmId: String, minutes: Int = 9) async {
        guard isAuthorized else { return }

        let content = UNMutableNotificationContent()
        content.title = String(localized: "alarm_notification_title")
        content.body = String(localized: "alarm_snooze_body")
        content.categoryIdentifier = Constants.alarmCategoryIdentifier
        content.sound = .defaultCritical
        content.interruptionLevel = .timeSensitive
        content.userInfo = ["alarmId": alarmId, "isSnooze": true]

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(minutes * 60),
            repeats: false
        )

        let request = UNNotificationRequest(
            identifier: "\(alarmId)_snooze",
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
            print("Snooze scheduled for \(minutes) minutes")
        } catch {
            print("Failed to schedule snooze: \(error)")
        }
    }

    // MARK: - Cancel Alarm
    func cancelAlarm(_ alarm: AlarmModel) async {
        notificationCenter.removePendingNotificationRequests(
            withIdentifiers: [alarm.id.uuidString, "\(alarm.id.uuidString)_snooze"]
        )
        await refreshPendingNotifications()
    }

    func cancelAllAlarms() async {
        notificationCenter.removeAllPendingNotificationRequests()
        await refreshPendingNotifications()
    }

    // MARK: - Pending Notifications
    func refreshPendingNotifications() async {
        pendingNotifications = await notificationCenter.pendingNotificationRequests()
    }

    func getNextScheduledAlarm() async -> Date? {
        await refreshPendingNotifications()

        let alarmNotifications = pendingNotifications.filter {
            $0.content.categoryIdentifier == Constants.alarmCategoryIdentifier
        }

        let dates = alarmNotifications.compactMap { request -> Date? in
            guard let trigger = request.trigger as? UNCalendarNotificationTrigger else {
                return nil
            }
            return trigger.nextTriggerDate()
        }

        return dates.min()
    }

    // MARK: - Debug
    func printPendingNotifications() async {
        await refreshPendingNotifications()
        print("=== Pending Notifications ===")
        for request in pendingNotifications {
            if let trigger = request.trigger as? UNCalendarNotificationTrigger {
                print("ID: \(request.identifier)")
                print("Next trigger: \(trigger.nextTriggerDate() ?? Date())")
                print("Content: \(request.content.title)")
                print("---")
            }
        }
    }

    // MARK: - Bedtime Reminder
    private let bedtimeReminderIdentifier = "BEDTIME_REMINDER"

    func scheduleBedtimeReminder(bedtime: Date, minutesBefore: Int) async {
        if !isAuthorized {
            let granted = await requestAuthorization()
            if !granted { return }
        }

        // Cancel existing bedtime reminder
        await cancelBedtimeReminder()

        // Calculate reminder time
        let reminderTime = bedtime.addingTimeInterval(-Double(minutesBefore * 60))

        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = String(localized: "bedtime_reminder_title")
        content.body = String(localized: "bedtime_reminder_body \(minutesBefore)")
        content.sound = .default
        content.interruptionLevel = .timeSensitive

        // Create daily trigger
        let components = Calendar.current.dateComponents([.hour, .minute], from: reminderTime)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        // Create request
        let request = UNNotificationRequest(
            identifier: bedtimeReminderIdentifier,
            content: content,
            trigger: trigger
        )

        // Schedule
        do {
            try await notificationCenter.add(request)
            print("Bedtime reminder scheduled for \(components.hour ?? 0):\(components.minute ?? 0)")
        } catch {
            print("Failed to schedule bedtime reminder: \(error)")
        }
    }

    func cancelBedtimeReminder() async {
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [bedtimeReminderIdentifier])
    }
}

// MARK: - Notification Delegate
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        let alarmId = userInfo["alarmId"] as? String ?? ""

        switch response.actionIdentifier {
        case "SNOOZE_ACTION":
            Task { @MainActor in
                await NotificationService.shared.scheduleSnooze(for: alarmId)
            }
        case "DISMISS_ACTION", UNNotificationDismissActionIdentifier:
            // Alarm dismissed - reschedule if repeating
            Task { @MainActor in
                await rescheduleRepeatingAlarm(alarmId: alarmId)
            }
        case UNNotificationDefaultActionIdentifier:
            // User tapped notification - open app
            break
        default:
            break
        }

        completionHandler()
    }

    @MainActor
    private func rescheduleRepeatingAlarm(alarmId: String) async {
        guard let uuid = UUID(uuidString: alarmId) else { return }

        let alarms = StorageService.shared.loadAlarms()
        if let alarm = alarms.first(where: { $0.id == uuid }),
           !alarm.repeatDays.isEmpty,
           alarm.isEnabled {
            await NotificationService.shared.scheduleAlarm(alarm)
        }
    }
}
