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
    private let notificationService: NotificationService

    // MARK: - Published Properties
    @Published var alarms: [AlarmModel] = []
    @Published var selectedAlarm: AlarmModel?
    @Published var isEditing = false
    @Published var showingAddSheet = false
    @Published private(set) var nextAlarmDate: Date?

    // Editing state
    @Published var editingTime = Date()
    @Published var editingIsSmartAlarm = true
    @Published var editingSmartWindow = 30
    @Published var editingSound: AlarmSound = .sunrise
    @Published var editingRepeatDays: Set<Weekday> = []
    @Published var editingLabel = ""

    // Pacote Despertar editing state
    @Published var editingMission: WakeMission = .none
    @Published var editingMissionDifficulty: MissionDifficulty = .medium
    @Published var editingGradualWake = true
    @Published var editingGradualDuration = 2
    @Published var editingAntiRelapse = false

    // MARK: - Computed Properties
    var nextAlarmText: String {
        guard let alarm = alarms.first(where: { $0.isEnabled }),
              let nextDate = alarm.nextAlarmDate else {
            return String(localized: "alarm_no_alarm_set")
        }

        let now = Date()
        let interval = nextDate.timeIntervalSince(now)

        if interval <= 0 {
            return String(localized: "alarm_now")
        } else if interval < 60 {
            return String(localized: "alarm_less_than_minute")
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return String(localized: "alarm_in_minutes \(minutes)")
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            let minutes = Int((interval.truncatingRemainder(dividingBy: 3600)) / 60)
            if minutes == 0 {
                return String(localized: "alarm_in_hours \(hours)")
            }
            return String(localized: "alarm_in_hours_minutes \(hours) \(minutes)")
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEEE, HH:mm"
            return formatter.string(from: nextDate)
        }
    }

    var hasEnabledAlarm: Bool {
        alarms.contains { $0.isEnabled }
    }

    // MARK: - Init
    init(
        storageService: StorageService = .shared,
        notificationService: NotificationService = .shared
    ) {
        self.storageService = storageService
        self.notificationService = notificationService
        loadAlarms()
        scheduleAllEnabledAlarms()
    }

    // MARK: - Public Methods
    func loadAlarms() {
        alarms = storageService.loadAlarms()
        if alarms.isEmpty {
            // Add a default alarm for 7:00 AM
            let defaultAlarm = createDefaultAlarm()
            alarms = [defaultAlarm]
            storageService.saveAlarm(defaultAlarm)
        }
        updateNextAlarmDate()
    }

    func toggleAlarm(_ alarm: AlarmModel) {
        var updatedAlarm = alarm
        updatedAlarm.isEnabled.toggle()
        storageService.saveAlarm(updatedAlarm)

        if let index = alarms.firstIndex(where: { $0.id == alarm.id }) {
            alarms[index] = updatedAlarm
        }

        Task {
            if updatedAlarm.isEnabled {
                await notificationService.scheduleAlarm(updatedAlarm)
            } else {
                await notificationService.cancelAlarm(updatedAlarm)
            }
            updateNextAlarmDate()
        }
    }

    func deleteAlarm(_ alarm: AlarmModel) {
        storageService.deleteAlarm(alarm)
        alarms.removeAll { $0.id == alarm.id }

        Task {
            await notificationService.cancelAlarm(alarm)
            updateNextAlarmDate()
        }
    }

    func startEditing(_ alarm: AlarmModel) {
        selectedAlarm = alarm
        editingTime = alarm.time
        editingIsSmartAlarm = alarm.isSmartAlarm
        editingSmartWindow = alarm.smartAlarmWindow
        editingSound = alarm.sound
        editingRepeatDays = alarm.repeatDays
        editingLabel = alarm.label ?? ""
        editingMission = alarm.mission
        editingMissionDifficulty = alarm.missionDifficulty
        editingGradualWake = alarm.gradualWakeEnabled
        editingGradualDuration = alarm.gradualWakeDuration
        editingAntiRelapse = alarm.antiRelapseEnabled
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
        // Default new alarms to the shake-to-dismiss mission so the wake-up
        // challenge is on out of the box (user can change/disable it).
        editingMission = .shake
        editingMissionDifficulty = .medium
        editingGradualWake = true
        editingGradualDuration = 2
        editingAntiRelapse = false
        showingAddSheet = true
    }

    func saveAlarm() {

        let alarm = AlarmModel(
            id: selectedAlarm?.id ?? UUID(),
            time: editingTime,
            isEnabled: selectedAlarm?.isEnabled ?? true,
            isSmartAlarm: editingIsSmartAlarm,
            smartAlarmWindow: editingSmartWindow,
            sound: editingSound,
            repeatDays: editingRepeatDays,
            label: editingLabel.isEmpty ? nil : editingLabel,
            mission: editingMission,
            missionDifficulty: editingMissionDifficulty,
            gradualWakeEnabled: editingGradualWake,
            gradualWakeDuration: editingGradualDuration,
            antiRelapseEnabled: editingAntiRelapse
        )

        storageService.saveAlarm(alarm)

        if let index = alarms.firstIndex(where: { $0.id == alarm.id }) {
            alarms[index] = alarm
        } else {
            alarms.append(alarm)
        }

        Task {
            if alarm.isEnabled {
                await notificationService.scheduleAlarm(alarm)
            }
            updateNextAlarmDate()
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
        _ = await notificationService.requestAuthorization()
    }

    func scheduleAllEnabledAlarms() {
        Task {
            for alarm in alarms where alarm.isEnabled {
                await notificationService.scheduleAlarm(alarm)
            }
            updateNextAlarmDate()

            // Debug: print scheduled notifications
            await notificationService.printPendingNotifications()
        }
    }

    // MARK: - Private Methods
    private func updateNextAlarmDate() {
        nextAlarmDate = alarms
            .filter { $0.isEnabled }
            .compactMap { $0.nextAlarmDate }
            .min()
    }

    private func createDefaultAlarm() -> AlarmModel {
        var components = DateComponents()
        components.hour = 7
        components.minute = 0
        let calendar = Calendar.current
        let time = calendar.nextDate(
            after: Date(),
            matching: components,
            matchingPolicy: .nextTime
        ) ?? Date()

        return AlarmModel(
            time: time,
            isEnabled: false,
            isSmartAlarm: true,
            smartAlarmWindow: 30,
            sound: .sunrise,
            repeatDays: [],
            label: String(localized: "alarm_default_label")
        )
    }
}
