import SwiftUI
import GambitScreenshotKit

// MARK: - Tab Bar Mock
//
// Floating glass tab bar matching the real soninho MainTabView. Anchors
// the bottom of each marketing screen so the screenshots read as full
// app screens, not floating cards.

enum TabBarMockItem: Int, CaseIterable {
    case home, sleep, alarm, stats, settings

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .sleep: return "moon.zzz.fill"
        case .alarm: return "alarm.fill"
        case .stats: return "chart.bar.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

struct TabBarMock: View {
    let activeIndex: Int

    var body: some View {
        HStack(spacing: 0) {
            ForEach(TabBarMockItem.allCases, id: \.rawValue) { item in
                tabItem(icon: item.icon, isActive: item.rawValue == activeIndex)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(MockTheme.surface.opacity(0.94))
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .stroke(MockTheme.surfaceTertiary.opacity(0.6), lineWidth: 1)
            }
        )
        .padding(.horizontal, 26)
        .padding(.bottom, 18)
    }

    private func tabItem(icon: String, isActive: Bool) -> some View {
        Image(systemName: icon)
            .font(.system(size: 22, weight: .semibold))
            .foregroundStyle(isActive ? MockTheme.primaryLight : MockTheme.textTertiary)
            .frame(maxWidth: .infinity, minHeight: 44)
            .background(
                Capsule()
                    .fill(isActive ? MockTheme.primary.opacity(0.20) : Color.clear)
                    .padding(.vertical, 2)
                    .padding(.horizontal, 6)
            )
    }
}
