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
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Source badge — this screen analyzes Soninho's own tracking.
                    sourceBadge

                    // Period Picker
                    periodPicker

                    if viewModel.isLoading {
                        LoadingView()
                            .frame(height: 400)
                    } else if viewModel.records.isEmpty {
                        trackerEmptyState
                    } else {
                        // Overview Card
                        overviewCard

                        // Sleep Goal Progress
                        sleepGoalSection

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
                .padding(.bottom, AppSpacing.lg)
            }
            .background(AppColors.background)
            .navigationTitle(String(localized: "stats_title"))
            .navigationBarTitleDisplayMode(.large)
            .task {
                await viewModel.loadData()
            }
        }
    }

    // MARK: - Source Badge
    private var sourceBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: "moon.zzz.fill")
                .font(.system(size: 10, weight: .semibold))
            Text(String(localized: "stats_source_badge"))
                .font(AppFonts.caption())
        }
        .foregroundStyle(AppColors.accent)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(AppColors.accent.opacity(0.15))
        .clipShape(Capsule())
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Tracker Empty State
    private var trackerEmptyState: some View {
        EmptyStateView(
            icon: "moon.zzz.fill",
            title: String(localized: "stats_tracker_empty_title"),
            message: String(localized: "stats_tracker_empty_message"),
            actionTitle: String(localized: "stats_tracker_empty_action"),
            action: { startTracking() }
        )
        .frame(minHeight: 440)
    }

    private func startTracking() {
        NotificationCenter.default.post(name: .didRequestSwitchToSleepTab, object: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            NotificationCenter.default.post(name: .didRequestStartSleepTracking, object: nil)
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
                        .foregroundStyle(AppColors.textSecondary)

                    HStack(alignment: .lastTextBaseline, spacing: 4) {
                        Text("\(viewModel.averageQuality)")
                            .font(AppFonts.number(48))
                            .foregroundStyle(SleepQuality(score: viewModel.averageQuality).color)

                        Text(String(localized: "stats_score_max"))
                            .font(AppFonts.headline())
                            .foregroundStyle(AppColors.textTertiary)
                    }

                    HStack(spacing: 4) {
                        Image(systemName: viewModel.sleepTrend.icon)
                            .font(.system(size: 12, weight: .bold))

                        Text(viewModel.sleepTrend.localizedDescription)
                            .font(AppFonts.caption())
                    }
                    .foregroundStyle(viewModel.sleepTrend.color)
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
                    .foregroundStyle(color)

                Text(title)
                    .font(AppFonts.caption())
                    .foregroundStyle(AppColors.textSecondary)
            }

            Text(value)
                .font(AppFonts.title2())
                .foregroundStyle(AppColors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Sleep Goal Section
    private var sleepGoalSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(String(localized: "stats_sleep_goal"))
                    .font(AppFonts.headline())
                    .foregroundStyle(AppColors.textPrimary)

                Spacer()

                Text(String(localized: "stats_goal_hours \(Int(viewModel.sleepGoalHours))"))
                    .font(AppFonts.caption())
                    .foregroundStyle(AppColors.textSecondary)
            }

            VStack(spacing: 16) {
                // Progress Ring
                HStack(spacing: 20) {
                    // Circular Progress
                    ZStack {
                        Circle()
                            .stroke(AppColors.surfaceTertiary, lineWidth: 8)
                            .frame(width: 80, height: 80)

                        Circle()
                            .trim(from: 0, to: viewModel.sleepGoalProgress)
                            .stroke(
                                AppColors.success,
                                style: StrokeStyle(lineWidth: 8, lineCap: .round)
                            )
                            .frame(width: 80, height: 80)
                            .rotationEffect(.degrees(-90))

                        VStack(spacing: 0) {
                            Text("\(Int(viewModel.sleepGoalProgress * 100))%")
                                .font(AppFonts.headline())
                                .foregroundStyle(AppColors.textPrimary)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(String(localized: "stats_avg_vs_goal"))
                                .font(AppFonts.caption())
                                .foregroundStyle(AppColors.textSecondary)

                            Text("\(viewModel.averageDuration) / \(Int(viewModel.sleepGoalHours))h")
                                .font(AppFonts.title3())
                                .foregroundStyle(AppColors.textPrimary)
                        }

                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(AppColors.success)
                                .font(.system(size: 14))

                            Text(String(localized: "stats_days_met_goal \(viewModel.daysMetGoal) \(viewModel.totalDaysTracked)"))
                                .font(AppFonts.caption())
                                .foregroundStyle(AppColors.textSecondary)
                        }
                    }

                    Spacer()
                }
            }
            .cardStyle()
        }
    }

    // MARK: - Duration Chart Section
    private var durationChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "stats_sleep_duration"))
                .font(AppFonts.headline())
                .foregroundStyle(AppColors.textPrimary)

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
            RuleMark(y: .value("Goal", viewModel.sleepGoalHours))
                .foregroundStyle(AppColors.textTertiary)
                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisValueLabel {
                    Text("\(value.as(Double.self) ?? 0, specifier: "%.0f")h")
                        .font(AppFonts.caption2())
                        .foregroundStyle(AppColors.textSecondary)
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
            ForEach(viewModel.records.suffix(min(7, viewModel.records.count))) { record in
                VStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(record.quality.color)
                        .frame(width: 24, height: CGFloat(record.totalHours / 10.0) * 120)

                    Text(record.startTime.shortDay)
                        .font(AppFonts.caption2())
                        .foregroundStyle(AppColors.textTertiary)
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
                .foregroundStyle(AppColors.textPrimary)

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
                .foregroundStyle(phase.color)
                .frame(width: 40, height: 40)
                .background(phase.color.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(phase.localizedName)
                    .font(AppFonts.body())
                    .foregroundStyle(AppColors.textPrimary)

                Text(description)
                    .font(AppFonts.caption())
                    .foregroundStyle(AppColors.textSecondary)
            }

            Spacer()

            Text(duration)
                .font(AppFonts.headline())
                .foregroundStyle(phase.color)
        }
    }

    // MARK: - Schedule Section
    private var scheduleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "stats_sleep_schedule"))
                .font(AppFonts.headline())
                .foregroundStyle(AppColors.textPrimary)

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
                .foregroundStyle(color)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppFonts.caption())
                    .foregroundStyle(AppColors.textSecondary)

                Text(value)
                    .font(AppFonts.title2())
                    .foregroundStyle(AppColors.textPrimary)
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
                .foregroundStyle(AppColors.textPrimary)

            ForEach(viewModel.records) { record in
                NavigationLink {
                    SleepDetailView(record: record)
                } label: {
                    historyRow(record)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func historyRow(_ record: SleepRecord) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(record.startTime.mediumDateString)
                    .font(AppFonts.body())
                    .foregroundStyle(AppColors.textPrimary)

                Text("\(record.startTime.timeString) - \(record.endTime.timeString)")
                    .font(AppFonts.caption())
                    .foregroundStyle(AppColors.textSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(record.durationString)
                    .font(AppFonts.body())
                    .foregroundStyle(AppColors.textPrimary)

                SleepScoreBadge(score: record.qualityScore)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppColors.textTertiary)
        }
        .padding()
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Sleep Detail View
struct SleepDetailView: View {
    // MARK: - Properties
    let record: SleepRecord
    @Environment(\.dismiss) private var dismiss
    @State private var showingDeleteConfirmation = false

    // MARK: - View Body
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                SleepAnalysisCard(record: record)

                // Delete button
                Button {
                    showingDeleteConfirmation = true
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "trash")
                        Text(String(localized: "stats_delete_record"))
                    }
                    .font(AppFonts.subheadline())
                    .foregroundStyle(AppColors.error)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(AppColors.error.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal, AppSpacing.screenHorizontal)
            .padding(.bottom, AppSpacing.lg)
        }
        .background(AppColors.background)
        .navigationTitle(record.startTime.mediumDateString)
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            String(localized: "stats_delete_title"),
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button(String(localized: "stats_delete_confirm"), role: .destructive) {
                StorageService.shared.deleteSleepRecord(record)
                dismiss()
            }
            Button(String(localized: "stats_delete_cancel"), role: .cancel) {}
        } message: {
            Text(String(localized: "stats_delete_message"))
        }
    }
}