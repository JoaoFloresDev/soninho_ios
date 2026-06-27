//
//  SleepAnalysisView.swift
//  soninho
//
//  Created by João Flores on 28/01/26.
//

import SwiftUI
import Charts

// MARK: - Sleep Analysis Card
/// Professional sleep analysis component with detailed insights
struct SleepAnalysisCard: View {
    // MARK: - Properties
    let record: SleepRecord

    // MARK: - Computed Properties
    private var sleepEfficiency: Double {
        let totalTime = record.totalDuration
        guard totalTime > 0 else { return 0 }

        let awakeTime = record.awakeDuration

        // Assume minimum sleep onset latency (~5 min to fall asleep)
        // and brief micro-awakenings that motion sensors can't detect
        let sleepOnsetLatency: TimeInterval = 5 * 60
        let estimatedAwakeTime = max(awakeTime, sleepOnsetLatency)

        let actualSleep = totalTime - estimatedAwakeTime
        let efficiency = (actualSleep / totalTime) * 100

        // Cap at 97% — perfect 100% efficiency is unrealistic even for ideal sleepers
        return min(max(efficiency, 0), 97)
    }

    private var isOptimalDuration: Bool {
        record.totalHours >= 7 && record.totalHours <= 9
    }

    private var isOptimalDeepSleep: Bool {
        record.deepSleepPercentage >= 15 && record.deepSleepPercentage <= 25
    }

    private var isOptimalREM: Bool {
        record.remSleepPercentage >= 20 && record.remSleepPercentage <= 25
    }

