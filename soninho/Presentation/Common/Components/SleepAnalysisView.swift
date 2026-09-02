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
    /// Straight from the record — this card and the Time Asleep card used to
    /// derive their own numbers (with a latency fudge and a 97% cap) and
    /// disagree side by side on the same screen.
    private var sleepEfficiency: Double {
        record.efficiency * 100
    }

    /// Fraction of the night the app was NOT observing. Above a tenth, phase
    /// advice would be judging a night the app mostly missed.
    private var gapFraction: Double {
        guard record.totalDuration > 0 else { return 0 }
        return record.gapDuration / record.totalDuration
    }

    private var isOptimalDuration: Bool {
        record.totalHours >= 7 && record.totalHours <= 9
    }

    // Bands come from the scorer, so the badge and the ring can never
    // disagree about the same percentage.
    private var isOptimalDeepSleep: Bool {
        SleepQualityScorer.deepIdealPercent.contains(record.deepSleepPercentage)
    }

    private var isOptimalREM: Bool {
        SleepQualityScorer.remIdealPercent.contains(record.remSleepPercentage)
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
        .glassSurface(cornerRadius: 20)
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

            hypnogramChart
            hypnogramLegend
        }
    }

    // MARK: - Hypnogram Chart
    /// One coloured block per staged span, on the record's own time window.
    /// The old chart drew a single-colour line with an area fill that made
    /// AWAKE the biggest filled shape and deep sleep the smallest — a good
    /// night rendered nearly empty. Gaps (app not observing) are muted, not
    /// disguised as sleep.
    private var hypnogramChart: some View {
        Chart {
            ForEach(record.phases) { span in
                RectangleMark(
                    xStart: .value("Start", max(span.startTime, record.startTime)),
                    xEnd: .value("End", min(span.endTime, record.endTime)),
                    y: .value("Stage", stageValue(span.phase))
                )
                .foregroundStyle(
                    span.isMissingData
                        ? AppColors.textTertiary.opacity(0.25)
                        : span.phase.color
                )
                .cornerRadius(2)
            }
        }
        .chartXScale(domain: record.startTime...record.endTime)
        .chartXAxis {
            AxisMarks(values: .stride(by: .hour, count: 2)) { _ in
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

    // MARK: - Hypnogram Legend
    private var hypnogramLegend: some View {
        HStack(spacing: 12) {
            ForEach(SleepPhase.allCases, id: \.self) { phase in
                HStack(spacing: 4) {
                    Circle()
                        .fill(phase.color)
                        .frame(width: 8, height: 8)
                    Text(phase.localizedName)
                        .font(.system(size: 11))
                        .foregroundStyle(AppColors.textSecondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
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
                value: record.timeAsleep.hoursMinutesString,
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
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.surfaceSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Phase Details
            VStack(spacing: 8) {
                PhaseDetailRow(phase: .deep, duration: record.deepSleepDuration, total: record.totalDuration, isOptimal: isOptimalDeepSleep)
                PhaseDetailRow(phase: .light, duration: record.lightSleepDuration, total: record.totalDuration, isOptimal: true)
                PhaseDetailRow(phase: .rem, duration: record.remSleepDuration, total: record.totalDuration, isOptimal: isOptimalREM)
                PhaseDetailRow(
                    phase: .awake,
                    duration: record.awakeDuration,
                    total: record.totalDuration,
                    isOptimal: record.totalDuration > 0
                        && record.awakeDuration / record.totalDuration < SleepQualityScorer.awakeOptimalFraction
                )
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

                // Phase advice is withheld when the app missed a chunk of the
                // night — "low deep sleep, avoid caffeine" over a data hole
                // blames the user for an iOS suspension.
                if !isOptimalDeepSleep, gapFraction < 0.1 {
                    InsightRow(
                        icon: "moon.zzz",
                        text: record.deepSleepPercentage < 15
                            ? String(localized: "insight_low_deep_sleep")
                            : String(localized: "insight_high_deep_sleep"),
                        color: AppColors.deepSleep
                    )
                }

                if sleepEfficiency < 85, gapFraction < 0.1 {
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
        // No minimum width: a phase that did not happen gets no bar, and the
        // old 4 pt floor across four segments clipped the rightmost one.
        return Rectangle()
            .fill(phase.color)
            .frame(width: percentage > 0 ? max(totalWidth * percentage, 1) : 0)
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

