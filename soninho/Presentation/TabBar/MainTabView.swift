//
//  MainTabView.swift
//  soninho
//
//  Created by João Flores on 28/01/26.
//

import SwiftUI

// MARK: - Notification Names
extension Notification.Name {
    static let didSwitchToDataTab = Notification.Name("didSwitchToDataTab")
    static let didRequestSwitchToSleepTab = Notification.Name("didRequestSwitchToSleepTab")
    static let didRequestStartSleepTracking = Notification.Name("didRequestStartSleepTracking")
    /// Posted when an alarm is fully dismissed (not snoozed) — ends any active
    /// sleep tracking session.
    static let didCompleteAlarm = Notification.Name("didCompleteAlarm")
}

// MARK: - Tab Item
enum TabItem: Int, CaseIterable, Identifiable {
    case tracker
    case alarm
    case statistics
    case settings

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .tracker: return String(localized: "tab_sleep")
        case .alarm: return String(localized: "tab_alarm")
        case .statistics: return String(localized: "tab_stats")
        case .settings: return String(localized: "tab_settings")
        }
    }

    var icon: String {
        switch self {
        case .tracker: return "moon.zzz.fill"
        case .alarm: return "alarm.fill"
        case .statistics: return "chart.bar.fill"
        case .settings: return "gearshape.fill"
        }
    }

    var iconUnselected: String {
        switch self {
        case .tracker: return "moon.zzz"
        case .alarm: return "alarm"
        case .statistics: return "chart.bar"
        case .settings: return "gearshape"
        }
    }
}

// MARK: - Main Tab View
struct MainTabView: View {
    // MARK: - Properties
    @State private var selectedTab: TabItem = .tracker
    @EnvironmentObject private var storageService: StorageService

    // MARK: - Init
    init() {
        // Dark tab bar appearance
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = UIColor(AppColors.surface)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    // MARK: - View Body
    var body: some View {
        TabView(selection: $selectedTab) {
            SleepTrackerView()
                .tabItem {
                    Label(TabItem.tracker.title, systemImage: selectedTab == .tracker ? TabItem.tracker.icon : TabItem.tracker.iconUnselected)
                }
                .tag(TabItem.tracker)

            SmartAlarmView()
                .tabItem {
                    Label(TabItem.alarm.title, systemImage: selectedTab == .alarm ? TabItem.alarm.icon : TabItem.alarm.iconUnselected)
                }
                .tag(TabItem.alarm)

            StatisticsView()
                .tabItem {
                    Label(TabItem.statistics.title, systemImage: selectedTab == .statistics ? TabItem.statistics.icon : TabItem.statistics.iconUnselected)
                }
                .tag(TabItem.statistics)

            SettingsView()
                .tabItem {
                    Label(TabItem.settings.title, systemImage: selectedTab == .settings ? TabItem.settings.icon : TabItem.settings.iconUnselected)
                }
                .tag(TabItem.settings)
        }
        .tint(AppColors.primary)
        .onChange(of: selectedTab) { _, newTab in
            if newTab == .statistics {
                NotificationCenter.default.post(name: .didSwitchToDataTab, object: nil)
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .didRequestSwitchToSleepTab)) { _ in
            selectedTab = .tracker
        }
    }
}
