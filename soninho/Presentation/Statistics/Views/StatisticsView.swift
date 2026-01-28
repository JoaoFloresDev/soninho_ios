//
//  StatisticsView.swift
//  soninho
//
//  Created by João Flores on 28/01/26.
//

import SwiftUI
import Charts

// MARK: - Statistics View
struct StatisticsView: View {
    // MARK: - Properties
    @StateObject private var viewModel = StatisticsViewModel()

    // MARK: - View Body
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Period Picker
                periodPicker

                if viewModel.isLoading {
                    LoadingView()
                        .frame(height: 400)
                } else {
                    // Overview Card
                    overviewCard

                    // Sleep Duration Chart
                    durationChartSection

                    // Sleep Phases
                    phasesSection

                    // Sleep Schedule
                    scheduleSection

                    // Sleep History
                    historySection
                }
            }
            .padding(.horizontal, AppSpacing.screenHorizontal)
            .padding(.bottom, 100)
        }
        .background(AppColors.background)
        .navigationTitle(String(localized: "stats_title"))
        .task {
            await viewModel.loadData()
        }
    }

    // MARK: - Period Picker
    private var periodPicker: some View {
        Picker("", selection: $viewModel.selectedPeriod) {
            ForEach(TimePeriod.allCases) { period in
                Text(period.displayName).tag(period)
            }
        }
        .pickerStyle(.segmented)
        .onChange(of: viewModel.selectedPeriod) { _, newValue in
            viewModel.changePeriod(newValue)
        }
    }

    // MARK: - Overview Card
    private var overviewCard: some View {
        VStack(spacing: 20) {
            // Score
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(String(localized: "stats_average_quality"))
                        .font(AppFonts.subheadline())
                        .foregroundColor(AppColors.textSecondary)

                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text("\(viewModel.averageQuality)")
                            .font(AppFonts.number(48))
                            .foregroundColor(SleepQuality(score: viewModel.averageQuality).color)

                        Text("/100")
                            .font(AppFonts.headline())
                            .foregroundColor(AppColors.textTertiary)
                    }

                    HStack(spacing: 4) {
                        Image(systemName: viewModel.sleepTrend.icon)
                            .font(.system(size: 12, weight: .bold))

                        Text(viewModel.sleepTrend.localizedDescription)
                            .font(AppFonts.caption())
                    }
                    .foregroundColor(viewModel.sleepTrend.color)
                }

                Spacer()

                SleepScoreRing(score: viewModel.averageQuality, size: 100, lineWidth: 10, showLabel: false)
            }

            Divider()
                .background(AppColors.surfaceSecondary)

            // Quick Stats
            HStack(spacing: 16) {
                quickStatItem(
                    title: String(localized: "stats_avg_duration"),
                    value: viewModel.averageDuration,
                    icon: "moon.fill",
                    color: AppColors.primary
                )

                quickStatItem(
                    title: String(localized: "stats_consistency"),
                    value: "\(viewModel.consistencyScore)%",
                    icon: "chart.line.uptrend.xyaxis",
                    color: AppColors.accent
                )
            }
        }
        .cardStyle()
    }

    private func quickStatItem(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundColor(color)

                Text(title)
                    .font(AppFonts.caption())
                    .foregroundColor(AppColors.textSecondary)
            }

            Text(value)
                .font(AppFonts.title2())
                .foregroundColor(AppColors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Duration Chart Section
    private var durationChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "stats_sleep_duration"))
                .font(AppFonts.headline())
                .foregroundColor(AppColors.textPrimary)

            if #available(iOS 17.0, *) {
                sleepDurationChart
                    .frame(height: 200)
                    .cardStyle()
            } else {
                legacyDurationChart
                    .cardStyle()
            }
        }
    }

    @available(iOS 17.0, *)
    private var sleepDurationChart: some View {
        Chart {
            ForEach(viewModel.records.prefix(viewModel.selectedPeriod.days)) { record in
                BarMark(
                    x: .value("Date", record.startTime, unit: .day),
                    y: .value("Hours", record.totalHours)
                )
                .foregroundStyle(record.quality.color.gradient)
                .cornerRadius(4)
            }

            // Goal line
            RuleMark(y: .value("Goal", 8))
                .foregroundStyle(AppColors.textTertiary)
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisValueLabel {
                    Text("\(value.as(Double.self) ?? 0, specifier: "%.0f")h")
                        .font(AppFonts.caption2())
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
        .chartXAxis {
            AxisMarks { value in
                AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                    .foregroundStyle(AppColors.textTertiary)
            }
        }
    }

    private var legacyDurationChart: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(viewModel.records.prefix(7)) { record in
                VStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(record.quality.color)
                        .frame(width: 24, height: CGFloat(record.totalHours / 10.0) * 120)

                    Text(record.startTime.shortDay)
                        .font(AppFonts.caption2())
                        .foregroundColor(AppColors.textTertiary)
                }
            }
        }
        .frame(height: 150)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Phases Section
    private var phasesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "stats_sleep_phases"))
                .font(AppFonts.headline())
                .foregroundColor(AppColors.textPrimary)

            VStack(spacing: 12) {
                phaseRow(
                    phase: .deep,
                    duration: viewModel.averageDeepSleep,
                    description: String(localized: "stats_deep_description")
                )

                phaseRow(
                    phase: .light,
                    duration: viewModel.averageLightSleep,
                    description: String(localized: "stats_light_description")
                )

                phaseRow(
                    phase: .rem,
                    duration: viewModel.averageRemSleep,
                    description: String(localized: "stats_rem_description")
                )
            }
            .cardStyle()
        }
    }

    private func phaseRow(phase: SleepPhase, duration: String, description: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: phase.icon)
                .font(.system(size: 20))
                .foregroundColor(phase.color)
                .frame(width: 40, height: 40)
                .background(phase.color.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(phase.localizedName)
                    .font(AppFonts.body())
                    .foregroundColor(AppColors.textPrimary)

                Text(description)
                    .font(AppFonts.caption())
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer()

            Text(duration)
                .font(AppFonts.headline())
                .foregroundColor(phase.color)
        }
    }

    // MARK: - Schedule Section
    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "stats_sleep_schedule"))
                .font(AppFonts.headline())
                .foregroundColor(AppColors.textPrimary)

            HStack(spacing: 12) {
                scheduleCard(
                    title: String(localized: "stats_avg_bedtime"),
                    value: viewModel.averageBedtime,
                    icon: "bed.double.fill",
                    color: AppColors.primary
                )

                scheduleCard(
                    title: String(localized: "stats_avg_wake"),
                    value: viewModel.averageWakeTime,
                    icon: "sunrise.fill",
                    color: AppColors.accent
                )
            }
        }
    }

    private func scheduleCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppFonts.caption())
                    .foregroundColor(AppColors.textSecondary)

                Text(value)
                    .font(AppFonts.title2())
                    .foregroundColor(AppColors.textPrimary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    // MARK: - History Section
    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "stats_history"))
                .font(AppFonts.headline())
                .foregroundColor(AppColors.textPrimary)

            ForEach(viewModel.records.prefix(10)) { record in
                historyRow(record)
            }
        }
    }

    private func historyRow(_ record: SleepRecord) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(record.startTime.mediumDateString)
                    .font(AppFonts.body())
                    .foregroundColor(AppColors.textPrimary)

                Text("\(record.startTime.timeString) - \(record.endTime.timeString)")
                    .font(AppFonts.caption())
                    .foregroundColor(AppColors.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(record.durationString)
                    .font(AppFonts.body())
                    .foregroundColor(AppColors.textPrimary)

                SleepScoreBadge(score: record.qualityScore)
            }
        }
        .padding()
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Preview
#Preview {
    NavigationStack {
        StatisticsView()
    }
}
