//
//  EmptyStateView.swift
//  soninho
//
//  Created by João Flores on 28/01/26.
//

import SwiftUI

// MARK: - Empty State View
struct EmptyStateView: View {
    // MARK: - Properties
    let icon: String
    let title: String
    let message: String
    let actionTitle: String?
    let action: (() -> Void)?

    // MARK: - State
    @State private var isAnimating = false

    // MARK: - Init
    init(
        icon: String = "moon.stars.fill",
        title: String,
        message: String,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    // MARK: - View Body
    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(AppColors.primary.opacity(0.1))
                    .frame(width: 120, height: 120)

                Circle()
                    .fill(AppColors.primary.opacity(0.2))
                    .frame(width: 90, height: 90)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(
                        .easeInOut(duration: 2).repeatForever(autoreverses: true),
                        value: isAnimating
                    )

                Image(systemName: icon)
                    .font(.system(size: 44))
                    .foregroundStyle(AppColors.sleepGradient)
            }

            // Text
            VStack(spacing: 8) {
                Text(title)
                    .font(AppFonts.title2())
                    .foregroundStyle(AppColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(AppFonts.body())
                    .foregroundStyle(AppColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
            .padding(.horizontal, 32)

            // Action Button
            if let actionTitle = actionTitle, let action = action {
                AppButton(title: actionTitle, style: .primary, action: action)
                    .padding(.horizontal, 48)
                    .padding(.top, 8)
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(AppColors.background)
        .onAppear {
            isAnimating = true
        }
    }
}

// MARK: - Sleep Data Placeholder
struct SleepDataPlaceholderView: View {
    // MARK: - View Body
    var body: some View {
        VStack(spacing: 20) {
            // Score Preview
            scorePlaceholder

            // Metrics Preview
            metricsPlaceholder

            // Chart Preview
            chartPlaceholder

            // Phases Preview
            phasesPlaceholder
        }
    }

    // MARK: - Score Placeholder
    private var scorePlaceholder: some View {
        HStack(spacing: 16) {
            // Empty score ring
            ZStack {
                Circle()
                    .stroke(AppColors.surfaceSecondary, lineWidth: 10)
                    .frame(width: 100, height: 100)

                VStack(spacing: 2) {
                    Text("--")
                        .font(AppFonts.title())
                        .foregroundStyle(AppColors.textTertiary)
                    Text(String(localized: "home_score"))
                        .font(AppFonts.caption2())
                        .foregroundStyle(AppColors.textTertiary)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text(String(localized: "empty_no_sleep_title"))
                    .font(AppFonts.headline())
                    .foregroundStyle(AppColors.textPrimary)

                Text(String(localized: "empty_placeholder_subtitle"))
                    .font(AppFonts.caption())
                    .foregroundStyle(AppColors.textSecondary)
                    .lineLimit(2)

                HStack(spacing: 4) {
                    Image(systemName: "bed.double.fill")
                        .font(.system(size: 12))
                    Text("--:--")
                    Image(systemName: "arrow.right")
                        .font(.system(size: 10))
                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 12))
                    Text("--:--")
                }
                .font(AppFonts.caption())
                .foregroundStyle(AppColors.textTertiary)
            }

            Spacer()
        }
        .padding(20)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: - Metrics Placeholder
    private var metricsPlaceholder: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            placeholderMetric(icon: "percent", title: String(localized: "metric_efficiency"), color: AppColors.success)
            placeholderMetric(icon: "clock.fill", title: String(localized: "metric_time_asleep"), color: AppColors.primary)
            placeholderMetric(icon: "moon.zzz.fill", title: String(localized: "metric_deep_sleep"), color: AppColors.deepSleep)
            placeholderMetric(icon: "sparkles", title: String(localized: "metric_rem_sleep"), color: AppColors.remSleep)
        }
    }

    private func placeholderMetric(icon: String, title: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundStyle(color.opacity(0.5))

                Text(title)
                    .font(AppFonts.caption())
                    .foregroundStyle(AppColors.textTertiary)
            }

            Text("--")
                .font(AppFonts.title2())
                .fontWeight(.bold)
                .foregroundStyle(AppColors.textTertiary)

            RoundedRectangle(cornerRadius: 3)
                .fill(AppColors.surfaceSecondary)
                .frame(width: 60, height: 8)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(AppColors.surfaceSecondary.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    // MARK: - Chart Placeholder
    private var chartPlaceholder: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "analysis_sleep_stages"))
                .font(AppFonts.headline())
                .foregroundStyle(AppColors.textTertiary)

