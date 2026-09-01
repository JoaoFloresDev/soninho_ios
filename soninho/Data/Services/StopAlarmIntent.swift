//
//  StopAlarmIntent.swift
//  soninho
//

import AppIntents
import Foundation

// MARK: - Stop Alarm Intent
/// Runs when the sleeper taps Stop on the system alarm.
///
/// AlarmKit's alert can only offer Stop and Snooze, so stopping there would let
/// someone dismiss the alarm without ever facing the mission — which is the one
/// thing this app promises. The intent therefore opens the app instead of
/// ending the wake-up, and the app resumes ringing into the mission. The sound
/// that AlarmKit guaranteed is what got the sleeper here; the mission is what
/// keeps them up.
@available(iOS 26.0, *)
struct StopAlarmIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Stop alarm"
    static var openAppWhenRun: Bool { true }

    @Parameter(title: "Alarm")
    var alarmId: String

    init() {}

    init(alarmId: String) {
        self.alarmId = alarmId
    }

    func perform() async throws -> some IntentResult {
        await MainActor.run {
            NotificationCenter.default.post(
                name: .systemAlarmStopped,
                object: nil,
                userInfo: ["alarmId": alarmId]
            )
        }
        return .result()
    }
}

// MARK: - Notification Names
extension Notification.Name {
    /// Posted when the system alarm alert was dismissed and the app should take
    /// over the wake-up flow.
    static let systemAlarmStopped = Notification.Name("systemAlarmStopped")
}
