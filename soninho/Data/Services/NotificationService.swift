//
//  NotificationService.swift
//  soninho
//
//  Created by João Flores on 28/01/26.
//

import Foundation
import UserNotifications
import AVFoundation
import AudioToolbox

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
    @Published var isAlarmRinging = false
    @Published var ringingAlarmId: String?
    @Published var ringingAlarmTime: Date?
    private var ringingAlarmSoundName: String = "sunrise"
    private var ringingAlarmVolume: Float = 1.0
    private var ringingAlarmVibration: Bool = true

    // MARK: - Private Properties
    private let notificationCenter = UNUserNotificationCenter.current()
    private var audioPlayer: AVAudioPlayer?
    private var audioSession: AVAudioSession { AVAudioSession.sharedInstance() }
    private var vibrationTimer: Timer?

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
            let options: UNAuthorizationOptions = [.alert, .sound, .badge]
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

        // Cancel all existing notifications for this alarm
        await cancelAlarm(alarm)

        guard alarm.isEnabled, let nextDate = alarm.nextAlarmDate else { return }

        let calendar = Calendar.current

        // Smart alarm: a single early notification in the light-sleep window.
        if alarm.isSmartAlarm {
            let smartDate = nextDate.addingTimeInterval(-Double(alarm.smartAlarmWindow * 60))
            if smartDate > Date() {
                await scheduleNotification(
                    alarm: alarm,
                    dateComponents: calendar.dateComponents([.year, .month, .day, .hour, .minute], from: smartDate),
                    repeats: false,
                    identifier: "\(alarm.id.uuidString)_smart",
                    isSmartWake: true
                )
            }
        }

        // PERSISTENT RING: schedule a burst of notifications spaced ~30s apart
        // (each plays the 29s alarm sound), so the alarm keeps ringing for
        // several minutes at the next occurrence even if the app is suspended or
        // the user force-quit it. This is the only reliable way to ring without
        // the Critical Alerts entitlement. Budget stays under iOS's 64-pending
        // limit by sharing the slots across all enabled alarms.
        let enabledCount = max(1, StorageService.shared.loadAlarms().filter { $0.isEnabled }.count)
        let burstCount = max(6, min(18, 40 / enabledCount))
        let spacing: TimeInterval = AlarmBurst.spacing
        for i in 0..<burstCount {
            let fireDate = nextDate.addingTimeInterval(Double(i) * spacing)
            await scheduleNotification(
                alarm: alarm,
                dateComponents: calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: fireDate),
                repeats: false,
                identifier: "\(alarm.id.uuidString)\(AlarmBurst.suffix)\(i)",
                isSmartWake: false
            )
        }

        // Baseline for repeating alarms: a repeats:true notification per selected
        // weekday so it keeps firing each day even if the app is never reopened
        // (the burst above only covers the next occurrence). One per weekday.
        if !alarm.repeatDays.isEmpty {
            let timeComps = calendar.dateComponents([.hour, .minute], from: alarm.time)
            for weekday in alarm.repeatDays {
                var comps = DateComponents()
                comps.hour = timeComps.hour
                comps.minute = timeComps.minute
                comps.weekday = weekday.rawValue
                await scheduleNotification(
                    alarm: alarm,
                    dateComponents: comps,
                    repeats: true,
                    identifier: "\(alarm.id.uuidString)_day_\(weekday.rawValue)",
                    isSmartWake: false
                )
            }
        }

        await refreshPendingNotifications()
    }

    // MARK: - Alarm Burst Config
    private enum AlarmBurst {
        static let spacing: TimeInterval = 30   // seconds between notifications
        static let suffix = "_burst_"
        static let maxIds = 30                  // upper bound for cancellation
    }

    /// Cancels the remaining burst notifications for an alarm — call when the
    /// alarm is handled in-app, dismissed, or snoozed, so it doesn't keep
    /// ringing from already-scheduled notifications.
    func cancelBurst(alarmId: String) {
        let ids = (0..<AlarmBurst.maxIds).map { "\(alarmId)\(AlarmBurst.suffix)\($0)" }
        notificationCenter.removePendingNotificationRequests(withIdentifiers: ids)
    }

    // MARK: - Schedule Single Notification
    private func scheduleNotification(
        alarm: AlarmModel,
        dateComponents: DateComponents,
        repeats: Bool,
        identifier: String,
        isSmartWake: Bool
    ) async {
        let content = UNMutableNotificationContent()

        if isSmartWake {
            content.title = String(localized: "alarm_smart_wake_title")
            content.body = String(localized: "alarm_smart_wake_body")
        } else {
            content.title = String(localized: "alarm_notification_title")
            content.body = alarm.label ?? String(localized: "alarm_notification_body")
        }

        content.categoryIdentifier = Constants.alarmCategoryIdentifier
        content.interruptionLevel = .timeSensitive
        content.sound = AlarmSoundGenerator.notificationSound(for: alarm.sound)

        content.userInfo = [
            "alarmId": alarm.id.uuidString,
            "isSmartAlarm": isSmartWake,
            "soundName": alarm.sound.rawValue,
            "volume": alarm.volume,
            "vibrationEnabled": alarm.vibrationEnabled
        ]

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: repeats)

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: trigger
        )

        do {
            try await notificationCenter.add(request)
            let nextDate = trigger.nextTriggerDate()
            print("[\(identifier)] Scheduled for: \(nextDate?.description ?? "unknown") repeats=\(repeats)")
        } catch {
            print("Failed to schedule [\(identifier)]: \(error)")
        }
    }

    // MARK: - Schedule All Enabled Alarms
    func scheduleAllEnabledAlarms() async {
        let alarms = StorageService.shared.loadAlarms()
        for alarm in alarms where alarm.isEnabled {
            await scheduleAlarm(alarm)
        }
    }

    // MARK: - Schedule Snooze
    func scheduleSnooze(for alarmId: String, minutes: Int = 9, soundName: String = "sunrise", volume: Float = 1.0, vibrationEnabled: Bool = true) async {
        guard isAuthorized else { return }

        let alarmSound = AlarmSound(rawValue: soundName) ?? .sunrise
        let content = UNMutableNotificationContent()
        content.title = String(localized: "alarm_notification_title")
        content.body = String(localized: "alarm_snooze_body")
        content.categoryIdentifier = Constants.alarmCategoryIdentifier
        content.sound = AlarmSoundGenerator.notificationSound(for: alarmSound)
        content.interruptionLevel = .timeSensitive
        content.userInfo = [
            "alarmId": alarmId,
            "isSnooze": true,
            "soundName": soundName,
            "volume": Double(volume),
            "vibrationEnabled": vibrationEnabled
        ]

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

    // MARK: - In-App Alarm Audio
    /// Plays the alarm. When `gradualSeconds > 0`, the volume fades in and the
    /// vibration ramps from sparse/soft to insistent over that window
    /// (Pacote Despertar — despertar gradual).
    func startAlarmAudio(soundName: String, volume: Float = 1.0, vibration: Bool = true, gradualSeconds: TimeInterval = 0) {
        // Release the sleep-tracking microphone session first so it can't block
        // the alarm from owning the .playback session.
        MotionSleepMonitor.shared.releaseForAlarm()

        // Tear down only the audio/vibration — keep ringing identifiers so
        // snooze and re-ring keep working.
        teardownAudio()

        do {
            // .playback plays audio even when the mute switch is ON
            try audioSession.setCategory(.playback, mode: .default, options: [.duckOthers])
            try audioSession.setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }

        // Use the selected alarm sound
        let alarmSound = AlarmSound(rawValue: soundName) ?? .sunrise
        let audioURL = AlarmSoundGenerator.alarmSoundURL(for: alarmSound)

        if let url = audioURL {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: url)
                audioPlayer?.numberOfLoops = -1
                if gradualSeconds > 0 {
                    audioPlayer?.volume = max(0.04, volume * 0.06)
                    audioPlayer?.play()
                    audioPlayer?.setVolume(volume, fadeDuration: gradualSeconds)
                } else {
                    audioPlayer?.volume = volume
                    audioPlayer?.play()
                }
            } catch {
                print("Failed to play alarm audio: \(error)")
                playFallbackAlarm()
            }
        } else {
            playFallbackAlarm()
        }

        // Vibration loop
        if vibration {
            startVibrationLoop(gradualSeconds: gradualSeconds)
        }

        isAlarmRinging = true
    }

    /// Stops the audio and vibration without clearing the ringing identifiers.
    private func teardownAudio() {
        audioPlayer?.stop()
        audioPlayer = nil
        vibrationTimer?.invalidate()
        vibrationTimer = nil
        BackgroundAlarmPlayer.shared.stopAlarm()
    }

    func stopAlarmAudio() {
        teardownAudio()
        // Stop any remaining burst notifications so it doesn't keep ringing.
        if let id = ringingAlarmId { cancelBurst(alarmId: id) }
        isAlarmRinging = false
        ringingAlarmId = nil
        ringingAlarmTime = nil
        try? audioSession.setActive(false, options: .notifyOthersOnDeactivation)
    }

    // MARK: - Pacote Despertar coordination

    /// Silences the alarm but keeps the ringing screen up (used while the user
    /// works through the dismiss mission or the anti-relapse confirmation).
    func muteAlarm() {
        teardownAudio()
    }

    /// Re-rings at full intensity (no gradual ramp) — used when the
    /// anti-relapse check detects the user lay back down.
    func reRing() {
        guard let alarmId = ringingAlarmId, let uuid = UUID(uuidString: alarmId),
              let alarm = StorageService.shared.loadAlarms().first(where: { $0.id == uuid }) else {
            startAlarmAudio(soundName: ringingAlarmSoundName, volume: ringingAlarmVolume, vibration: ringingAlarmVibration)
            return
        }
        startAlarmAudio(soundName: alarm.sound.rawValue, volume: Float(alarm.volume), vibration: alarm.vibrationEnabled)
    }

    /// Fully dismisses the alarm (mission + confirmation cleared).
    func completeAlarm() {
        disableOneTimeAlarmIfNeeded()
        stopAlarmAudio()
    }

    /// A one-time alarm (no repeat days) must disappear after it's dismissed.
    /// Otherwise nextAlarmDate rolls it to tomorrow and it re-arms / can re-ring.
    /// Pass an explicit id for the notification-action path (where ringingAlarmId
    /// may be unset); otherwise it uses the currently-ringing alarm. Call BEFORE
    /// stopAlarmAudio (which clears ringingAlarmId).
    func disableOneTimeAlarmIfNeeded(id: String? = nil) {
        guard let alarmId = id ?? ringingAlarmId, let uuid = UUID(uuidString: alarmId) else { return }
        var alarms = StorageService.shared.loadAlarms()
        guard let idx = alarms.firstIndex(where: { $0.id == uuid }), alarms[idx].repeatDays.isEmpty else { return }
        alarms[idx].isEnabled = false
        let disabled = alarms[idx]
        StorageService.shared.saveAlarm(disabled)
        Task { await cancelAlarm(disabled) }
    }

    private func playFallbackAlarm() {
        // Repeatedly play system alert sound
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        AudioServicesPlaySystemSound(SystemSoundID(1304)) // Alarm sound
    }

    private func startVibrationLoop(gradualSeconds: TimeInterval = 0) {
        vibrationTimer?.invalidate()

        guard gradualSeconds > 0 else {
            vibrationTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
                AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            }
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            return
        }

        // Crescent vibration: pulses start sparse (~5s apart) and tighten to
        // ~1.2s as the ramp completes.
        let start = Date()
        var lastFire = Date(timeIntervalSince1970: 0)
        vibrationTimer = Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { _ in
            let progress = min(Date().timeIntervalSince(start) / gradualSeconds, 1.0)
            let period = 5.0 - 3.8 * progress
            if Date().timeIntervalSince(lastFire) >= period {
                lastFire = Date()
                AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            }
        }
    }

    // MARK: - Handle Foreground Alarm
    func handleForegroundAlarm(alarmId: String, soundName: String, volume: Float = 1.0, vibration: Bool = true) {
        // The app is now ringing in-app — drop the remaining fallback burst so
        // we don't get a double sound.
        cancelBurst(alarmId: alarmId)
        ringingAlarmId = alarmId
        ringingAlarmSoundName = soundName
        ringingAlarmVolume = volume
        ringingAlarmVibration = vibration

        // Store the alarm time for display + resolve gradual wake settings.
        var gradualSeconds: TimeInterval = 0
        if let uuid = UUID(uuidString: alarmId) {
            let alarms = StorageService.shared.loadAlarms()
            if let alarm = alarms.first(where: { $0.id == uuid }) {
                ringingAlarmTime = alarm.time
                if alarm.gradualWakeEnabled {
                    gradualSeconds = TimeInterval(alarm.gradualWakeDuration * 60)
                }
            }
        }

        startAlarmAudio(soundName: soundName, volume: volume, vibration: vibration, gradualSeconds: gradualSeconds)
    }

    func snoozeCurrentAlarm() {
        guard let alarmId = ringingAlarmId else { return }
        // Resolve the configured sound/volume/vibration from storage — the
        // background fire path doesn't populate the backing fields, so relying
        // on them would snooze with the wrong (default) sound at full volume.
        var soundName = ringingAlarmSoundName
        var volume = ringingAlarmVolume
        var vibration = ringingAlarmVibration
        if let uuid = UUID(uuidString: alarmId),
           let alarm = StorageService.shared.loadAlarms().first(where: { $0.id == uuid }) {
            soundName = alarm.sound.rawValue
            volume = Float(alarm.volume)
            vibration = alarm.vibrationEnabled
        }
        stopAlarmAudio()
        Task {
            await scheduleSnooze(for: alarmId, soundName: soundName, volume: volume, vibrationEnabled: vibration)
        }
    }

    func dismissCurrentAlarm() {
        disableOneTimeAlarmIfNeeded()
        stopAlarmAudio()
    }

    // MARK: - Cancel Alarm
    func cancelAlarm(_ alarm: AlarmModel) async {
        var identifiers = [
            alarm.id.uuidString,
            "\(alarm.id.uuidString)_snooze",
            "\(alarm.id.uuidString)_smart"
        ]

        // Legacy per-weekday notifications (older builds)
        for weekday in Weekday.allCases {
            identifiers.append("\(alarm.id.uuidString)_day_\(weekday.rawValue)")
            identifiers.append("\(alarm.id.uuidString)_day_\(weekday.rawValue)_smart")
        }

        // The persistent-ring burst
        for i in 0..<AlarmBurst.maxIds {
            identifiers.append("\(alarm.id.uuidString)\(AlarmBurst.suffix)\(i)")
        }

        notificationCenter.removePendingNotificationRequests(withIdentifiers: identifiers)
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
            if let trigger = request.trigger as? UNCalendarNotificationTrigger {
                return trigger.nextTriggerDate()
            } else if let trigger = request.trigger as? UNTimeIntervalNotificationTrigger {
                return trigger.nextTriggerDate()
            }
            return nil
        }

        return dates.min()
    }

    // MARK: - Debug
    func printPendingNotifications() async {
        await refreshPendingNotifications()
        print("=== Pending Notifications (\(pendingNotifications.count)) ===")
        for request in pendingNotifications {
            if let trigger = request.trigger as? UNCalendarNotificationTrigger {
                print("ID: \(request.identifier)")
                print("Next trigger: \(trigger.nextTriggerDate()?.description ?? "nil")")
                print("Repeats: \(trigger.repeats)")
                print("Content: \(request.content.title) - \(request.content.body)")
                print("---")
            } else if let trigger = request.trigger as? UNTimeIntervalNotificationTrigger {
                print("ID: \(request.identifier) (interval: \(trigger.timeInterval)s)")
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
            identifier: bedtimeReminderIdentifier,
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
                await NotificationService.shared.scheduleSnooze(for: alarmId, soundName: soundName, volume: Float(volume), vibrationEnabled: vibration)
            case "DISMISS_ACTION", UNNotificationDismissActionIdentifier:
                NotificationService.shared.cancelBurst(alarmId: alarmId)
                NotificationService.shared.disableOneTimeAlarmIfNeeded(id: alarmId)
                NotificationService.shared.stopAlarmAudio()
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
