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
    case alarm
    case tracker
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
}

// MARK: - Main Tab View
struct MainTabView: View {
    // MARK: - Properties
    @State private var selectedTab: TabItem = .alarm
    @EnvironmentObject private var storageService: StorageService

    // MARK: - Init
    init() {
        // iOS 26 renders the tab bar in Liquid Glass — leave it untouched there.
        if #available(iOS 26.0, *) { return }
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        appearance.backgroundColor = UIColor(AppColors.surface)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    // MARK: - View Body
    var body: some View {
        TabView(selection: $selectedTab) {
            SmartAlarmView()
                .tabItem {
                    Label(TabItem.alarm.title, systemImage: TabItem.alarm.icon)
                }
                .tag(TabItem.alarm)

            SleepTrackerView()
                .tabItem {
                    Label(TabItem.tracker.title, systemImage: TabItem.tracker.icon)
                }
                .tag(TabItem.tracker)

            StatisticsView()
                .tabItem {
                    Label(TabItem.statistics.title, systemImage: TabItem.statistics.icon)
                }
                .tag(TabItem.statistics)

            SettingsView()
                .tabItem {
                    Label(TabItem.settings.title, systemImage: TabItem.settings.icon)
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
