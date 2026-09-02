//
//  NotificationService+Delegate.swift
//  soninho
//

import Foundation
import UserNotifications

// MARK: - Notification Delegate
class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let userInfo = notification.request.content.userInfo
        let categoryId = notification.request.content.categoryIdentifier

        // If it's an alarm and app is in foreground, play audio directly
        if categoryId == "ALARM_CATEGORY" {
            let alarmId = userInfo["alarmId"] as? String ?? ""
            let soundName = userInfo["soundName"] as? String ?? "sunrise"
            let volume = userInfo["volume"] as? Double ?? 1.0
            let vibration = userInfo["vibrationEnabled"] as? Bool ?? true

            Task { @MainActor in
                NotificationService.shared.handleForegroundAlarm(
                    alarmId: alarmId,
                    soundName: soundName,
                    volume: Float(volume),
                    vibration: vibration
                )
            }

            // Show banner but we handle sound ourselves
            completionHandler([.banner, .badge])
        } else {
            completionHandler([.banner, .sound, .badge])
        }
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let categoryId = response.notification.request.content.categoryIdentifier

        // Bedtime reminder: the action button OR tapping it starts the sleep night.
        if categoryId == "BEDTIME_CATEGORY" {
            if response.actionIdentifier == "START_SLEEP_ACTION"
                || response.actionIdentifier == UNNotificationDefaultActionIdentifier {
                // Delay so the UI is subscribed by the time we post (cold launch).
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    NotificationCenter.default.post(name: .didRequestSwitchToSleepTab, object: nil)
                    NotificationCenter.default.post(name: .didRequestStartSleepTracking, object: nil)
                }
            }
            completionHandler()
            return
        }

        let userInfo = response.notification.request.content.userInfo
        let alarmId = userInfo["alarmId"] as? String ?? ""
        let soundName = userInfo["soundName"] as? String ?? "sunrise"
        let volume = userInfo["volume"] as? Double ?? 1.0
        let vibration = userInfo["vibrationEnabled"] as? Bool ?? true

        Task { @MainActor in
            switch response.actionIdentifier {
            case "SNOOZE_ACTION":
                NotificationService.shared.cancelBurst(alarmId: alarmId)
                NotificationService.shared.stopAlarmAudio()
                let minutes = UUID(uuidString: alarmId)
                    .flatMap { uuid in StorageService.shared.loadAlarms().first { $0.id == uuid } }?
                    .snoozeDuration ?? 9
                await NotificationService.shared.scheduleSnooze(for: alarmId, minutes: minutes, soundName: soundName, volume: Float(volume), vibrationEnabled: vibration)
            case "DISMISS_ACTION", UNNotificationDismissActionIdentifier:
                NotificationService.shared.cancelBurst(alarmId: alarmId)
                NotificationService.shared.disableOneTimeAlarmIfNeeded(id: alarmId)
                NotificationService.shared.resetSnoozes(for: alarmId)
                NotificationService.shared.stopAlarmAudio()
                // Dismissing from the lock screen ends the night too — without
                // this the tracked session lingered until the 12h stale guard
                // DISCARDED it: a full night tracked, nothing saved.
                NotificationCenter.default.post(name: .didCompleteAlarm, object: nil)
            case UNNotificationDefaultActionIdentifier:
                // User tapped notification — show alarm screen
                NotificationService.shared.handleForegroundAlarm(
                    alarmId: alarmId,
                    soundName: soundName,
                    volume: Float(volume),
                    vibration: vibration
                )
            default:
                NotificationService.shared.stopAlarmAudio()
            }
        }

        completionHandler()
    }
}
