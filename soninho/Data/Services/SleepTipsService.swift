//
//  SleepTipsService.swift
//  soninho
//
//  Created by João Flores on 28/01/26.
//

import Foundation

// MARK: - Sleep Tip
struct SleepTip: Identifiable {
    let id = UUID()
    let icon: String
    let title: String
    let description: String
    let category: TipCategory
    
    enum TipCategory: String, CaseIterable {
        case routine = "routine"
        case environment = "environment"
        case lifestyle = "lifestyle"
        case nutrition = "nutrition"
        case relaxation = "relaxation"
        
        var localizedName: String {
            String(localized: String.LocalizationValue("tip_category_\(rawValue)"))
        }
    }
}

// MARK: - Sleep Tips Service
@MainActor
final class SleepTipsService {
    // MARK: - Singleton
    static let shared = SleepTipsService()
    
    // MARK: - Properties
    private let allTips: [SleepTip] = [
        // Routine Tips
        SleepTip(
            icon: "clock.fill",
            title: "tip_consistent_schedule_title",
            description: "tip_consistent_schedule_desc",
            category: .routine
        ),
        SleepTip(
            icon: "sun.horizon.fill",
            title: "tip_morning_light_title",
            description: "tip_morning_light_desc",
            category: .routine
        ),
        SleepTip(
            icon: "bed.double.fill",
            title: "tip_wind_down_title",
            description: "tip_wind_down_desc",
            category: .routine
        ),
        
        // Environment Tips
        SleepTip(
            icon: "thermometer.snowflake",
            title: "tip_cool_room_title",
            description: "tip_cool_room_desc",
            category: .environment
        ),
        SleepTip(
            icon: "moon.stars.fill",
            title: "tip_dark_room_title",
            description: "tip_dark_room_desc",
            category: .environment
        ),
        SleepTip(
            icon: "speaker.slash.fill",
            title: "tip_quiet_room_title",
            description: "tip_quiet_room_desc",
            category: .environment
        ),
        
        // Lifestyle Tips
        SleepTip(
            icon: "figure.run",
            title: "tip_exercise_title",
            description: "tip_exercise_desc",
            category: .lifestyle
        ),
        SleepTip(
            icon: "iphone.slash",
            title: "tip_screen_time_title",
            description: "tip_screen_time_desc",
            category: .lifestyle
        ),
        SleepTip(
            icon: "sun.max.fill",
            title: "tip_daylight_title",
            description: "tip_daylight_desc",
            category: .lifestyle
        ),
        
        // Nutrition Tips
        SleepTip(
            icon: "cup.and.saucer.fill",
            title: "tip_caffeine_title",
            description: "tip_caffeine_desc",
            category: .nutrition
        ),
        SleepTip(
            icon: "fork.knife",
            title: "tip_heavy_meals_title",
            description: "tip_heavy_meals_desc",
            category: .nutrition
        ),
        SleepTip(
            icon: "drop.fill",
            title: "tip_hydration_title",
            description: "tip_hydration_desc",
            category: .nutrition
        ),
        
        // Relaxation Tips
        SleepTip(
            icon: "lungs.fill",
            title: "tip_breathing_title",
            description: "tip_breathing_desc",
            category: .relaxation
        ),
        SleepTip(
            icon: "brain.head.profile",
            title: "tip_meditation_title",
            description: "tip_meditation_desc",
            category: .relaxation
        ),
        SleepTip(
            icon: "book.fill",
            title: "tip_reading_title",
            description: "tip_reading_desc",
            category: .relaxation
        )
    ]
    
    // MARK: - Init
    private init() {}
    
    // MARK: - Public Methods
    func getDailyTip() -> SleepTip {
        // Get a different tip each day based on the day of year
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        let index = dayOfYear % allTips.count
        return allTips[index]
    }
    
    func getTipsForCategory(_ category: SleepTip.TipCategory) -> [SleepTip] {
        allTips.filter { $0.category == category }
    }
    
    func getAllTips() -> [SleepTip] {
        allTips
    }
    
    func getRandomTips(count: Int) -> [SleepTip] {
        Array(allTips.shuffled().prefix(count))
    }
    
    func getPersonalizedTips(
        averageQuality: Int,
        averageDuration: TimeInterval,
        consistency: Int
    ) -> [SleepTip] {
        var tips: [SleepTip] = []
        
        // Low quality score - suggest relaxation
        if averageQuality < 60 {
            tips.append(contentsOf: getTipsForCategory(.relaxation).prefix(1))
        }
        
        // Short sleep duration - suggest routine
        if averageDuration < 7 * 3600 {
            tips.append(contentsOf: getTipsForCategory(.routine).prefix(1))
        }
        
        // Low consistency - suggest environment
        if consistency < 70 {
            tips.append(contentsOf: getTipsForCategory(.environment).prefix(1))
        }
        
        // If no specific issues, return general tips
        if tips.isEmpty {
            tips = getRandomTips(count: 2)
        }
        
        return Array(tips.prefix(3))
    }
}
