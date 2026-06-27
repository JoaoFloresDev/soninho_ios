import SwiftUI
import GambitScreenshotKit

// MARK: - Onboarding Screen (Slot 5 — Sleep Tips: daily tip + filter chips + tips list)
//
// Faithful recreation of soninho's SleepTipsView. The real screen flow:
//   - Daily Tip section (sparkles label + expanded TipCard with icon, title,
//     description, no chevron because it's already shown)
//   - Horizontal category filter chips (All + 5 categories), "All" selected
//     by default and styled with primary color
//   - Tips list — vertical stack of TipCards (icon tile + title + chevron)
//
// File name kept as "OnboardingScreen.swift" by convention with the
// screenshots-tool slot numbering, but this is the Sleep Tips screen.
// Sized for iPhone 6.5" canvas (414×896pt). NO ScrollView.

struct OnboardingScreen: View {
    let locale: String

    // MARK: - View Body
    var body: some View {
        ZStack {
            MockTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                iOSStatusBar(foreground: .white)

                navBar

                VStack(alignment: .leading, spacing: 22) {
                    dailyTipSection
                    categoryFilterRow
                    tipsList
                }
                .padding(.horizontal, 20)
                .padding(.top, 4)

                Spacer(minLength: 0)
            }
        }
    }

    // MARK: - Nav Bar (mirrors navigationTitle "Sleep Tips")
    private var navBar: some View {
        HStack {
            Image(systemName: "chevron.left")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(MockTheme.primaryLight)
                .frame(width: 40, height: 40)

            Spacer()

            Text(LocalizedLabels.tipsTitle[locale] ?? "Sleep Tips")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(MockTheme.textPrimary)

            Spacer()

            // Spacer counterpart to keep title centered
            Color.clear.frame(width: 40, height: 40)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    // MARK: - Daily Tip Section
    //
    // Mirrors `dailyTipCard` in SleepTipsView: a section header row
    // (sparkles + "Tip of the day") above an expanded TipCard.
    private var dailyTipSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(MockTheme.accent)

                Text(LocalizedLabels.tipsDailyLabel[locale] ?? "Tip of the day")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(MockTheme.textPrimary)
            }

            expandedTipCard
        }
    }

    /// Expanded TipCard (isExpanded = true) — icon tile + title + description.
    private var expandedTipCard: some View {
        HStack(alignment: .top, spacing: 16) {
            // Icon tile (mirrors the real TipCard 48×48 icon with primary tint)
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(MockTheme.primary.opacity(0.15))
                    .frame(width: 56, height: 56)
                Image(systemName: "clock.fill")
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundStyle(MockTheme.primary)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(LocalizedLabels.tipsDailyTitle[locale] ?? "Same bedtime, every night")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(MockTheme.textPrimary)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Text(LocalizedLabels.tipsDailyBody[locale] ?? "")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(MockTheme.textSecondary)
                    .multilineTextAlignment(.leading)
                    .lineLimit(4)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            ZStack {
                MockTheme.surface
                LinearGradient(
                    colors: [MockTheme.primary.opacity(0.14), MockTheme.accent.opacity(0.06)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: - Category Filter Chips
    //
    // Mirrors the horizontal scroll FilterChip strip in the real app.
    // First chip "All" is selected (filled primary); rest are unselected
    // (surface bg + textSecondary). No scroll — fits 4 chips inline at 6.5".
    private var categoryFilterRow: some View {
        let allLabel = LocalizedLabels.tipsAll[locale] ?? "All"
        return HStack(spacing: 8) {
            filterChip(title: allLabel, selected: true)
            ForEach(MockTipCategories.all.prefix(3)) { cat in
                let name = LocalizedLabels.tipsCategoryNames[cat.nameKey]?[locale] ?? cat.nameKey
                filterChip(title: name, selected: false)
            }
        }
    }

    private func filterChip(title: String, selected: Bool) -> some View {
        Text(title)
            .font(.system(size: 13, weight: selected ? .semibold : .regular))
            .foregroundStyle(selected ? .white : MockTheme.textSecondary)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(
                Capsule().fill(selected ? AnyShapeStyle(MockTheme.primary) : AnyShapeStyle(MockTheme.surface))
            )
    }

    // MARK: - Tips List
    //
    // Mirrors the LazyVStack of collapsed TipCards in the real app.
    private var tipsList: some View {
        VStack(spacing: 12) {
            ForEach(MockTipList.all) { tip in
                tipRow(tip)
            }
        }
    }

    private func tipRow(_ tip: MockTipListItem) -> some View {
        HStack(spacing: 16) {
            // Icon tile (48×48, tinted)
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(tip.tint.opacity(0.18))
                    .frame(width: 48, height: 48)
                Image(systemName: tip.icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(tip.tint)
            }

            Text(MockTipList.title(for: tip, locale: locale))
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(MockTheme.textPrimary)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)

            Spacer(minLength: 0)

            Image(systemName: "chevron.down")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(MockTheme.textTertiary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MockTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
