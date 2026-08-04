//
//  WakeMissionModel.swift
//  soninho
//
//  Wake-up "mission" that must be completed to dismiss the alarm, plus the
//  anti-relapse confirmation targets. Part of the Pacote Despertar.
//

import Foundation

// MARK: - Wake Mission
/// Task the user must complete before the alarm can be dismissed.
enum WakeMission: String, Codable, CaseIterable, Identifiable {
    case none = "none"
    case math = "math"
    case shake = "shake"
    case typing = "typing"
    case memory = "memory"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .none: return String(localized: "wake_mission_none")
        case .math: return String(localized: "wake_mission_math")
        case .shake: return String(localized: "wake_mission_shake")
        case .typing: return String(localized: "wake_mission_typing")
        case .memory: return String(localized: "wake_mission_memory")
        }
    }

    var icon: String {
        switch self {
        case .none: return "moon.zzz.fill"
        case .math: return "function"
        case .shake: return "iphone.gen3.radiowaves.left.and.right"
        case .typing: return "keyboard"
        case .memory: return "square.grid.3x3.fill"
        }
    }

    var requiresMission: Bool { self != .none }
}

// MARK: - Mission Difficulty
/// Scales how much effort the mission demands, so it can match how hard the
/// user is to wake.
enum MissionDifficulty: String, Codable, CaseIterable, Identifiable {
    case easy = "easy"
    case medium = "medium"
    case hard = "hard"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .easy: return String(localized: "wake_difficulty_easy")
        case .medium: return String(localized: "wake_difficulty_medium")
        case .hard: return String(localized: "wake_difficulty_hard")
        }
    }

    /// Number of math problems that must be solved in a row.
    var mathRounds: Int {
        switch self {
        case .easy: return 1
        case .medium: return 2
        case .hard: return 3
        }
    }

    /// Number of shakes required to dismiss.
    var shakeTarget: Int {
        switch self {
        case .easy: return 15
        case .medium: return 25
        case .hard: return 40
        }
    }

    /// Number of phrases that must be typed in a row.
    var typingRounds: Int {
        switch self {
        case .easy: return 1
        case .medium: return 1
        case .hard: return 2
        }
    }

    /// Length of the tile sequence to memorize and repeat.
    var memorySequenceLength: Int {
        switch self {
        case .easy: return 4
        case .medium: return 5
        case .hard: return 7
        }
    }
}

// MARK: - Typing Challenge
/// A localized phrase the user must retype exactly to dismiss the alarm.
struct TypingChallenge: Identifiable {
    // MARK: - Properties
    let id = UUID()
    let phrase: String

    // MARK: - Factory
    static func make(for difficulty: MissionDifficulty) -> TypingChallenge {
        // Short phrases wake a light sleeper; long ones force real focus.
        let shortKeys = ["wake_phrase_1", "wake_phrase_2", "wake_phrase_3"]
        let longKeys = ["wake_phrase_4", "wake_phrase_5", "wake_phrase_6"]
        let pool = difficulty == .easy ? shortKeys : longKeys
        let key = pool.randomElement() ?? "wake_phrase_1"
        return TypingChallenge(phrase: String(localized: String.LocalizationValue(key)))
    }
}

// MARK: - Math Challenge
/// A single generated arithmetic problem.
struct MathChallenge: Identifiable {
    // MARK: - Properties
    let id = UUID()
    let question: String
    let answer: Int

    // MARK: - Factory
    static func make(for difficulty: MissionDifficulty) -> MathChallenge {
        switch difficulty {
        case .easy:
            let a = Int.random(in: 2...9)
            let b = Int.random(in: 2...9)
            return MathChallenge(question: "\(a) + \(b)", answer: a + b)
        case .medium:
            // Mix of addition and subtraction with two-digit operands.
            if Bool.random() {
                let a = Int.random(in: 11...39)
                let b = Int.random(in: 11...39)
                return MathChallenge(question: "\(a) + \(b)", answer: a + b)
            } else {
                let a = Int.random(in: 20...49)
                let b = Int.random(in: 5...a - 1)
                return MathChallenge(question: "\(a) − \(b)", answer: a - b)
            }
        case .hard:
            let a = Int.random(in: 3...12)
            let b = Int.random(in: 3...12)
            return MathChallenge(question: "\(a) × \(b)", answer: a * b)
        }
    }
}

// MARK: - Wake Confirmation (anti-relapse)
/// Targets for the post-dismiss motion check that confirms the user actually
/// got up instead of rolling back over.
enum WakeConfirmation {
    /// Steps the user must take after dismissing to clear the alarm for good.
    static let stepTarget = 15
    /// If the target isn't reached within this many seconds, the alarm re-rings.
    static let timeoutSeconds: TimeInterval = 120
}
