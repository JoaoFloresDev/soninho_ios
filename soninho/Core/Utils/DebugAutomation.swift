//
//  DebugAutomation.swift
//  soninho
//

#if DEBUG
import Foundation

// MARK: - Debug Automation
/// Launch-argument hooks so the smart-alarm machinery can be exercised on a
/// REAL device from the command line — no waiting for a real night. DEBUG
/// builds only; the arguments live in the volatile argument domain and leave
/// no trace on a normal launch.
///
///   devicectl device process launch ... com.gambitstudio.soninho \
///     -SmartWakeTestAlarmMinutes 20        # seed one-off smart alarm in 20 min
///     -SmartWakeTestForceSmartWakeAfter 90 # fire the full early-ring path in 90 s
///     -SmartWakeTestReset 1                # remove every seeded test alarm
@MainActor
enum DebugAutomation {

    // MARK: - Constants
    private static let testLabel = "DEBUG-TEST"

    // MARK: - Public Methods

    static func runIfRequested() {
        let arguments = UserDefaults.standard

        if arguments.bool(forKey: "SmartWakeTestReset") {
            resetTestAlarms()
            return
        }

        let minutes = arguments.integer(forKey: "SmartWakeTestAlarmMinutes")
        if minutes > 0 {
            seedAlarm(minutesFromNow: minutes)
        }

        let forceAfter = arguments.integer(forKey: "SmartWakeTestForceSmartWakeAfter")
        if forceAfter > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(forceAfter)) {
                MotionSleepMonitor.shared.debugForceSmartWake()
            }
        }

        // Tracked-night session driven from the command line, through the
        // REAL ViewModel paths — start writes the tracking defaults and spins
        // the monitor; stop (typically on a relaunch, which also exercises
        // the persistence restore) saves the SleepRecord like a real morning.
        if arguments.bool(forKey: "SleepTestStartTracking") {
            SleepTrackerViewModel().startTracking()
        }
        if arguments.bool(forKey: "SleepTestStopTracking") {
            let viewModel = SleepTrackerViewModel()
            Task {
                // Give the restore path a beat to re-anchor the session.
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                await viewModel.stopTracking(greet: false)
            }
        }
    }

    // MARK: - Private Methods

    private static func seedAlarm(minutesFromNow: Int) {
        let alarm = AlarmModel(
            time: Date().addingTimeInterval(Double(minutesFromNow) * 60),
            isEnabled: true,
            isSmartAlarm: true,
            smartAlarmWindow: 30,
            repeatDays: [],
            label: testLabel
        )
        StorageService.shared.saveAlarm(alarm)
        Task { await NotificationService.shared.scheduleAlarm(alarm) }
    }

    private static func resetTestAlarms() {
        let testAlarms = StorageService.shared.loadAlarms().filter { $0.label == testLabel }
        for alarm in testAlarms {
            AlarmOccurrenceLedger.clear(alarmId: alarm.id.uuidString)
            Task { await NotificationService.shared.cancelAlarm(alarm) }
            StorageService.shared.deleteAlarm(alarm)
        }
        if MotionSleepMonitor.shared.isAlarmOnlySession {
            MotionSleepMonitor.shared.stopMonitoring()
        }
    }
}
#endif