    // MARK: - View Body
    var body: some View {
        VStack(spacing: 24) {
            // Header with Score
            headerSection

            // Sleep Timeline
            sleepTimelineSection

            // Key Metrics Grid
            keyMetricsGrid

            // Sleep Phases Breakdown
            phasesBreakdown

            // Insights
            insightsSection
        }
        .padding(20)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: - Header Section
    private var headerSection: some View {
        HStack(alignment: .top, spacing: 16) {
            // Score Ring
            SleepScoreRing(score: record.qualityScore, size: 100, lineWidth: 10)

            // Summary
            VStack(alignment: .leading, spacing: 8) {
                Text(record.startTime.mediumDateString)
                    .font(AppFonts.subheadline())
                    .foregroundStyle(AppColors.textSecondary)

                Text(record.durationString)
                    .font(AppFonts.title())
                    .foregroundStyle(AppColors.textPrimary)

                HStack(spacing: 4) {
                    Image(systemName: "bed.double.fill")
                        .font(.system(size: 12))
                    Text(record.startTime.timeString)

                    Image(systemName: "arrow.right")
                        .font(.system(size: 10))

                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 12))
                    Text(record.endTime.timeString)
                }
                .font(AppFonts.caption())
                .foregroundStyle(AppColors.textTertiary)
            }

            Spacer()
        }
    }

    // MARK: - Sleep Timeline Section
    private var sleepTimelineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "analysis_sleep_stages"))
                .font(AppFonts.headline())
                .foregroundStyle(AppColors.textPrimary)

            if #available(iOS 17.0, *) {
                hypnogramChart
            } else {
                legacyHypnogram
            }
        }
    }

    // MARK: - Hypnogram Chart (iOS 17+)
    @available(iOS 17.0, *)
    private var hypnogramChart: some View {
        let dataPoints = hypnogramDataPoints
        return Chart {
            ForEach(Array(dataPoints.enumerated()), id: \.offset) { _, point in
                LineMark(
                    x: .value("Time", point.time),
                    y: .value("Stage", point.stage)
                )
                .interpolationMethod(.stepEnd)
                .foregroundStyle(AppColors.primary)
                .lineStyle(StrokeStyle(lineWidth: 2))

                AreaMark(
                    x: .value("Time", point.time),
                    y: .value("Stage", point.stage)
                )
                .interpolationMethod(.stepEnd)
                .foregroundStyle(
                    LinearGradient(
                        colors: [AppColors.primary.opacity(0.25), AppColors.primary.opacity(0.02)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
        .chartXAxis {
            AxisMarks(values: .stride(by: .hour, count: 2)) { value in
                AxisValueLabel(format: .dateTime.hour(.defaultDigits(amPM: .abbreviated)))
                    .foregroundStyle(AppColors.textTertiary)
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [4]))
                    .foregroundStyle(AppColors.surfaceSecondary)
            }
        }
        .chartYAxis {
            AxisMarks(values: [1, 2, 3, 4]) { value in
                AxisValueLabel {
                    Text(stageLabel(value.as(Int.self) ?? 1))
                        .font(.system(size: 10))
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
        }
        .chartYScale(domain: 0...5)
        .frame(height: 160)
    }

    // MARK: - Hypnogram Data Points
    private var hypnogramDataPoints: [(time: Date, stage: Int)] {
        var points: [(time: Date, stage: Int)] = []
        for phase in record.phases {
            points.append((time: phase.startTime, stage: stageValue(phase.phase)))
        }
        if let lastPhase = record.phases.last {
            points.append((time: lastPhase.endTime, stage: stageValue(lastPhase.phase)))
        }
        return points
    }

    // MARK: - Legacy Hypnogram
    private var legacyHypnogram: some View {
        GeometryReader { geometry in
            let totalDuration = record.endTime.timeIntervalSince(record.startTime)
            let width = geometry.size.width
            let height: CGFloat = 120

            ZStack(alignment: .topLeading) {
                // Grid lines
                ForEach(0..<4, id: \.self) { i in
                    Rectangle()
                        .fill(AppColors.surfaceSecondary)
                        .frame(height: 1)
                        .offset(y: CGFloat(i) * (height / 4))
                }

                // Phase path
                Path { path in
                    var isFirst = true
                    for phase in record.phases {
                        let x = phase.startTime.timeIntervalSince(record.startTime) / totalDuration * width
                        let y = height - (CGFloat(stageValue(phase.phase)) / 4.0 * height)

                        if isFirst {
                            path.move(to: CGPoint(x: x, y: y))
                            isFirst = false
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(AppColors.primary, lineWidth: 2)
            }
        }
        .frame(height: 120)
    }

    // MARK: - Key Metrics Grid
    private var keyMetricsGrid: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: 12) {
            MetricCard(
                icon: "percent",
                title: String(localized: "metric_efficiency"),
                value: String(format: "%.0f%%", sleepEfficiency),
                subtitle: sleepEfficiency >= 85 ? String(localized: "metric_optimal") : String(localized: "metric_can_improve"),
                color: sleepEfficiency >= 85 ? AppColors.success : AppColors.warning
            )

            MetricCard(
                icon: "clock.fill",
                title: String(localized: "metric_time_asleep"),
                value: (record.totalDuration - record.awakeDuration).hoursMinutesString,
                subtitle: isOptimalDuration ? String(localized: "metric_ideal_range") : String(localized: "metric_adjust_schedule"),
                color: isOptimalDuration ? AppColors.success : AppColors.warning
            )

            MetricCard(
                icon: "moon.zzz.fill",
                title: String(localized: "metric_deep_sleep"),
                value: record.deepSleepDuration.hoursMinutesString,
                subtitle: String(format: "%.0f%% %@", record.deepSleepPercentage, String(localized: "metric_of_total")),
                color: isOptimalDeepSleep ? AppColors.deepSleep : AppColors.warning
            )

            MetricCard(
                icon: "sparkles",
                title: String(localized: "metric_rem_sleep"),
                value: record.remSleepDuration.hoursMinutesString,
                subtitle: String(format: "%.0f%% %@", record.remSleepPercentage, String(localized: "metric_of_total")),
                color: isOptimalREM ? AppColors.remSleep : AppColors.warning
            )
        }
    }

    // MARK: - Phases Breakdown
    private var phasesBreakdown: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "analysis_time_in_stages"))
                .font(AppFonts.headline())
                .foregroundStyle(AppColors.textPrimary)

            // Stacked Bar
            GeometryReader { geometry in
                HStack(spacing: 2) {
                    phaseBar(.deep, record.deepSleepDuration, geometry.size.width)
                    phaseBar(.light, record.lightSleepDuration, geometry.size.width)
                    phaseBar(.rem, record.remSleepDuration, geometry.size.width)
                    phaseBar(.awake, record.awakeDuration, geometry.size.width)
                }
            }
            .frame(height: 24)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Phase Details
            VStack(spacing: 8) {
                PhaseDetailRow(phase: .deep, duration: record.deepSleepDuration, total: record.totalDuration, isOptimal: isOptimalDeepSleep)
                PhaseDetailRow(phase: .light, duration: record.lightSleepDuration, total: record.totalDuration, isOptimal: true)
                PhaseDetailRow(phase: .rem, duration: record.remSleepDuration, total: record.totalDuration, isOptimal: isOptimalREM)
                PhaseDetailRow(phase: .awake, duration: record.awakeDuration, total: record.totalDuration, isOptimal: record.awakeDuration / record.totalDuration < 0.05)
            }
        }
    }

    // MARK: - Insights Section
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "analysis_insights"))
                .font(AppFonts.headline())
                .foregroundStyle(AppColors.textPrimary)

            VStack(spacing: 8) {
                if record.qualityScore >= 85 {
                    InsightRow(
                        icon: "star.fill",
                        text: String(localized: "insight_excellent_night"),
                        color: AppColors.success
                    )
                }

                if !isOptimalDuration {
                    InsightRow(
                        icon: "clock.badge.exclamationmark",
                        text: record.totalHours < 7
                            ? String(localized: "insight_sleep_more")
                            : String(localized: "insight_sleep_less"),
                        color: AppColors.warning
                    )
                }

                if !isOptimalDeepSleep {
                    InsightRow(
                        icon: "moon.zzz",
                        text: record.deepSleepPercentage < 15
                            ? String(localized: "insight_low_deep_sleep")
                            : String(localized: "insight_high_deep_sleep"),
                        color: AppColors.deepSleep
                    )
                }

                if sleepEfficiency < 85 {
                    InsightRow(
                        icon: "bed.double",
                        text: String(localized: "insight_improve_efficiency"),
                        color: AppColors.warning
                    )
                }
            }
        }
    }

    // MARK: - Helper Views
    private func phaseBar(_ phase: SleepPhase, _ duration: TimeInterval, _ totalWidth: CGFloat) -> some View {
        let percentage = record.totalDuration > 0 ? duration / record.totalDuration : 0
        return Rectangle()
            .fill(phase.color)
            .frame(width: max(totalWidth * percentage, 4))
    }

    // MARK: - Helper Methods
    private func stageValue(_ phase: SleepPhase) -> Int {
        switch phase {
        case .deep: return 1
        case .light: return 2
        case .rem: return 3
        case .awake: return 4
        }
    }

    private func stageLabel(_ value: Int) -> String {
        switch value {
        case 1: return String(localized: "stage_deep")
        case 2: return String(localized: "stage_light")
        case 3: return String(localized: "stage_rem")
        case 4: return String(localized: "stage_awake")
        default: return ""
        }
    }
}

