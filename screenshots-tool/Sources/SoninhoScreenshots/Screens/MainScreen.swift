import SwiftUI
import GambitScreenshotKit

// MARK: - Main Screen (Slot 1 — Home: today's sleep analysis + stats + weekly chart)
//
// Faithful recreation of soninho HomeView for the App Store marketing
// carousel. Mirrors the real app: greeting header → today's sleep analysis
// card (score ring + duration + bedtime/wake + stacked phase bar) →
// quick stats row → weekly bar chart with "See all".
//
// Designed for iPhone 6.5" canvas (414×896pt). NO ScrollView — everything
// fits naturally in ~852pt after the status bar.

struct MainScreen: View {
    let locale: String

    // MARK: - Sample Data
    private var sample: MockSleepRecord { MockSleepData.lastNight }
    private var totalMin: Int {
        sample.deepMinutes + sample.lightMinutes + sample.remMinutes + sample.awakeMinutes
    }

    // MARK: - View Body
    var body: some View {
        ZStack {
            MockTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                iOSStatusBar(foreground: .white)

                header

                VStack(spacing: 14) {
                    todaySleepCard
                    quickStatsRow
                    weeklyChartCard
                    insightsSection
                }
                .padding(.horizontal, 16)
                .padding(.top, 6)

                Spacer(minLength: 0)
            }

            // Floating "Start night" CTA — mirrors HomeView.startSleepButton
            VStack {
                Spacer()
                startNightButton
                    .padding(.horizontal, 20)
                    .padding(.bottom, 28)
            }
        }
    }

    // MARK: - Insights Section (mirrors HomeView.insightsSection)
    private var insightsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(LocalizedLabels.homeInsightsTitle[locale] ?? "Sleep insights")
                .font(.system(size: 17, weight: .bold))
                .foregroundStyle(MockTheme.textPrimary)

            insightCard(
                icon: "lightbulb.fill",
                tint: MockTheme.deepSleep,
                title: LocalizedLabels.homeInsightTitle[locale] ?? "Healthy deep sleep",
                message: LocalizedLabels.homeInsightBody[locale] ?? "You averaged 1h 32m of deep sleep — within the recommended range."
            )
        }
    }

    private func insightCard(icon: String, tint: Color, title: String, message: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(tint.opacity(0.18))
                    .frame(width: 38, height: 38)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(tint)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(MockTheme.textPrimary)
                Text(message)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(MockTheme.textSecondary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MockTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Start Night Button (floating bottom CTA)
    private var startNightButton: some View {
        HStack(spacing: 10) {
            Image(systemName: "moon.zzz.fill")
                .font(.system(size: 17, weight: .semibold))
            Text(LocalizedLabels.homeStartNight[locale] ?? "Start tonight's sleep")
                .font(.system(size: 16, weight: .semibold))
        }
        .frame(maxWidth: .infinity)
        .frame(height: 54)
        .foregroundStyle(.white)
        .background(MockTheme.primary)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    // MARK: - Header (greeting + large title)
    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 2) {
                Text(LocalizedLabels.homeGreeting[locale] ?? "Good morning, João")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(MockTheme.textSecondary)

                Text(homeTitle)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(MockTheme.textPrimary)
            }

            Spacer()

            // Streak chip
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                Text("14")
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                Capsule().fill(
                    LinearGradient(
                        colors: [Color(red: 1.00, green: 0.42, blue: 0.21),
                                 Color(red: 0.97, green: 0.58, blue: 0.12)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            )
            .padding(.top, 6)
        }
        .padding(.horizontal, 20)
        .padding(.top, 6)
        .padding(.bottom, 10)
    }

    private var homeTitle: String {
        switch locale {
        case "pt-BR": return "Início"
        case "es-ES", "es-MX": return "Inicio"
        default: return "Home"
        }
    }

    // MARK: - Today's Sleep Analysis Card
    //
    // Mirrors SleepAnalysisCard from the real app:
    //   - 100pt score ring + duration + bedtime → wake line
    //   - Stacked phase bar (deep/light/rem/awake)
    //   - Inline phase legend with minutes
    private var todaySleepCard: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Title row
            HStack {
                Text(LocalizedLabels.homeTodaySleep[locale] ?? "Today's sleep")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(MockTheme.textPrimary)
                Spacer()
                Text(LocalizedLabels.homeTodayDate[locale] ?? "Today")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(MockTheme.textTertiary)
            }

            // Score ring + summary
            HStack(alignment: .center, spacing: 18) {
                scoreRing

                VStack(alignment: .leading, spacing: 6) {
                    Text(MockFormat.duration(sample.durationHours, locale: locale))
                        .font(.system(size: 26, weight: .heavy, design: .rounded))
                        .foregroundStyle(MockTheme.textPrimary)

                    HStack(spacing: 6) {
                        Image(systemName: "bed.double.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(MockTheme.primaryLight)
                        Text(sample.bedtime)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(MockTheme.textSecondary)

                        Image(systemName: "arrow.right")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(MockTheme.textTertiary)

                        Image(systemName: "sun.max.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(MockTheme.warning)
                        Text(sample.wake)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(MockTheme.textSecondary)
                    }

                    // Efficiency chip
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 10, weight: .bold))
                        Text(efficiencyText)
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundStyle(MockTheme.success)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(MockTheme.success.opacity(0.15)))
                }

                Spacer(minLength: 0)
            }

            // Stacked phase bar
            phaseStackedBar

            // Phase legend (compact 4-column grid)
            phaseLegendRow
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MockTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: - Score Ring
    private var scoreRing: some View {
        ZStack {
            Circle()
                .stroke(MockTheme.surfaceSecondary, lineWidth: 9)
                .frame(width: 96, height: 96)

            Circle()
                .trim(from: 0, to: CGFloat(sample.qualityScore) / 100)
                .stroke(
                    AngularGradient(
                        colors: [MockTheme.primary, MockTheme.accent, MockTheme.primaryLight],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 9, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: 96, height: 96)

            VStack(spacing: 0) {
                Text("\(sample.qualityScore)")
                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                    .foregroundStyle(MockTheme.textPrimary)
                Text(LocalizedLabels.sleepScore[locale] ?? "Score")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(MockTheme.textSecondary)
                    .tracking(0.4)
            }
        }
    }

    private var efficiencyText: String {
        switch locale {
        case "pt-BR": return "92% eficiência"
        case "es-ES", "es-MX": return "92% eficiencia"
        default: return "92% efficiency"
        }
    }

    // MARK: - Stacked Phase Bar
    private var phaseStackedBar: some View {
        GeometryReader { geo in
            HStack(spacing: 2) {
                phaseSegment(width: geo.size.width, minutes: sample.deepMinutes, color: MockTheme.deepSleep)
                phaseSegment(width: geo.size.width, minutes: sample.lightMinutes, color: MockTheme.lightSleep)
                phaseSegment(width: geo.size.width, minutes: sample.remMinutes, color: MockTheme.remSleep)
                phaseSegment(width: geo.size.width, minutes: sample.awakeMinutes, color: MockTheme.awake)
            }
        }
        .frame(height: 18)
        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }

    private func phaseSegment(width: CGFloat, minutes: Int, color: Color) -> some View {
        let total = max(totalMin, 1)
        return color.frame(width: width * CGFloat(minutes) / CGFloat(total))
    }

    // MARK: - Phase Legend (compact 4-column row)
    private var phaseLegendRow: some View {
        HStack(spacing: 10) {
            phaseChip(color: MockTheme.deepSleep,
                      name: LocalizedLabels.phaseDeep[locale] ?? "Deep",
                      minutes: sample.deepMinutes)
            phaseChip(color: MockTheme.lightSleep,
                      name: LocalizedLabels.phaseLight[locale] ?? "Light",
                      minutes: sample.lightMinutes)
            phaseChip(color: MockTheme.remSleep,
                      name: LocalizedLabels.phaseREM[locale] ?? "REM",
                      minutes: sample.remMinutes)
            phaseChip(color: MockTheme.awake,
                      name: LocalizedLabels.phaseAwake[locale] ?? "Awake",
                      minutes: sample.awakeMinutes)
        }
    }

    private func phaseChip(color: Color, name: String, minutes: Int) -> some View {
        let h = minutes / 60
        let m = minutes % 60
        let value = h > 0 ? "\(h)h \(String(format: "%02d", m))" : "\(m)m"
        return VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 5) {
                Circle()
                    .fill(color)
                    .frame(width: 7, height: 7)
                Text(name)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(MockTheme.textSecondary)
            }
            Text(value)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(MockTheme.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(MockTheme.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    // MARK: - Quick Stats Row (avg sleep + avg bedtime)
    private var quickStatsRow: some View {
        HStack(spacing: 12) {
            statCard(
                icon: "moon.fill",
                tint: MockTheme.primary,
                title: LocalizedLabels.homeAvgSleep[locale] ?? "Avg sleep",
                value: MockFormat.duration(7.6, locale: locale),
                trendUp: true
            )
            statCard(
                icon: "bed.double.fill",
                tint: MockTheme.accent,
                title: LocalizedLabels.homeAvgBedtime[locale] ?? "Avg bedtime",
                value: "22:48",
                trendUp: false
            )
        }
    }

    private func statCard(icon: String, tint: Color, title: String, value: String, trendUp: Bool) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 30, height: 30)
                    .background(tint.opacity(0.15))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                Spacer()

                if trendUp {
                    HStack(spacing: 2) {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 9, weight: .bold))
                        Text(LocalizedLabels.homeTrendUp[locale] ?? "+8%")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundStyle(MockTheme.success)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundStyle(MockTheme.textPrimary)
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(MockTheme.textSecondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MockTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    // MARK: - Weekly Chart Card
    private var weeklyChartCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(LocalizedLabels.homeThisWeek[locale] ?? "This week")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(MockTheme.textPrimary)
                Spacer()
                HStack(spacing: 4) {
                    Text(LocalizedLabels.homeSeeAll[locale] ?? "See all")
                        .font(.system(size: 13, weight: .semibold))
                    Image(systemName: "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                }
                .foregroundStyle(MockTheme.primaryLight)
            }

            weekBars
                .frame(height: 140)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MockTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var weekBars: some View {
        let labels = MockSleepData.weekLabels(locale: locale)
        let values = MockSleepData.weekDurations
        let maxV = (values.max() ?? 1) + 0.5
        let todayIndex = values.count - 1  // last bar = today

        return GeometryReader { geo in
            let chartHeight = geo.size.height - 36
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(0..<values.count, id: \.self) { idx in
                    VStack(spacing: 5) {
                        Text(String(format: "%.1f", values[idx]))
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundStyle(idx == todayIndex ? MockTheme.primaryLight : MockTheme.textTertiary)

                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(barGradient(forIndex: idx, todayIndex: todayIndex))
                            .frame(width: 26, height: max(18, CGFloat(values[idx] / maxV) * chartHeight))

                        Text(labels[idx])
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(idx == todayIndex ? MockTheme.primaryLight : MockTheme.textTertiary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private func barGradient(forIndex idx: Int, todayIndex: Int) -> LinearGradient {
        let isToday = idx == todayIndex
        let isPeak = idx == 5
        if isToday {
            return LinearGradient(
                colors: [MockTheme.accent, MockTheme.accentSecondary],
                startPoint: .bottom,
                endPoint: .top
            )
        }
        if isPeak {
            return LinearGradient(
                colors: [MockTheme.primaryDark, MockTheme.primary],
                startPoint: .bottom,
                endPoint: .top
            )
        }
        return LinearGradient(
            colors: [MockTheme.primary.opacity(0.85), MockTheme.primaryLight.opacity(0.95)],
            startPoint: .bottom,
            endPoint: .top
        )
    }
}
