import SwiftUI
import GambitScreenshotKit

// MARK: - Settings Screen (Slot 4 — Statistics: long-term sleep trends)
//
// Faithful recreation of soninho's StatisticsView for the App Store
// marketing carousel. NOTE: the file is named "SettingsScreen" for legacy
// reasons but the carousel renders the Statistics screen here.
//
// Mirrors the real app sections (Presentation/Statistics/Views/StatisticsView.swift):
//   - Large title + period picker (Week / Month / Year)
//   - Overview card     : score ring + avg quality + trend + quick stats (avg duration + consistency)
//   - Goal card         : progress ring + goal hours + days-met-goal
//   - Duration chart    : 30-day bar chart with goal line + value labels
//   - Phases card       : Deep / Light / REM rows (icon + name + duration)
//   - Schedule row      : Avg bedtime + Avg wake cards
//
// Sized for iPhone 6.5" canvas (414×896pt). NO ScrollView.

struct SettingsScreen: View {
    let locale: String

    // MARK: - Sample Data
    private let goalHours: Double = 8.0
    private let monthAverageScore: Int = 86
    private let consistencyPct: Int = 94
    private let daysMet: Int = 26
    private let totalDays: Int = 30

    private var averageHours: Double {
        let values = MockSleepData.monthDurations
        return values.reduce(0, +) / Double(values.count)
    }

    private var goalPercent: Double {
        min(averageHours / goalHours, 1.0)
    }

