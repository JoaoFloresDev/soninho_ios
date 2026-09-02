//
//  AlarmOccurrenceLedgerTests.swift
//  soninhoTests
//
//  The ledger is what stops the fixed-time alarm from ringing AGAIN minutes
//  after the smart alarm already woke the sleeper: every scheduling path that
//  re-runs after the early ring (app foregrounded, alarms edited) consults it.
//

import Foundation
import Testing
@testable import soninho

struct AlarmOccurrenceLedgerTests {

    private func makeDefaults() -> UserDefaults {
        let name = "ledger-tests-\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: name) ?? .standard
        defaults.removePersistentDomain(forName: name)
        return defaults
    }

    private func makeAlarm(hour: Int, minute: Int, repeatDays: Set<Weekday> = Set(Weekday.allCases)) -> AlarmModel {
        var components = DateComponents()
        components.year = 2026; components.month = 9; components.day = 1
        components.hour = hour; components.minute = minute
        let time = Calendar.current.date(from: components) ?? Date()
        return AlarmModel(time: time, repeatDays: repeatDays)
    }

    // MARK: - Handled Bookkeeping

    @Test func unmarkedOccurrenceIsNotHandled() {
        let defaults = makeDefaults()
        let occurrence = Date(timeIntervalSince1970: 1_760_000_000)
        #expect(AlarmOccurrenceLedger.wasHandled(alarmId: "a", occurrence: occurrence, defaults: defaults) == false)
    }

    @Test func markedOccurrenceIsHandledWithinTolerance() {
        let defaults = makeDefaults()
        let occurrence = Date(timeIntervalSince1970: 1_760_000_000)
        AlarmOccurrenceLedger.markHandled(alarmId: "a", occurrence: occurrence, defaults: defaults)

        #expect(AlarmOccurrenceLedger.wasHandled(alarmId: "a", occurrence: occurrence, defaults: defaults))
        // The early ring happens BEFORE the fixed time; the scheduling paths
        // ask about the fixed time itself — a minute of drift must still match.
        #expect(AlarmOccurrenceLedger.wasHandled(
            alarmId: "a",
            occurrence: occurrence.addingTimeInterval(60),
            defaults: defaults
        ))
    }

    @Test func differentOccurrenceIsNotHandled() {
        let defaults = makeDefaults()
        let occurrence = Date(timeIntervalSince1970: 1_760_000_000)
        AlarmOccurrenceLedger.markHandled(alarmId: "a", occurrence: occurrence, defaults: defaults)

        // Tomorrow's occurrence must be free to ring.
        #expect(AlarmOccurrenceLedger.wasHandled(
            alarmId: "a",
            occurrence: occurrence.addingTimeInterval(24 * 3600),
            defaults: defaults
        ) == false)
    }

    @Test func differentAlarmIsNotHandled() {
        let defaults = makeDefaults()
        let occurrence = Date(timeIntervalSince1970: 1_760_000_000)
        AlarmOccurrenceLedger.markHandled(alarmId: "a", occurrence: occurrence, defaults: defaults)
        #expect(AlarmOccurrenceLedger.wasHandled(alarmId: "b", occurrence: occurrence, defaults: defaults) == false)
    }

    // MARK: - Scheduling Around a Handled Occurrence

    @Test func scheduledDateSkipsTheOccurrenceThatAlreadyRang() {
        let defaults = makeDefaults()
        let alarm = makeAlarm(hour: 7, minute: 0)

        // The smart alarm rang early for "tomorrow 07:00".
        guard let occurrence = alarm.nextOccurrence(after: Date()) else {
            Issue.record("alarm has no next occurrence")
            return
        }
        AlarmOccurrenceLedger.markHandled(alarmId: alarm.id.uuidString, occurrence: occurrence, defaults: defaults)

        let scheduled = AlarmOccurrenceLedger.scheduledDate(for: alarm, defaults: defaults)
        #expect(scheduled != nil)
        guard let scheduled else { return }

        // Re-scheduling must aim at the FOLLOWING day, flagged as a skip (a
        // weekly relative schedule cannot skip a single occurrence).
        #expect(scheduled.skippedHandled)
        #expect(abs(scheduled.date.timeIntervalSince(occurrence) - 24 * 3600) < 120)
        // The handled occurrence itself must come back too: the weekday
        // baseline guard keys on IT, not on "today" (an early ring near
        // midnight lands on the previous calendar day, and deriving the day
        // from Date() re-armed the very occurrence that already rang).
        #expect(scheduled.handledOccurrence == occurrence)
    }

    @Test func unhandledScheduleCarriesNoHandledOccurrence() {
        let defaults = makeDefaults()
        let alarm = makeAlarm(hour: 7, minute: 0)
        let scheduled = AlarmOccurrenceLedger.scheduledDate(for: alarm, defaults: defaults)
        #expect(scheduled?.handledOccurrence == nil)
    }

    @Test func scheduledDateIsUntouchedWhenNothingRang() {
        let defaults = makeDefaults()
        let alarm = makeAlarm(hour: 7, minute: 0)

        let scheduled = AlarmOccurrenceLedger.scheduledDate(for: alarm, defaults: defaults)
        #expect(scheduled?.skippedHandled == false)
        #expect(scheduled?.date == alarm.nextOccurrence(after: Date()))
    }

    // MARK: - Next Occurrence

    @Test func nextOccurrenceMovesPastAReference() {
        let alarm = makeAlarm(hour: 7, minute: 0)
        guard let first = alarm.nextOccurrence(after: Date()) else {
            Issue.record("no occurrence")
            return
        }
        let second = alarm.nextOccurrence(after: first.addingTimeInterval(90))

        #expect(second != nil)
        if let second {
            #expect(abs(second.timeIntervalSince(first) - 24 * 3600) < 120)
        }
    }

    @Test func nextOccurrenceMatchesNextAlarmDate() {
        // The generalized helper must agree with the legacy computed property.
        let alarm = makeAlarm(hour: 6, minute: 30)
        #expect(alarm.nextOccurrence(after: Date()) == alarm.nextAlarmDate)

        let oneTime = makeAlarm(hour: 22, minute: 15, repeatDays: [])
        #expect(oneTime.nextOccurrence(after: Date()) == oneTime.nextAlarmDate)
    }

    @Test func weeklyAlarmSkipsToNextSelectedDay() {
        let calendar = Calendar.current
        let todayWeekday = calendar.component(.weekday, from: Date())
        guard let today = Weekday(calendarWeekday: todayWeekday) else {
            Issue.record("weekday bridge failed")
            return
        }

        // An alarm ONLY on today's weekday: after today's occurrence is
        // skipped, the next one is a full week out.
        let alarm = makeAlarm(hour: 23, minute: 59, repeatDays: [today])
        guard let first = alarm.nextOccurrence(after: Date()) else {
            Issue.record("no occurrence")
            return
        }
        let second = alarm.nextOccurrence(after: first.addingTimeInterval(120))
        #expect(second != nil)
        if let second {
            #expect(abs(second.timeIntervalSince(first) - 7 * 24 * 3600) < 3600)
        }
    }

    @Test func clearForgetsTheAlarm() {
        let defaults = makeDefaults()
        let occurrence = Date(timeIntervalSince1970: 1_760_000_000)
        AlarmOccurrenceLedger.markHandled(alarmId: "a", occurrence: occurrence, defaults: defaults)
        AlarmOccurrenceLedger.clear(alarmId: "a", defaults: defaults)
        #expect(AlarmOccurrenceLedger.wasHandled(alarmId: "a", occurrence: occurrence, defaults: defaults) == false)
    }
}

