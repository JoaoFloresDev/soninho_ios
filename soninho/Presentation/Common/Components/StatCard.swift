//
//  StatCard.swift
//  soninho
//
//  Created by João Flores on 28/01/26.
//

import SwiftUI

// MARK: - Stat Card
struct StatCard: View {
    // MARK: - Properties
    let title: String
    let value: String
    let subtitle: String?
    let icon: String
    let iconColor: Color
    let trend: SleepTrend?

    // MARK: - Init
    init(
        title: String,
        value: String,
        subtitle: String? = nil,
        icon: String,
        iconColor: Color = AppColors.primary,
        trend: SleepTrend? = nil
    ) {
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.icon = icon
        self.iconColor = iconColor
        self.trend = trend
    }

    // MARK: - View Body
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(iconColor)
                    .frame(width: 32, height: 32)
                    .background(iconColor.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Spacer()

                if let trend = trend {
                    HStack(spacing: 2) {
                        Image(systemName: trend.icon)
                            .font(.system(size: 10, weight: .bold))

                        Text(trend.localizedDescription)
                            .font(AppFonts.caption2())
                    }
                    .foregroundColor(trend.color)
                }
            }

            // Value
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(AppFonts.title2())
                    .foregroundColor(AppColors.textPrimary)

                Text(title)
                    .font(AppFonts.caption())
                    .foregroundColor(AppColors.textSecondary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(AppFonts.caption2())
                        .foregroundColor(AppColors.textTertiary)
                }
            }
        }
        .cardStyle()
    }
}

// MARK: - Horizontal Stat Card
struct HorizontalStatCard: View {
    // MARK: - Properties
    let title: String
    let value: String
    let icon: String
    let iconColor: Color

    // MARK: - View Body
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(iconColor)
                .frame(width: 44, height: 44)
                .background(iconColor.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppFonts.caption())
                    .foregroundColor(AppColors.textSecondary)

                Text(value)
                    .font(AppFonts.headline())
                    .foregroundColor(AppColors.textPrimary)
            }

            Spacer()
        }
        .cardStyle()
    }
}

// MARK: - Large Stat Display
struct LargeStatDisplay: View {
    // MARK: - Properties
    let title: String
    let value: String
    let unit: String?
    let color: Color

    // MARK: - View Body
    var body: some View {
        VStack(spacing: 4) {
            HStack(alignment: .lastTextBaseline, spacing: 4) {
                Text(value)
                    .font(AppFonts.number(48))
                    .foregroundColor(color)

                if let unit = unit {
                    Text(unit)
                        .font(AppFonts.title3())
                        .foregroundColor(AppColors.textSecondary)
                }
            }

            Text(title)
                .font(AppFonts.subheadline())
                .foregroundColor(AppColors.textSecondary)
        }
    }
}

// MARK: - Preview
#Preview {
    ScrollView {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                StatCard(
                    title: "Avg. Sleep",
                    value: "7h 32m",
                    subtitle: "Past 7 days",
                    icon: "moon.fill",
                    iconColor: AppColors.primary,
                    trend: .improving
                )

                StatCard(
                    title: "Deep Sleep",
                    value: "1h 45m",
                    subtitle: "22% of sleep",
                    icon: "moon.zzz.fill",
                    iconColor: AppColors.deepSleep
                )
            }

            HorizontalStatCard(
                title: "Average Bedtime",
                value: "23:15",
                icon: "bed.double.fill",
                iconColor: AppColors.accent
            )

            LargeStatDisplay(
                title: "Sleep Duration",
                value: "7",
                unit: "h 32m",
                color: AppColors.primary
            )
            .padding()
        }
        .padding()
    }
    .background(AppColors.background)
}
