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
    /// True while the system permission sheet is up, so the control that
    /// triggered it can show a loading state instead of looking frozen.
    @Published private(set) var isRequestingNotificationPermission = false
    @Published var isEditing = false
    @Published var showingAddSheet = false
    @Published private(set) var nextAlarmDate: Date?
    /// Heartbeat for the "next alarm in…" countdown — ticks every 30s so the
    /// text keeps up with the clock.
    @Published private(set) var clock = Date()

    // MARK: - Private Properties
    private var clockTimer: Timer?

    // Editing state
    @Published var editingTime = Date()
    @Published var editingIsSmartAlarm = true
    @Published var editingSmartWindow = 30
    @Published var editingSound: AlarmSound = .sunrise
    @Published var editingRepeatDays: Set<Weekday> = []
    @Published var editingLabel = ""
    @Published var editingVolume = 1.0
    @Published var editingVibration = true
    @Published var editingSnoozeDuration = 9
    @Published var editingSnoozeLimit = AlarmModel.unlimitedSnoozes

    // Pacote Despertar editing state
    @Published var editingMission: WakeMission = .none
    @Published var editingMissionDifficulty: MissionDifficulty = .medium
    @Published var editingGradualWake = true
    @Published var editingGradualDuration = 2
    @Published var editingAntiRelapse = false

    // MARK: - Computed Properties
    /// The enabled alarm that fires next — skipping an occurrence the smart
    /// alarm already rang early (the ledger), which would otherwise display
    /// as due "now" after an early wake.
    var nextEnabledAlarm: AlarmModel? {
        alarms
            .filter { $0.isEnabled }
            .compactMap { alarm in
                AlarmOccurrenceLedger.scheduledDate(for: alarm).map { (alarm, $0.date) }
            }
            .min { $0.1 < $1.1 }?
            .0
    }

    var nextAlarmText: String {
        guard let alarm = nextEnabledAlarm,
              let nextDate = AlarmOccurrenceLedger.scheduledDate(for: alarm)?.date else {
            return String(localized: "alarm_no_alarm_set")
        }

        // `clock` (not Date()) so the countdown actually counts: a computed
        // string only re-renders when a published property changes, and
        // nothing used to change — "in 20h 15m" froze until the next edit.
        let now = clock
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
        // Scheduling is owned by the App (launch + every foreground), so the
        // ViewModel only mirrors storage here.
        loadAlarms()

        clockTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.clock = Date()
            }
        }
    }

    deinit {
        clockTimer?.invalidate()
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
        sortAlarms()
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
                await ensureNotificationPermission()
                await notificationService.scheduleAlarm(updatedAlarm)
                Analytics.coreAction("alarm_armed")
                _ = RatingGateService.shared.recordPositiveEvent()
            } else {
                await notificationService.cancelAlarm(updatedAlarm)
            }
            updateNextAlarmDate()
        }
    }

    /// Creates a disabled copy of the alarm so the user can tweak the time
    /// without rebuilding the whole configuration.
    func duplicateAlarm(_ alarm: AlarmModel) {
        let copy = AlarmModel(
            id: UUID(),
            time: alarm.time,
            isEnabled: false,
            isSmartAlarm: alarm.isSmartAlarm,
            smartAlarmWindow: alarm.smartAlarmWindow,
            sound: alarm.sound,
            volume: alarm.volume,
            vibrationEnabled: alarm.vibrationEnabled,
            repeatDays: alarm.repeatDays,
            label: alarm.label,
            mission: alarm.mission,
            missionDifficulty: alarm.missionDifficulty,
            gradualWakeEnabled: alarm.gradualWakeEnabled,
            gradualWakeDuration: alarm.gradualWakeDuration,
            antiRelapseEnabled: alarm.antiRelapseEnabled,
            snoozeDuration: alarm.snoozeDuration,
            snoozeLimit: alarm.snoozeLimit
        )
        storageService.saveAlarm(copy)
        alarms.append(copy)
        sortAlarms()
        startEditing(copy)
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
        editingVolume = alarm.volume
        editingVibration = alarm.vibrationEnabled
        editingSnoozeDuration = alarm.snoozeDuration
        editingSnoozeLimit = alarm.snoozeLimit
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
        // Default new alarms to ring every day (user can deselect days).
        editingRepeatDays = Set(Weekday.allCases)
        editingLabel = ""
        editingVolume = 1.0
        editingVibration = true
        editingSnoozeDuration = 9
        editingSnoozeLimit = AlarmModel.unlimitedSnoozes
        // Default new alarms to the shake-to-dismiss mission so the wake-up
        // challenge is on out of the box (user can change/disable it).
        editingMission = .shake
        editingMissionDifficulty = .medium
        editingGradualWake = true
        editingGradualDuration = 2
        editingAntiRelapse = false
        showingAddSheet = true
    }

    func saveAlarm() async {

        let alarm = AlarmModel(
            id: selectedAlarm?.id ?? UUID(),
            time: editingTime,
            isEnabled: selectedAlarm?.isEnabled ?? true,
            isSmartAlarm: editingIsSmartAlarm,
            smartAlarmWindow: editingSmartWindow,
            sound: editingSound,
            volume: editingVolume,
            vibrationEnabled: editingVibration,
            repeatDays: editingRepeatDays,
            label: editingLabel.isEmpty ? nil : editingLabel,
            mission: editingMission,
            missionDifficulty: editingMissionDifficulty,
            gradualWakeEnabled: editingGradualWake,
            gradualWakeDuration: editingGradualDuration,
            antiRelapseEnabled: editingAntiRelapse,
            snoozeDuration: editingSnoozeDuration,
            snoozeLimit: editingSnoozeLimit
        )

        // The alarm only rings through a local notification, so this is the
        // moment the permission starts mattering — ask for it here rather than
        // on launch, when the user has no idea what it is for.
        if alarm.isEnabled {
            await ensureNotificationPermission()
        }

        storageService.saveAlarm(alarm)

        if let index = alarms.firstIndex(where: { $0.id == alarm.id }) {
            alarms[index] = alarm
        } else {
            alarms.append(alarm)
        }
        sortAlarms()

        if alarm.isEnabled {
            await notificationService.scheduleAlarm(alarm)
            // Arming an alarm is the aha: the user has trusted the app to wake them.
            Analytics.coreAction("alarm_armed")
            _ = RatingGateService.shared.recordPositiveEvent()
        }
        updateNextAlarmDate()

        isEditing = false
        showingAddSheet = false
    }

    func cancelEditing() {
        isEditing = false
        showingAddSheet = false
    }

    // MARK: - Notifications
    /// Asks for the notification permission the first time the user does
    /// something that depends on it. Already-granted stays silent, and a denied
    /// status resolves without drawing anything, so this is safe to call on
    /// every save and every toggle.
    private func ensureNotificationPermission() async {
        guard !notificationService.isAuthorized else { return }
        isRequestingNotificationPermission = true
        let granted = await notificationService.requestAuthorization()
        Analytics.permissionResult("notifications", granted: granted)
        isRequestingNotificationPermission = false
    }

    // MARK: - Private Methods
    private func sortAlarms() {
        let calendar = Calendar.current
        alarms.sort { lhs, rhs in
            let l = calendar.dateComponents([.hour, .minute], from: lhs.time)
            let r = calendar.dateComponents([.hour, .minute], from: rhs.time)
            return (l.hour ?? 0, l.minute ?? 0) < (r.hour ?? 0, r.minute ?? 0)
        }
    }

    private func updateNextAlarmDate() {
        // Ledger-aware, like the countdown text — an occurrence the smart
        // alarm already rang must not surface as the "next" one.
        nextAlarmDate = alarms
            .filter { $0.isEnabled }
            .compactMap { AlarmOccurrenceLedger.scheduledDate(for: $0)?.date }
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
            repeatDays: Set(Weekday.allCases),
            label: String(localized: "alarm_default_label")
        )
    }
}
