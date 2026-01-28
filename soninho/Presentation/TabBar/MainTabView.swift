//
//  MainTabView.swift
//  soninho
//
//  Created by João Flores on 28/01/26.
//

import SwiftUI

// MARK: - Tab Item
enum TabItem: Int, CaseIterable, Identifiable {
    case home
    case tracker
    case alarm
    case statistics
    case settings

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .home: return String(localized: "tab_home")
        case .tracker: return String(localized: "tab_sleep")
        case .alarm: return String(localized: "tab_alarm")
        case .statistics: return String(localized: "tab_stats")
        case .settings: return String(localized: "tab_settings")
        }
    }

    var icon: String {
        switch self {
        case .home: return "house.fill"
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
    @State private var selectedTab: TabItem = .home
    @EnvironmentObject private var storageService: StorageService

    // MARK: - View Body
    var body: some View {
        ZStack(alignment: .bottom) {
            // Tab Content
            TabView(selection: $selectedTab) {
                HomeView()
                    .tag(TabItem.home)

                SleepTrackerView()
                    .tag(TabItem.tracker)

                SmartAlarmView()
                    .tag(TabItem.alarm)

                StatisticsView()
                    .tag(TabItem.statistics)

                SettingsView()
                    .tag(TabItem.settings)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            // Custom Tab Bar
            customTabBar
        }
        .ignoresSafeArea(.keyboard)
    }

    // MARK: - Custom Tab Bar
    private var customTabBar: some View {
        HStack(spacing: 0) {
            ForEach(TabItem.allCases) { tab in
                tabButton(for: tab)
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 12)
        .padding(.bottom, 28)
        .background(
            AppColors.surface
                .shadow(color: .black.opacity(0.2), radius: 20, y: -5)
        )
    }

    private func tabButton(for tab: TabItem) -> some View {
        Button {
            HapticManager.selection()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 22, weight: selectedTab == tab ? .semibold : .regular))
                    .foregroundColor(selectedTab == tab ? AppColors.primary : AppColors.textTertiary)
                    .scaleEffect(selectedTab == tab ? 1.1 : 1.0)

                Text(tab.title)
                    .font(AppFonts.caption2())
                    .foregroundColor(selectedTab == tab ? AppColors.primary : AppColors.textTertiary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview
#Preview {
    MainTabView()
        .environmentObject(StorageService.shared)
}
