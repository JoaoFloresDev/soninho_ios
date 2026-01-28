//
//  SmartAlarmViewModel.swift
//  soninho
//
//  Created by João Flores on 28/01/26.
//

import Foundation
import UserNotifications
import Combine

// MARK: - Smart Alarm ViewModel
@MainActor
final class SmartAlarmViewModel: ObservableObject {
    // MARK: - Dependencies
    private let storageService: StorageService

    // MARK: - Published Properties
    @Published var alarms: [AlarmModel] = []
    @Published var selectedAlarm: AlarmModel?
    @Published var isEditing = false
    @Published var showingAddSheet = false

    // Editing state
    @Published var editingTime = Date()
    @Published var editingIsSmartAlarm = true
    @Published var editingSmartWindow = 30
    @Published var editingSound: AlarmSound = .sunrise
    @Published var editingRepeatDays: Set<Weekday> = []
    @Published var editingLabel = ""

    // MARK: - Computed Properties
    var nextAlarmText: String {
        guard let alarm = alarms.first(where: { $0.isEnabled }),
              let nextDate = alarm.nextAlarmDate else {
            return String(localized: "alarm_no_alarm_set")
        }

        let now = Date()
        let interval = nextDate.timeIntervalSince(now)

        if interval < 3600 {
            let minutes = Int(interval / 60)
            return String(localized: "alarm_in_minutes \(minutes)")
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            let minutes = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)
            return String(localized: "alarm_in_hours_minutes \(hours) \(minutes)")
        } else {
            return String(localized: "alarm_tomorrow_at \(nextDate.timeString)")
        }
    }

    // MARK: - Init
    init(storageService: StorageService = .shared) {
        self.storageService = storageService
        loadAlarms()
    }

    // MARK: - Public Methods
    func loadAlarms() {
        alarms = storageService.loadAlarms()
        if alarms.isEmpty {
            // Add a default alarm
            let defaultAlarm = AlarmModel.sampleAlarm
            alarms = [defaultAlarm]
            storageService.saveAlarm(defaultAlarm)
        }
    }

    func toggleAlarm(_ alarm: AlarmModel) {
        HapticManager.selection()
        var updatedAlarm = alarm
        updatedAlarm.isEnabled.toggle()
        storageService.saveAlarm(updatedAlarm)

        if let index = alarms.firstIndex(where: { $0.id == alarm.id }) {
            alarms[index] = updatedAlarm
        }

        if updatedAlarm.isEnabled {
            scheduleNotification(for: updatedAlarm)
        } else {
            cancelNotification(for: updatedAlarm)
        }
    }

    func deleteAlarm(_ alarm: AlarmModel) {
        HapticManager.mediumImpact()
        storageService.deleteAlarm(alarm)
        alarms.removeAll { $0.id == alarm.id }
        cancelNotification(for: alarm)
    }

    func startEditing(_ alarm: AlarmModel) {
        selectedAlarm = alarm
        editingTime = alarm.time
        editingIsSmartAlarm = alarm.isSmartAlarm
        editingSmartWindow = alarm.smartAlarmWindow
        editingSound = alarm.sound
        editingRepeatDays = alarm.repeatDays
        editingLabel = alarm.label ?? ""
        isEditing = true
    }

    func startAddingNew() {
        selectedAlarm = nil
        editingTime = storageService.defaultWakeTime
        editingIsSmartAlarm = true
        editingSmartWindow = 30
        editingSound = .sunrise
        editingRepeatDays = []
        editingLabel = ""
        showingAddSheet = true
    }

    func saveAlarm() {
        HapticManager.success()

        let alarm = AlarmModel(
            id: selectedAlarm?.id ?? UUID(),
            time: editingTime,
            isEnabled: selectedAlarm?.isEnabled ?? true,
            isSmartAlarm: editingIsSmartAlarm,
            smartAlarmWindow: editingSmartWindow,
            sound: editingSound,
            repeatDays: editingRepeatDays,
            label: editingLabel.isEmpty ? nil : editingLabel
        )

        storageService.saveAlarm(alarm)

        if let index = alarms.firstIndex(where: { $0.id == alarm.id }) {
            alarms[index] = alarm
        } else {
            alarms.append(alarm)
        }

        if alarm.isEnabled {
            scheduleNotification(for: alarm)
        }

        isEditing = false
        showingAddSheet = false
    }

    func cancelEditing() {
        isEditing = false
        showingAddSheet = false
    }

    // MARK: - Notifications
    func requestNotificationPermission() async {
        let center = UNUserNotificationCenter.current()
        do {
            try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            print("Notification permission error: \(error)")
        }
    }

    private func scheduleNotification(for alarm: AlarmModel) {
        guard let nextDate = alarm.nextAlarmDate else { return }

        let center = UNUserNotificationCenter.current()

        // Cancel existing
        center.removePendingNotificationRequests(withIdentifiers: [alarm.id.uuidString])

        // Create content
        let content = UNMutableNotificationContent()
        content.title = String(localized: "alarm_notification_title")
        content.body = alarm.label ?? String(localized: "alarm_notification_body")
        content.sound = .default
        content.categoryIdentifier = "ALARM_CATEGORY"

        // If smart alarm, schedule earlier
        var triggerDate = nextDate
        if alarm.isSmartAlarm {
            triggerDate = nextDate.addingTimeInterval(-Double(alarm.smartAlarmWindow * 60))
        }

        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: triggerDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)

        let request = UNNotificationRequest(
            identifier: alarm.id.uuidString,
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error = error {
                print("Failed to schedule notification: \(error)")
            }
        }
    }

    private func cancelNotification(for alarm: AlarmModel) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [alarm.id.uuidString])
    }
}