    // MARK: - View Body
    var body: some View {
        ZStack {
            MockTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                iOSStatusBar(foreground: .white)

                header

                VStack(spacing: 12) {
                    periodPicker
                    overviewCard
                    goalCard
                    durationChartCard
                    phasesCard
                    scheduleRow
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)
                .padding(.bottom, 8)

                Spacer(minLength: 0)
            }
        }
    }

    // MARK: - Header (large title)
    private var header: some View {
        HStack {
            Text(LocalizedLabels.statsTitle[locale] ?? "Statistics")
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(MockTheme.textPrimary)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 6)
        .padding(.bottom, 10)
    }

    // MARK: - Period Picker (segmented)
    private var periodPicker: some View {
        HStack(spacing: 0) {
            segment(title: LocalizedLabels.statsPeriodWeek[locale] ?? "Week", active: false)
            segment(title: LocalizedLabels.statsPeriodMonth[locale] ?? "Month", active: true)
            segment(title: LocalizedLabels.statsPeriodYear[locale] ?? "Year", active: false)
        }
        .padding(3)
        .background(MockTheme.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
    }

    private func segment(title: String, active: Bool) -> some View {
        Text(title)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(active ? MockTheme.textPrimary : MockTheme.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 7, style: .continuous)
                    .fill(active ? MockTheme.surfaceTertiary : Color.clear)
            )
    }

    // MARK: - Overview Card (avg quality + score ring + quick stats)
    private var overviewCard: some View {
        VStack(spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(LocalizedLabels.statsAverageQuality[locale] ?? "Average quality")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(MockTheme.textSecondary)

                    HStack(alignment: .lastTextBaseline, spacing: 3) {
                        Text("\(monthAverageScore)")
                            .font(.system(size: 44, weight: .heavy, design: .rounded))
                            .foregroundStyle(MockTheme.success)
                        Text("/100")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundStyle(MockTheme.textTertiary)
                    }

                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 10, weight: .bold))
                        Text(LocalizedLabels.statsTrendImproving[locale] ?? "Improving")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundStyle(MockTheme.success)
                }

                Spacer()

                miniScoreRing
            }

            Rectangle()
                .fill(MockTheme.surfaceSecondary)
                .frame(height: 1)

            HStack(spacing: 14) {
                quickStat(
                    icon: "moon.fill",
                    tint: MockTheme.primary,
                    title: LocalizedLabels.statsAvgDuration[locale] ?? "Avg duration",
                    value: MockFormat.duration(averageHours, locale: locale)
                )
                quickStat(
                    icon: "chart.line.uptrend.xyaxis",
                    tint: MockTheme.accent,
                    title: LocalizedLabels.statsConsistency[locale] ?? "Consistency",
                    value: "\(consistencyPct)%"
                )
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(MockTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var miniScoreRing: some View {
        ZStack {
            Circle()
                .stroke(MockTheme.surfaceSecondary, lineWidth: 9)
                .frame(width: 86, height: 86)

            Circle()
                .trim(from: 0, to: CGFloat(monthAverageScore) / 100)
                .stroke(
                    AngularGradient(
                        colors: [MockTheme.success, MockTheme.success.opacity(0.7)],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: 9, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: 86, height: 86)

            Text("\(monthAverageScore)")
                .font(.system(size: 26, weight: .heavy, design: .rounded))
                .foregroundStyle(MockTheme.textPrimary)
        }
    }

    private func quickStat(icon: String, tint: Color, title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(tint)
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(MockTheme.textSecondary)
            }
            Text(value)
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .foregroundStyle(MockTheme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Goal Card (progress ring + days met)
    private var goalCard: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(MockTheme.surfaceTertiary, lineWidth: 8)
                    .frame(width: 72, height: 72)
                Circle()
                    .trim(from: 0, to: CGFloat(goalPercent))
                    .stroke(
                        AngularGradient(
                            colors: [MockTheme.success, MockTheme.success.opacity(0.7)],
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 72, height: 72)
                Text("\(Int(round(goalPercent * 100)))%")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundStyle(MockTheme.textPrimary)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(LocalizedLabels.statsGoal[locale] ?? "Sleep goal")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(MockTheme.textSecondary)

                Text("\(MockFormat.duration(averageHours, locale: locale)) / \(Int(goalHours))h")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(MockTheme.textPrimary)

                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(MockTheme.success)
                    Text(LocalizedLabels.statsDaysMet[locale] ?? "26 of 30 days")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(MockTheme.textSecondary)
                }
            }

            Spacer()
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MockTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    // MARK: - Duration Chart Card (30-day bars + goal line)
    private var durationChartCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(LocalizedLabels.statsDuration[locale] ?? "Sleep duration")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(MockTheme.textPrimary)

                Spacer()

                HStack(spacing: 4) {
                    Rectangle()
                        .fill(MockTheme.textTertiary)
                        .frame(width: 10, height: 1.5)
                    Text("\(Int(goalHours))h")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .foregroundStyle(MockTheme.textTertiary)
                }
            }

            durationBars
                .frame(height: 128)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MockTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var durationBars: some View {
        let values = MockSleepData.monthDurations
        let minV: CGFloat = 5.5
        let maxV: CGFloat = 9.0

        return GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let goalY = h - h * (CGFloat(goalHours) - minV) / (maxV - minV)
            let barCount = values.count
            let spacing: CGFloat = 2
            let barWidth = (w - spacing * CGFloat(barCount - 1)) / CGFloat(barCount)

            ZStack(alignment: .topLeading) {
                // Goal dashed line
                Path { p in
                    p.move(to: CGPoint(x: 0, y: goalY))
                    p.addLine(to: CGPoint(x: w, y: goalY))
                }
                .stroke(
                    MockTheme.textTertiary.opacity(0.55),
                    style: StrokeStyle(lineWidth: 1, dash: [4, 4])
                )

                // Bars
                HStack(alignment: .bottom, spacing: spacing) {
                    ForEach(0..<barCount, id: \.self) { idx in
                        let v = CGFloat(values[idx])
                        let normalized = (v - minV) / (maxV - minV)
                        let barH = max(6, normalized * h)
                        RoundedRectangle(cornerRadius: 3, style: .continuous)
                            .fill(barGradient(value: values[idx]))
                            .frame(width: barWidth, height: barH)
                    }
                }
                .frame(width: w, height: h, alignment: .bottom)
            }
        }
    }

    private func barGradient(value: Double) -> LinearGradient {
        if value >= goalHours {
            return LinearGradient(
                colors: [MockTheme.success, MockTheme.success.opacity(0.75)],
                startPoint: .top, endPoint: .bottom
            )
        }
        if value >= goalHours - 0.7 {
            return LinearGradient(
                colors: [MockTheme.primaryLight, MockTheme.primary],
                startPoint: .top, endPoint: .bottom
            )
        }
        return LinearGradient(
            colors: [MockTheme.primary.opacity(0.85), MockTheme.primaryDark],
            startPoint: .top, endPoint: .bottom
        )
    }

    // MARK: - Phases Card (Deep / Light / REM rows)
    private var phasesCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(LocalizedLabels.statsPhases[locale] ?? "Sleep phases")
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(MockTheme.textPrimary)

            VStack(spacing: 8) {
                phaseRow(
                    icon: "moon.zzz.fill",
                    color: MockTheme.deepSleep,
                    name: LocalizedLabels.phaseDeep[locale] ?? "Deep",
                    description: LocalizedLabels.statsDeepDescription[locale] ?? "Restorative",
                    duration: "1h 32m"
                )
                phaseRow(
                    icon: "moon.fill",
                    color: MockTheme.lightSleep,
                    name: LocalizedLabels.phaseLight[locale] ?? "Light",
                    description: LocalizedLabels.statsLightDescription[locale] ?? "Most of the night",
                    duration: "3h 38m"
                )
                phaseRow(
                    icon: "sparkles",
                    color: MockTheme.remSleep,
                    name: LocalizedLabels.phaseREM[locale] ?? "REM",
                    description: LocalizedLabels.statsRemDescription[locale] ?? "Dreams & memory",
                    duration: "1h 56m"
                )
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MockTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func phaseRow(icon: String, color: Color, name: String, description: String, duration: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 34, height: 34)
                .background(color.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))

            VStack(alignment: .leading, spacing: 1) {
                Text(name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(MockTheme.textPrimary)
                Text(description)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(MockTheme.textSecondary)
            }

            Spacer()

            Text(duration)
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(color)
        }
    }

    // MARK: - Schedule Row (Avg bedtime + Avg wake)
    private var scheduleRow: some View {
        HStack(spacing: 10) {
            scheduleCard(
                icon: "bed.double.fill",
                tint: MockTheme.primary,
                title: LocalizedLabels.statsAvgBedtime[locale] ?? "Avg bedtime",
                value: "22:48"
            )
            scheduleCard(
                icon: "sunrise.fill",
                tint: MockTheme.warning,
                title: LocalizedLabels.statsAvgWake[locale] ?? "Avg wake",
                value: "06:30"
            )
        }
    }

    private func scheduleCard(icon: String, tint: Color, title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(tint)

            Text(value)
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundStyle(MockTheme.textPrimary)

            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(MockTheme.textSecondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MockTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
