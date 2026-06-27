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
                        // Today's Sleep Analysis (inline)
                        if let todaySleep = viewModel.todaySleep {
                            SleepAnalysisCard(record: todaySleep)
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
                .padding(.bottom, AppSpacing.lg)
            }
            .background(AppColors.background)
            .navigationTitle(String(localized: "home_title"))
            .navigationBarTitleDisplayMode(.large)
            .refreshable {
                await viewModel.refresh()
            }
            .task {
                await viewModel.loadData()
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
        }
    }

    // MARK: - Header Section
    private var headerSection: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.greeting)
                    .font(AppFonts.subheadline())
                    .foregroundStyle(AppColors.textSecondary)

                // Source badge — this screen reflects Apple Health data.
                HStack(spacing: 6) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 10, weight: .semibold))
                    Text(String(localized: "home_source_badge"))
                        .font(AppFonts.caption())
                }
                .foregroundStyle(AppColors.error)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(AppColors.error.opacity(0.15))
                .clipShape(Capsule())
            }

            Spacer()

            // Premium Badge or Upgrade Button (only show when purchases enabled)
            if AppConstants.isPurchasesEnabled && !storageService.isPremiumUser {
                SmallButton(title: String(localized: "badge_pro"), icon: "crown.fill") {
                    showingPaywall = true
                }
            }
        }
    }

    // MARK: - Loading Section
    private var loadingSection: some View {
        VStack(spacing: 16) {
            ShimmerCard()
            ShimmerCard()
            ShimmerCard()
        }
    }

    // MARK: - Quick Stats Section
    private var quickStatsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(String(localized: "home_weekly_average"))
                .font(AppFonts.headline())
                .foregroundStyle(AppColors.textPrimary)

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

            // Streak Card
            if viewModel.currentStreak > 0 {
                streakCard
            }
        }
    }

    // MARK: - Streak Card
    private var streakCard: some View {
        HStack(spacing: 16) {
            // Streak Icon with Fire Animation
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color(hex: "FF6B35"), Color(hex: "F7931E")],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)

                Image(systemName: "flame.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(String(localized: "streak_current"))
                    .font(AppFonts.subheadline())
                    .foregroundStyle(AppColors.textSecondary)

                Text(String(localized: "streak_days \(viewModel.currentStreak)"))
                    .font(AppFonts.title2())
                    .fontWeight(.bold)
                    .foregroundStyle(AppColors.textPrimary)
            }

            Spacer()

            // Longest Streak Badge
            if viewModel.longestStreak > viewModel.currentStreak {
                VStack(alignment: .trailing, spacing: 2) {
                    Text(String(localized: "streak_longest"))
                        .font(AppFonts.caption2())
                        .foregroundStyle(AppColors.textTertiary)

                    Text("\(viewModel.longestStreak)")
                        .font(AppFonts.headline())
                        .foregroundStyle(AppColors.accent)
                }
            } else if viewModel.currentStreak == viewModel.longestStreak && viewModel.currentStreak > 1 {
                // Personal best badge
                Text("🏆")
                    .font(.system(size: 28))
            }
        }
        .cardStyle()
    }

    // MARK: - Weekly Overview Section
    private var weeklyOverviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(String(localized: "home_this_week"))
                    .font(AppFonts.headline())
                    .foregroundStyle(AppColors.textPrimary)

                Spacer()

                NavigationLink {
                    StatisticsView()
                } label: {
                    Text(String(localized: "home_see_all"))
                        .font(AppFonts.subheadline())
                        .foregroundStyle(AppColors.primary)
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
                .foregroundStyle(AppColors.textPrimary)

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
        EmptyStateView(
            icon: "heart.text.square.fill",
            title: String(localized: "home_apple_empty_title"),
            message: String(localized: "home_apple_empty_message"),
            actionTitle: viewModel.isHealthKitAvailable ? String(localized: "home_apple_empty_action") : nil,
            action: viewModel.isHealthKitAvailable ? { Task { await viewModel.requestHealthKitAccess() } } : nil
        )
        .frame(minHeight: 460)
    }
}

// MARK: - Weekly Bar Chart
struct WeeklyBarChart: View {
    let records: [SleepRecord]

    private var last7Days: [Date] {
        (0..<7).compactMap { Calendar.current.date(byAdding: .day, value: -$0, to: Date()) }.reversed()
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            ForEach(last7Days, id: \.self) { date in
                // Match by wake day (endTime) — sleep that ended on this day
                let record = records.first { Calendar.current.isDate($0.endTime, inSameDayAs: date) }
                let hours = record?.totalHours ?? 0
                let maxHours: Double = 10

                VStack(spacing: 4) {
                    // Hours label
                    if hours > 0 {
                        Text(String(format: "%.1f", hours))
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(AppColors.textTertiary)
                    }

                    // Bar
                    RoundedRectangle(cornerRadius: 4)
                        .fill(barColor(for: record))
                        .frame(width: 32, height: max(CGFloat(hours / maxHours) * 100, 4))

                    // Day Label
                    Text(date.shortDay)
                        .font(AppFonts.caption2())
                        .foregroundStyle(date.isToday ? AppColors.primary : AppColors.textTertiary)
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
                .foregroundStyle(color)
                .frame(width: 40, height: 40)
                .background(color.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppFonts.subheadline())
                    .fontWeight(.medium)
                    .foregroundStyle(AppColors.textPrimary)

                Text(message)
                    .font(AppFonts.caption())
                    .foregroundStyle(AppColors.textSecondary)
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppColors.textTertiary)
        }
        .cardStyle()
    }
}
