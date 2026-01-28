//
//  HomeView.swift
//  soninho
//
//  Created by João Flores on 28/01/26.
//

import SwiftUI

// MARK: - Home View
struct HomeView: View {
    // MARK: - Properties
    @StateObject private var viewModel = HomeViewModel()
    @State private var showingPaywall = false
    @State private var showingSleepDetail = false
    @State private var selectedRecord: SleepRecord?

    // MARK: - Environment
    @EnvironmentObject private var storageService: StorageService

    // MARK: - View Body
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    headerSection

                    if viewModel.isLoading {
                        loadingSection
                    } else if viewModel.hasSleepData {
                        // Today's Sleep Summary
                        if let todaySleep = viewModel.todaySleep {
                            todaySleepCard(todaySleep)
                        }

                        // Quick Stats
                        quickStatsSection

                        // Weekly Overview
                        weeklyOverviewSection

                        // Sleep Quality Insights
                        insightsSection
                    } else {
                        emptyStateSection
                    }
                }
                .padding(.horizontal, AppSpacing.screenHorizontal)
                .padding(.bottom, 16)
            }
            .background(AppColors.background)
            .navigationBarTitleDisplayMode(.inline)
            .refreshable {
                await viewModel.refresh()
            }
            .task {
                await viewModel.loadData()
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
            .sheet(item: $selectedRecord) { record in
                SleepDetailSheet(record: record)
            }
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.greeting)
                    .font(AppFonts.subheadline())
                    .foregroundColor(AppColors.textSecondary)

                Text(String(localized: "home_title"))
                    .font(AppFonts.title())
                    .foregroundColor(AppColors.textPrimary)
            }

            Spacer()

            // Premium Badge or Upgrade Button (only show when purchases enabled)
            if AppConstants.isPurchasesEnabled && !storageService.isPremiumUser {
                SmallButton(title: "PRO", icon: "crown.fill") {
                    showingPaywall = true
                }
            }
        }
        .padding(.top, 16)
    }

    // MARK: - Loading Section
    private var loadingSection: some View {
        VStack(spacing: 16) {
            ShimmerCard()
            ShimmerCard()
            ShimmerCard()
        }
    }

    // MARK: - Today's Sleep Card
    private func todaySleepCard(_ record: SleepRecord) -> some View {
        Button {
            HapticManager.lightImpact()
            selectedRecord = record
        } label: {
            VStack(spacing: 20) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(String(localized: "home_last_night"))
                            .font(AppFonts.subheadline())
                            .foregroundColor(AppColors.textSecondary)

                        Text(record.durationString)
                            .font(AppFonts.title())
                            .foregroundColor(AppColors.textPrimary)

                        Text("\(record.startTime.timeString) - \(record.endTime.timeString)")
                            .font(AppFonts.caption())
                            .foregroundColor(AppColors.textTertiary)
                    }

                    Spacer()

                    SleepScoreRing(score: record.qualityScore, size: 100, lineWidth: 10)
                }

                // Phase Distribution
                SleepPhaseDistribution(
                    deepSleep: record.deepSleepDuration,
                    lightSleep: record.lightSleepDuration,
                    remSleep: record.remSleepDuration,
                    awakeDuration: record.awakeDuration
                )
            }
            .cardStyle()
        }
        .buttonStyle(.plain)
    }

    // MARK: - Quick Stats Section
    private var quickStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "home_weekly_average"))
                .font(AppFonts.headline())
                .foregroundColor(AppColors.textPrimary)

            HStack(spacing: 12) {
                StatCard(
                    title: String(localized: "stat_avg_sleep"),
                    value: viewModel.averageSleepDuration,
                    icon: "moon.fill",
                    iconColor: AppColors.primary,
                    trend: viewModel.sleepTrend
                )

                StatCard(
                    title: String(localized: "stat_avg_bedtime"),
                    value: viewModel.averageBedtime,
                    icon: "bed.double.fill",
                    iconColor: AppColors.accent
                )
            }
        }
    }

    // MARK: - Weekly Overview Section
    private var weeklyOverviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(String(localized: "home_this_week"))
                    .font(AppFonts.headline())
                    .foregroundColor(AppColors.textPrimary)

                Spacer()

                NavigationLink {
                    StatisticsView()
                } label: {
                    Text(String(localized: "home_see_all"))
                        .font(AppFonts.subheadline())
                        .foregroundColor(AppColors.primary)
                }
            }

            // Weekly Bar Chart
            WeeklyBarChart(records: viewModel.weeklyRecords)
                .frame(height: 150)
                .cardStyle()
        }
    }

    // MARK: - Insights Section
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "home_insights"))
                .font(AppFonts.headline())
                .foregroundColor(AppColors.textPrimary)

            VStack(spacing: 12) {
                InsightCard(
                    icon: "lightbulb.fill",
                    title: String(localized: "insight_deep_sleep_title"),
                    message: String(localized: "insight_deep_sleep_message"),
                    color: AppColors.deepSleep
                )

                if viewModel.averageQuality < 70 {
                    InsightCard(
                        icon: "exclamationmark.triangle.fill",
                        title: String(localized: "insight_improve_title"),
                        message: String(localized: "insight_improve_message"),
                        color: AppColors.warning
                    )
                }
            }
        }
    }

    // MARK: - Empty State Section
    private var emptyStateSection: some View {
        VStack(spacing: 24) {
            NoSleepDataView {
                Task {
                    await viewModel.requestHealthKitAccess()
                }
            }
        }
    }
}

// MARK: - Weekly Bar Chart
struct WeeklyBarChart: View {
    let records: [SleepRecord]

    private var last7Days: [Date] {
        (0..<7).map { Calendar.current.date(byAdding: .day, value: -$0, to: Date())! }.reversed()
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(last7Days, id: \.self) { date in
                let record = records.first { Calendar.current.isDate($0.startTime, inSameDayAs: date) }
                let hours = record?.totalHours ?? 0
                let maxHours: Double = 10

                VStack(spacing: 4) {
                    // Bar
                    RoundedRectangle(cornerRadius: 4)
                        .fill(barColor(for: record))
                        .frame(width: 32, height: max(CGFloat(hours / maxHours) * 100, 4))

                    // Day Label
                    Text(date.shortDay)
                        .font(AppFonts.caption2())
                        .foregroundColor(date.isToday ? AppColors.primary : AppColors.textTertiary)
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func barColor(for record: SleepRecord?) -> Color {
        guard let record = record else {
            return AppColors.surfaceTertiary
        }
        return record.quality.color.opacity(0.8)
    }
}

// MARK: - Insight Card
struct InsightCard: View {
    let icon: String
    let title: String
    let message: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppFonts.subheadline())
                    .fontWeight(.medium)
                    .foregroundColor(AppColors.textPrimary)

                Text(message)
                    .font(AppFonts.caption())
                    .foregroundColor(AppColors.textSecondary)
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(AppColors.textTertiary)
        }
        .cardStyle()
    }
}

// MARK: - Sleep Detail Sheet
struct SleepDetailSheet: View {
    let record: SleepRecord
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                SleepAnalysisCard(record: record)
                    .padding()
            }
            .background(AppColors.background)
            .navigationTitle(String(localized: "detail_analysis"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(String(localized: "action_done")) {
                        dismiss()
                    }
                    .foregroundColor(AppColors.primary)
                }
            }
        }
    }
}

// MARK: - Preview
#Preview {
    HomeView()
        .environmentObject(StorageService.shared)
}