// MARK: - Metric Card
struct MetricCard: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundStyle(color)

                Text(title)
                    .font(AppFonts.caption())
                    .foregroundStyle(AppColors.textSecondary)
            }

            Text(value)
                .font(AppFonts.title2())
                .fontWeight(.bold)
                .foregroundStyle(AppColors.textPrimary)

            Text(subtitle)
                .font(AppFonts.caption2())
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(AppColors.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

// MARK: - Phase Detail Row
struct PhaseDetailRow: View {
    let phase: SleepPhase
    let duration: TimeInterval
    let total: TimeInterval
    let isOptimal: Bool

    private var percentage: Double {
        total > 0 ? (duration / total) * 100 : 0
    }

    var body: some View {
        HStack(spacing: 12) {
            // Phase indicator
            Circle()
                .fill(phase.color)
                .frame(width: 10, height: 10)

            // Phase name
            Text(phase.localizedName)
                .font(AppFonts.subheadline())
                .foregroundStyle(AppColors.textPrimary)
                .frame(width: 80, alignment: .leading)

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(AppColors.surfaceSecondary)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(phase.color)
                        .frame(width: geometry.size.width * (percentage / 100))
                }
            }
            .frame(height: 8)

            // Values
            VStack(alignment: .trailing, spacing: 2) {
                Text(duration.hoursMinutesString)
                    .font(AppFonts.subheadline())
                    .fontWeight(.medium)
                    .foregroundStyle(AppColors.textPrimary)

                Text(String(format: "%.0f%%", percentage))
                    .font(AppFonts.caption2())
                    .foregroundStyle(isOptimal ? AppColors.success : AppColors.textTertiary)
            }
            .frame(width: 60, alignment: .trailing)
        }
    }
}

// MARK: - Insight Row
struct InsightRow: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(color)
                .frame(width: 32, height: 32)
                .background(color.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            Text(text)
                .font(AppFonts.subheadline())
                .foregroundStyle(AppColors.textPrimary)

            Spacer()
        }
        .padding(12)
        .background(AppColors.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

