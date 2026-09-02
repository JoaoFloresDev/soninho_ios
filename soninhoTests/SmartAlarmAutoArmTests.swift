//
//  SmartAlarmAutoArmTests.swift
//  soninhoTests
//
//  The field failure of 2026-09-02: a smart alarm set for 08:30 rang at
//  exactly 08:30 because the smart window only armed inside a manually
//  started tracking session — and nobody starts one. These tests pin the
//  decision that makes the smart alarm self-sufficient.
//

import Foundation
import Testing
@testable import soninho

struct SmartAlarmAutoArmTests {

    private func makeDefaults() -> UserDefaults {
        let name = "autoarm-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name) ?? .standard
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    /// An everyday alarm whose next occurrence is `minutesFromNow` away.
    private func makeAlarm(
        minutesFromNow: Int,
        now: Date,
        smart: Bool = true,
        enabled: Bool = true,
        window: Int = 30
    ) -> AlarmModel {
        AlarmModel(
            time: now.addingTimeInterval(Double(minutesFromNow) * 60),
            isEnabled: enabled,
            isSmartAlarm: smart,
            smartAlarmWindow: window,
            repeatDays: Set(Weekday.allCases)
        )
    }

    private let now = Date(timeIntervalSince1970: 1_760_000_000)

    // MARK: - Arming Window

    @Test func armsInsideLeadWindow() {
        // Alarm in 60 min, window 30 + lead 90 = arm from 120 min out.
        let defaults = makeDefaults()
        let alarm = makeAlarm(minutesFromNow: 60, now: now)

        let result = SmartAlarmAutoArm.alarmNeedingMonitoring(
            alarms: [alarm], now: now, defaults: defaults
        )
        #expect(result != nil)
        #expect(result?.alarm.id == alarm.id)
    }

    @Test func armsRightAtTheLeadBoundary() {
        let defaults = makeDefaults()
        let alarm = makeAlarm(minutesFromNow: 119, now: now)
        #expect(SmartAlarmAutoArm.alarmNeedingMonitoring(
            alarms: [alarm], now: now, defaults: defaults
        ) != nil)
    }

    @Test func doesNotArmTooEarly() {
        // Alarm 5 hours out: monitoring now would burn the battery for hours
        // of data the wake decision does not need.
        let defaults = makeDefaults()
        let alarm = makeAlarm(minutesFromNow: 300, now: now)
        #expect(SmartAlarmAutoArm.alarmNeedingMonitoring(
            alarms: [alarm], now: now, defaults: defaults
        ) == nil)
    }

    @Test func widerWindowArmsEarlier() {
        let defaults = makeDefaults()
        let alarm = makeAlarm(minutesFromNow: 140, now: now, window: 60)
        // 60 + 90 = arm from 150 min out — 140 is inside.
        #expect(SmartAlarmAutoArm.alarmNeedingMonitoring(
            alarms: [alarm], now: now, defaults: defaults
        ) != nil)
    }

    // MARK: - Eligibility

    @Test func ignoresNonSmartAlarms() {
        let defaults = makeDefaults()
        let alarm = makeAlarm(minutesFromNow: 60, now: now, smart: false)
        #expect(SmartAlarmAutoArm.alarmNeedingMonitoring(
            alarms: [alarm], now: now, defaults: defaults
        ) == nil)
    }

    @Test func ignoresDisabledAlarms() {
        let defaults = makeDefaults()
        let alarm = makeAlarm(minutesFromNow: 60, now: now, enabled: false)
        #expect(SmartAlarmAutoArm.alarmNeedingMonitoring(
            alarms: [alarm], now: now, defaults: defaults
        ) == nil)
    }

    @Test func skipsAnOccurrenceThatAlreadyRangEarly() {
        // The smart alarm already rang for this occurrence; re-arming
        // monitoring for it would be pointless — the next occurrence is
        // tomorrow, far outside the lead.
        let defaults = makeDefaults()
        let alarm = makeAlarm(minutesFromNow: 60, now: now)
        guard let occurrence = alarm.nextOccurrence(after: now) else {
            Issue.record("no occurrence")
            return
        }
        AlarmOccurrenceLedger.markHandled(
            alarmId: alarm.id.uuidString, occurrence: occurrence, defaults: defaults
        )

        #expect(SmartAlarmAutoArm.alarmNeedingMonitoring(
            alarms: [alarm], now: now, defaults: defaults
        ) == nil)
    }

    @Test func picksTheSmartAlarmAmongMany() {
        let defaults = makeDefaults()
        let plain = makeAlarm(minutesFromNow: 45, now: now, smart: false)
        let disabled = makeAlarm(minutesFromNow: 50, now: now, enabled: false)
        let smart = makeAlarm(minutesFromNow: 90, now: now)

        let result = SmartAlarmAutoArm.alarmNeedingMonitoring(
            alarms: [plain, disabled, smart], now: now, defaults: defaults
        )
        #expect(result?.alarm.id == smart.id)
    }

    @Test func earliestOccurrenceWinsAmongSmartAlarms() {
        // Field bug: with the user's daily alarm (next occurrence tomorrow)
        // listed first and a one-off about to ring, "first enabled smart
        // alarm" armed the wrong window. Nearest occurrence must win.
        let defaults = makeDefaults()
        let dailyTomorrow = makeAlarm(minutesFromNow: 22 * 60, now: now)
        let oneOffSoon = AlarmModel(
            time: now.addingTimeInterval(60 * 60),
            isEnabled: true,
            isSmartAlarm: true,
            smartAlarmWindow: 30,
            repeatDays: []
        )

        let earliest = SmartAlarmAutoArm.earliestSmartAlarm(
            alarms: [dailyTomorrow, oneOffSoon], now: now, defaults: defaults
        )
        #expect(earliest?.alarm.id == oneOffSoon.id)

        let arming = SmartAlarmAutoArm.alarmNeedingMonitoring(
            alarms: [dailyTomorrow, oneOffSoon], now: now, defaults: defaults
        )
        #expect(arming?.alarm.id == oneOffSoon.id)
    }

    @Test func occurrenceReportedMatchesTheAlarm() {
        let defaults = makeDefaults()
        let alarm = makeAlarm(minutesFromNow: 60, now: now)
        let result = SmartAlarmAutoArm.alarmNeedingMonitoring(
            alarms: [alarm], now: now, defaults: defaults
        )
        #expect(result?.occurrence == alarm.nextOccurrence(after: now))
    }
}
