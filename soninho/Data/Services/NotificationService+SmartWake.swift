//
//  NotificationService+SmartWake.swift
//  soninho
//

import Foundation
import UserNotifications

// MARK: - Smart Wake Support
/// What must happen around an EARLY smart ring. Before this existed, the early
/// ring left every fixed-time path armed — AlarmKit and the weekday baseline
/// both rang again minutes later — and on a locked phone the early ring itself
/// showed nothing at all.
extension NotificationService {

    /// Removes every pending fixed-time notification of today's occurrence:
    /// the safety-net burst and today's weekday baseline. Called when the
    /// smart alarm rings early — the occurrence is handled, ringing it again
    /// at the fixed time would punish the feature for working.
    func suppressFixedOccurrence(for alarm: AlarmModel, occurrence: Date) {
        cancelBurst(alarmId: alarm.id.uuidString)

        // Weekday of the OCCURRENCE: a wake window that crosses midnight
        // rings early on the previous calendar day.
        let weekday = Calendar.current.component(.weekday, from: occurrence)
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [
            "\(alarm.id.uuidString)_day_\(weekday)"
        ])
    }

    /// Posts an immediate alarm notification — the lock-screen face of the
    /// pre-AlarmKit early ring. The in-app audio does the waking; this makes
    /// the locked phone show WHY it is making noise.
    func postSmartWakeNotification(for alarm: AlarmModel) {
        let content = UNMutableNotificationContent()
        content.title = String(localized: "alarm_notification_title")
        content.body = alarm.label ?? String(localized: "alarm_notification_body")
        content.categoryIdentifier = "ALARM_CATEGORY"
        content.interruptionLevel = .timeSensitive
        // The in-app player is the sound source on this path — a sound here
        // doubles the same 29s file a fraction of a second apart.
        content.sound = nil
        content.userInfo = [
            "alarmId": alarm.id.uuidString,
            "isSmartAlarm": true,
            "soundName": alarm.sound.rawValue,
            "volume": alarm.volume,
            "vibrationEnabled": alarm.vibrationEnabled
        ]

        let request = UNNotificationRequest(
            identifier: "\(alarm.id.uuidString)_smartwake",
            content: content,
            trigger: nil
        )
        notificationCenter.add(request)
    }
}
