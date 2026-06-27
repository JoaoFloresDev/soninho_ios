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
                    .foregroundStyle(iconColor)
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
                    .foregroundStyle(trend.color)
                }
            }

            // Value
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(AppFonts.title2())
                    .foregroundStyle(AppColors.textPrimary)

                Text(title)
                    .font(AppFonts.caption())
                    .foregroundStyle(AppColors.textSecondary)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(AppFonts.caption2())
                        .foregroundStyle(AppColors.textTertiary)
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
                .foregroundStyle(iconColor)
                .frame(width: 44, height: 44)
                .background(iconColor.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppFonts.caption())
                    .foregroundStyle(AppColors.textSecondary)

                Text(value)
                    .font(AppFonts.headline())
                    .foregroundStyle(AppColors.textPrimary)
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
                    .foregroundStyle(color)

                if let unit = unit {
                    Text(unit)
                        .font(AppFonts.title3())
                        .foregroundStyle(AppColors.textSecondary)
                }
            }

            Text(title)
                .font(AppFonts.subheadline())
                .foregroundStyle(AppColors.textSecondary)
        }
    }
}