// MARK: - Sleep Quality Scorer Tests
struct SleepQualityScorerTests {

    private func spans(_ blocks: [(SleepPhase, minutes: Double)]) -> [SleepPhaseData] {
        var cursor = SyntheticNight.sessionStart
        return blocks.map { phase, minutes in
            let end = cursor.addingTimeInterval(minutes * 60)
            defer { cursor = end }
            return SleepPhaseData(phase: phase, startTime: cursor, endTime: end)
        }
    }

    @Test func healthyNightScoresWell() {
        // 8h: 20% deep, 20% REM, 57% light, 3% awake.
        let night = spans([
            (.light, 96), (.deep, 48), (.light, 90), (.rem, 48),
            (.deep, 48), (.light, 88), (.rem, 48), (.awake, 14),
        ])
        let score = SleepQualityScorer.score(phases: night, totalDuration: 8 * 3600)
        #expect(score >= 85)
    }

    @Test func flatLightNightScoresPoorly() {
        // The bug night: one flat light block. Must NOT look like quality sleep.
        let night = spans([(.light, 480)])
        let score = SleepQualityScorer.score(phases: night, totalDuration: 8 * 3600)
        #expect(score < 60)
    }

    @Test func veryShortNightScoresLow() {
        let night = spans([(.light, 60), (.deep, 30), (.light, 30)])
        let score = SleepQualityScorer.score(phases: night, totalDuration: 2 * 3600)
        #expect(score < 65)
    }

    @Test func zeroDurationIsNeutral() {
        #expect(SleepQualityScorer.score(phases: [], totalDuration: 0) == 50)
    }
}