            // Fake hypnogram
            ZStack(alignment: .topLeading) {
                // Grid lines
                VStack(spacing: 0) {
                    ForEach(0..<4, id: \.self) { _ in
                        Rectangle()
                            .fill(AppColors.surfaceSecondary)
                            .frame(height: 1)
                        Spacer()
                    }
                }

                // Placeholder wave
                placeholderWavePath
            }
            .frame(height: 120)

            // Y-axis labels
            HStack {
                ForEach(["22:00", "00:00", "02:00", "04:00", "06:00"], id: \.self) { time in
                    Text(time)
                        .font(.system(size: 9))
                        .foregroundStyle(AppColors.textTertiary.opacity(0.5))
                    if time != "06:00" { Spacer() }
                }
            }
        }
        .padding(20)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var placeholderWavePath: some View {
        GeometryReader { geometry in
            let w = geometry.size.width
            let h: CGFloat = 120

            Path { path in
                let points: [(CGFloat, CGFloat)] = [
                    (0.0, 0.5), (0.05, 0.7), (0.1, 0.85),
                    (0.15, 0.2), (0.25, 0.15), (0.3, 0.5),
                    (0.35, 0.7), (0.45, 0.2), (0.5, 0.15),
                    (0.55, 0.5), (0.6, 0.75), (0.7, 0.2),
                    (0.75, 0.6), (0.8, 0.7), (0.85, 0.5),
                    (0.9, 0.35), (0.95, 0.6), (1.0, 0.1)
                ]

                for (i, point) in points.enumerated() {
                    let x = point.0 * w
                    let y = (1.0 - point.1) * h
                    if i == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(AppColors.primary.opacity(0.3), lineWidth: 2)
        }
    }

    // MARK: - Phases Placeholder
    private var phasesPlaceholder: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "analysis_time_in_stages"))
                .font(AppFonts.headline())
                .foregroundStyle(AppColors.textTertiary)

            // Stacked bar placeholder
            HStack(spacing: 2) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppColors.deepSleep.opacity(0.3))
                    .frame(width: nil)
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppColors.lightSleep.opacity(0.3))
                    .frame(width: nil)
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppColors.remSleep.opacity(0.3))
                    .frame(width: nil)
                RoundedRectangle(cornerRadius: 4)
                    .fill(AppColors.awake.opacity(0.3))
                    .frame(maxWidth: 30)
            }
            .frame(height: 24)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Phase rows placeholder
            VStack(spacing: 8) {
                placeholderPhaseRow(name: String(localized: "stage_deep"), color: AppColors.deepSleep)
                placeholderPhaseRow(name: String(localized: "stage_light"), color: AppColors.lightSleep)
                placeholderPhaseRow(name: String(localized: "stage_rem"), color: AppColors.remSleep)
                placeholderPhaseRow(name: String(localized: "stage_awake"), color: AppColors.awake)
            }
        }
        .padding(20)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func placeholderPhaseRow(name: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(color.opacity(0.5))
                .frame(width: 10, height: 10)

            Text(name)
                .font(AppFonts.subheadline())
                .foregroundStyle(AppColors.textTertiary)
                .frame(width: 80, alignment: .leading)

            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppColors.surfaceSecondary)
                }
            }
            .frame(height: 8)

            Text("--:--")
                .font(AppFonts.subheadline())
                .foregroundStyle(AppColors.textTertiary)
                .frame(width: 60, alignment: .trailing)
        }
    }
}