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

    var iconUnselected: String {
        switch self {
        case .home: return "house"
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
    @State private var selectedTab: TabItem = .home
    @EnvironmentObject private var storageService: StorageService
    @Namespace private var tabAnimation

    // MARK: - View Body
    var body: some View {
        ZStack {
            // Tab Content
            Group {
                switch selectedTab {
                case .home:
                    HomeView()
                case .tracker:
                    SleepTrackerView()
                case .alarm:
                    SmartAlarmView()
                case .statistics:
                    StatisticsView()
                case .settings:
                    SettingsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .safeAreaInset(edge: .bottom) {
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
        .padding(.horizontal, 6)
        .padding(.vertical, 8)
        .background(tabBarBackground)
        .padding(.horizontal, 24)
        .padding(.bottom, 16)
    }

    // MARK: - Tab Bar Background
    private var tabBarBackground: some View {
        RoundedRectangle(cornerRadius: 28, style: .continuous)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.15),
                                Color.white.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(0.25), radius: 20, y: 10)
    }

    // MARK: - Tab Button
    private func tabButton(for tab: TabItem) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            HapticManager.selection()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    // Background indicator
                    if isSelected {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        AppColors.primary.opacity(0.25),
                                        AppColors.accent.opacity(0.15)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 52, height: 36)
                            .matchedGeometryEffect(id: "tabIndicator", in: tabAnimation)
                    }

                    // Icon
                    Image(systemName: isSelected ? tab.icon : tab.iconUnselected)
                        .font(.system(size: 20, weight: isSelected ? .semibold : .regular))
                        .foregroundStyle(
                            isSelected
                                ? AnyShapeStyle(AppColors.sleepGradient)
                                : AnyShapeStyle(AppColors.textTertiary)
                        )
                        .frame(width: 52, height: 36)
                        .scaleEffect(isSelected ? 1.05 : 1.0)
                }

                // Label
                Text(tab.title)
                    .font(.system(size: 10, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? AppColors.primary : AppColors.textTertiary)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview
#Preview {
    MainTabView()
        .environmentObject(StorageService.shared)
        .preferredColorScheme(.dark)
}
