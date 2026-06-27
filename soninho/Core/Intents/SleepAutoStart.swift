//
//  SleepAutoStart.swift
//  soninho
//
//  Auto-starts a sleep night at the user's bedtime — but ONLY when the app is
//  already alive (foreground, or background via the alarm keep-alive). iOS can't
//  wake a suspended app to do this, so it's best-effort: the common case is a
//  morning alarm keeping the app alive overnight on the nightstand.
//

import Foundation
import UIKit

// MARK: - Sleep Auto Start
@MainActor
enum SleepAutoStart {
    private static var foregroundTimer: Timer?

    /// Window after bedtime in which we still auto-start (covers timer jitter).
    private static let window: TimeInterval = 120

    /// Runs a light foreground check loop. The background case is driven by the
    /// alarm keep-alive timer calling `checkAndStartIfDue()`.
    static func startForegroundMonitor() {
        foregroundTimer?.invalidate()
        foregroundTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { _ in
            Task { @MainActor in checkAndStartIfDue() }
        }
        checkAndStartIfDue()
    }

    /// Starts a sleep night if auto-start is on, it's bedtime, and we're not
    /// already tracking. Safe to call frequently.
    static func checkAndStartIfDue() {
        let store = StorageService.shared
        guard store.autoStartSleepEnabled else { return }
        guard !UserDefaults.standard.bool(forKey: StorageKeys.isCurrentlyTracking) else { return }

        let now = Date()
        let calendar = Calendar.current
        let hm = calendar.dateComponents([.hour, .minute], from: store.bedtimeReminderTime)
        var comps = calendar.dateComponents([.year, .month, .day], from: now)
        comps.hour = hm.hour
        comps.minute = hm.minute
        comps.second = 0
        guard let todayAt = calendar.date(from: comps) else { return }
        let recent = now >= todayAt ? todayAt : (calendar.date(byAdding: .day, value: -1, to: todayAt) ?? todayAt)

        // Only within the window right after bedtime.
        let since = now.timeIntervalSince(recent)
        guard since >= 0, since <= window else { return }

        // Don't fire twice for the same bedtime occurrence.
        let lastKey = StorageKeys.lastAutoStartSleep
        if let last = UserDefaults.standard.object(forKey: lastKey) as? Date,
           abs(last.timeIntervalSince(recent)) < 60 {
            return
        }
        UserDefaults.standard.set(recent, forKey: lastKey)

        start()
    }

    // MARK: - Private
    private static func start() {
        if UIApplication.shared.applicationState == .active {
            // A live ViewModel will start tracking and update the UI.
            NotificationCenter.default.post(name: .didRequestSwitchToSleepTab, object: nil)
            NotificationCenter.default.post(name: .didRequestStartSleepTracking, object: nil)
        } else {
            // No UI alive — start the session directly; the ViewModel restores it
            // from these defaults the next time the app is opened.
            UserDefaults.standard.set(true, forKey: StorageKeys.isCurrentlyTracking)
            UserDefaults.standard.set(Date(), forKey: StorageKeys.trackingStartTime)
            MotionSleepMonitor.shared.startMonitoring()
        }
    }
}
