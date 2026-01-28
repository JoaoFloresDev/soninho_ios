//
//  AlarmModel.swift
//  soninho
//
//  Created by João Flores on 28/01/26.
//

import Foundation
import SwiftUI

// MARK: - Alarm Sound
enum AlarmSound: String, Codable, CaseIterable, Identifiable {
    case sunrise = "sunrise"
    case birds = "birds"
    case ocean = "ocean"
    case gentle = "gentle"
    case piano = "piano"
    case forest = "forest"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .sunrise: return "Sunrise"
        case .birds: return "Birds"
        case .ocean: return "Ocean Waves"
        case .gentle: return "Gentle"
        case .piano: return "Piano"
        case .forest: return "Forest"
        }
    }

    var fileName: String {
        "\(rawValue)_alarm"
    }

    var icon: String {
        switch self {
        case .sunrise: return "sunrise.fill"
        case .birds: return "bird.fill"
        case .ocean: return "water.waves"
        case .gentle: return "waveform"
        case .piano: return "pianokeys"
        case .forest: return "leaf.fill"
        }
    }
}

// MARK: - Alarm Model
struct AlarmModel: Codable, Identifiable {
    let id: UUID
    var time: Date
    var isEnabled: Bool
    var isSmartAlarm: Bool
    var smartAlarmWindow: Int // minutes before alarm to start monitoring
    var sound: AlarmSound
    var volume: Double
    var vibrationEnabled: Bool
    var repeatDays: Set<Weekday>
    var label: String?

    // MARK: - Computed Properties
    var timeString: String {
        time.timeString
    }

    var repeatDaysString: String {
        if repeatDays.isEmpty {
            return String(localized: "alarm_once")
        }
        if repeatDays.count == 7 {
            return String(localized: "alarm_everyday")
        }
        if repeatDays == [.monday, .tuesday, .wednesday, .thursday, .friday] {
            return String(localized: "alarm_weekdays")
        }
        if repeatDays == [.saturday, .sunday] {
            return String(localized: "alarm_weekends")
        }
        return repeatDays.sorted { $0.rawValue < $1.rawValue }
            .map { $0.shortName }
            .joined(separator: ", ")
    }

    var nextAlarmDate: Date? {
        let calendar = Calendar.current
        let now = Date()

        if repeatDays.isEmpty {
            // One-time alarm
            if time > now {
                return time
            }
            return calendar.date(byAdding: .day, value: 1, to: time)
        }

        // Repeating alarm
        var nextDate: Date?
        let currentWeekday = calendar.component(.weekday, from: now)

        for dayOffset in 0..<7 {
            let checkDate = calendar.date(byAdding: .day, value: dayOffset, to: now)!
            let checkWeekday = calendar.component(.weekday, from: checkDate)

            if let weekday = Weekday(calendarWeekday: checkWeekday), repeatDays.contains(weekday) {
                var components = calendar.dateComponents([.year, .month, .day], from: checkDate)
                components.hour = calendar.component(.hour, from: time)
                components.minute = calendar.component(.minute, from: time)

                if let potentialDate = calendar.date(from: components), potentialDate > now {
                    nextDate = potentialDate
                    break
                }
            }
        }

        return nextDate
    }

    // MARK: - Init
    init(
        id: UUID = UUID(),
        time: Date = Date(),
        isEnabled: Bool = true,
        isSmartAlarm: Bool = true,
        smartAlarmWindow: Int = 30,
        sound: AlarmSound = .sunrise,
        volume: Double = 0.7,
        vibrationEnabled: Bool = true,
        repeatDays: Set<Weekday> = [],
        label: String? = nil
    ) {
        self.id = id
        self.time = time
        self.isEnabled = isEnabled
        self.isSmartAlarm = isSmartAlarm
        self.smartAlarmWindow = smartAlarmWindow
        self.sound = sound
        self.volume = volume
        self.vibrationEnabled = vibrationEnabled
        self.repeatDays = repeatDays
        self.label = label
    }
}

// MARK: - Weekday
enum Weekday: Int, Codable, CaseIterable, Identifiable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7

    var id: Int { rawValue }

    init?(calendarWeekday: Int) {
        self.init(rawValue: calendarWeekday)
    }

    var displayName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        let calendar = Calendar.current
        var components = DateComponents()
        components.weekday = rawValue
        if let date = calendar.nextDate(after: Date(), matching: components, matchingPolicy: .nextTime) {
            return formatter.string(from: date)
        }
        return ""
    }

    var shortName: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        let calendar = Calendar.current
        var components = DateComponents()
        components.weekday = rawValue
        if let date = calendar.nextDate(after: Date(), matching: components, matchingPolicy: .nextTime) {
            return formatter.string(from: date)
        }
        return ""
    }

    var letter: String {
        switch self {
        case .sunday: return "S"
        case .monday: return "M"
        case .tuesday: return "T"
        case .wednesday: return "W"
        case .thursday: return "T"
        case .friday: return "F"
        case .saturday: return "S"
        }
    }
}

// MARK: - Sample Data
extension AlarmModel {
    static var sampleAlarm: AlarmModel {
        var components = DateComponents()
        components.hour = 7
        components.minute = 30
        let time = Calendar.current.date(from: components) ?? Date()

        return AlarmModel(
            time: time,
            isEnabled: true,
            isSmartAlarm: true,
            smartAlarmWindow: 30,
            sound: .sunrise,
            repeatDays: [.monday, .tuesday, .wednesday, .thursday, .friday],
            label: "Work"
        )
    }
}
