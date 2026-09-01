//
//  AlarmOccurrenceLedger.swift
//  soninho
//

import Foundation

// MARK: - Alarm Occurrence Ledger
/// Remembers which occurrence of each alarm was already handled — because the
/// smart alarm rings BEFORE the fixed time, and every scheduling path that
/// runs afterwards (app foregrounded, alarm list edited) would happily re-arm
/// the same occurrence and ring the sleeper a second time minutes later.
///
/// One entry per alarm: only the most recent handled occurrence matters.
enum AlarmOccurrenceLedger {

    // MARK: - Constants
    private static let key = "alarmOccurrence.handled"
    /// Two dates within this many seconds are the same occurrence.
    private static let tolerance: TimeInterval = 90

    // MARK: - Public Methods

    /// Records that this occurrence rang (early or on time).
    static func markHandled(alarmId: String, occurrence: Date, defaults: UserDefaults = .standard) {
        var handled = load(defaults: defaults)
        handled[alarmId] = occurrence.timeIntervalSince1970
        defaults.set(handled, forKey: key)
    }

    static func wasHandled(alarmId: String, occurrence: Date, defaults: UserDefaults = .standard) -> Bool {
        guard let stamp = load(defaults: defaults)[alarmId] else { return false }
        return abs(occurrence.timeIntervalSince1970 - stamp) < tolerance
    }

    /// The date scheduling should aim for: the alarm's next occurrence,
    /// skipping one that already rang early. Returns whether the skip
    /// happened, because a skipped repeating alarm must be scheduled as a
    /// fixed date (a weekly relative schedule cannot skip one week).
    static func scheduledDate(
        for alarm: AlarmModel,
        now: Date = Date(),
        defaults: UserDefaults = .standard
    ) -> (date: Date, skippedHandled: Bool)? {
        guard let next = alarm.nextOccurrence(after: now) else { return nil }
        guard wasHandled(alarmId: alarm.id.uuidString, occurrence: next, defaults: defaults) else {
            return (next, false)
        }
        guard let following = alarm.nextOccurrence(after: next.addingTimeInterval(tolerance)) else {
            return nil
        }
        return (following, true)
    }

    static func clear(alarmId: String, defaults: UserDefaults = .standard) {
        var handled = load(defaults: defaults)
        handled.removeValue(forKey: alarmId)
        defaults.set(handled, forKey: key)
    }

    // MARK: - Private Methods

    private static func load(defaults: UserDefaults) -> [String: Double] {
        defaults.dictionary(forKey: key) as? [String: Double] ?? [:]
    }
}

// MARK: - Alarm Occurrences
extension AlarmModel {

    /// The first occurrence of this alarm strictly after `reference` —
    /// `nextAlarmDate` generalized so the ledger can look past a handled one.
    func nextOccurrence(after reference: Date) -> Date? {
        let calendar = Calendar.current

        if repeatDays.isEmpty {
            let comps = calendar.dateComponents([.hour, .minute], from: time)
            return calendar.nextDate(after: reference, matching: comps, matchingPolicy: .nextTime)
        }

        for dayOffset in 0...7 {
            guard let checkDate = calendar.date(byAdding: .day, value: dayOffset, to: reference) else { continue }
            let checkWeekday = calendar.component(.weekday, from: checkDate)

            guard let weekday = Weekday(calendarWeekday: checkWeekday),
                  repeatDays.contains(weekday) else { continue }

            var components = calendar.dateComponents([.year, .month, .day], from: checkDate)
            components.hour = calendar.component(.hour, from: time)
            components.minute = calendar.component(.minute, from: time)

            if let potential = calendar.date(from: components), potential > reference {
                return potential
            }
        }
        return nil
    }
}
