import SwiftUI
import GambitScreenshotKit

// MARK: - Feature 1 Screen (Slot 2 — Sleep analysis detail)
//
// Faithful recreation of soninho's SleepAnalysisCard opened as a detail
// view. This is the "wow data" moment of the carousel — the screen that
// proves the app produces a serious sleep analysis, not a toy stats card.
//
// Mirrors the real component (Presentation/Common/Components/SleepAnalysisView.swift):
//   - Header card  : score ring + date + duration + bedtime → wake row
//   - Hypnogram    : step chart over 4 stages (Deep/Light/REM/Awake)
//   - Metrics grid : 2×2 (efficiency, time asleep, deep, REM)
//   - Phase rows   : stacked bar + 4 detail rows (color/name/duration/%)
//
// Sized for iPhone 6.5" canvas (414×896pt). NO ScrollView.

struct Feature1Screen: View {
    let locale: String

    // MARK: - Sample Data
    private var sample: MockSleepRecord { MockSleepData.lastNight }
    private var totalMin: Int {
        sample.deepMinutes + sample.lightMinutes + sample.remMinutes + sample.awakeMinutes
    }
    private var asleepMin: Int { totalMin - sample.awakeMinutes }
    private var efficiencyPct: Int { Int(round(Double(asleepMin) / Double(max(totalMin, 1)) * 100)) }

    // MARK: - View Body
    var body: some View {
        ZStack {
            MockTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                iOSStatusBar(foreground: .white)

                customHeader

                VStack(spacing: 14) {
                    summaryCard
                    hypnogramCard
                    metricsGrid
                    phasesCard
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)

                Spacer(minLength: 0)
            }
        }
    }

    // MARK: - Header
    private var customHeader: some View {
        HStack {
            Image(systemName: "chevron.left")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(MockTheme.primaryLight)
                .frame(width: 40, height: 40)

            Spacer()

            Text(LocalizedLabels.sleepDetailTitle[locale] ?? "Last night")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(MockTheme.textPrimary)

            Spacer()

            Image(systemName: "square.and.arrow.up")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(MockTheme.primaryLight)
                .frame(width: 40, height: 40)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    // MARK: - Summary Card (score ring + duration + bedtime/wake)
    private var summaryCard: some View {
        HStack(alignment: .center, spacing: 16) {
            scoreRing

            VStack(alignment: .leading, spacing: 6) {
                Text(LocalizedLabels.analysisDateLabel[locale] ?? "Mon, Nov 11")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(MockTheme.textSecondary)
                    .tracking(0.3)

                Text(MockFormat.duration(sample.durationHours, locale: locale))
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundStyle(MockTheme.textPrimary)

                HStack(spacing: 6) {
                    Image(systemName: "bed.double.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(MockTheme.primaryLight)
                    Text(sample.bedtime)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(MockTheme.textTertiary)

                    Image(systemName: "arrow.right")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(MockTheme.textTertiary)

                    Image(systemName: "sun.max.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(MockTheme.warning)
                    Text(sample.wake)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(MockTheme.textTertiary)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MockTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    // MARK: - Score Ring (mirrors SleepScoreRing)
    private var scoreRing: some View {
        ZStack {
            Circle()
                .stroke(MockTheme.surfaceSecondary, lineWidth: 10)
                .frame(width: 108, height: 108)

            Circle()
                .trim(from: 0, to: CGFloat(sample.qualityScore) / 100)
                .stroke(
                    AngularGradient(
                        colors: [MockTheme.success, MockTheme.success.opacity(0.7)],
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .frame(width: 108, height: 108)

            VStack(spacing: 0) {
                Text("\(sample.qualityScore)")
                    .font(.system(size: 36, weight: .heavy, design: .rounded))
                    .foregroundStyle(MockTheme.textPrimary)
                Text(LocalizedLabels.qualityExcellent[locale] ?? "Excellent")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(MockTheme.success)
            }
        }
    }

    // MARK: - Hypnogram Card (sleep stages chart)
    private var hypnogramCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(LocalizedLabels.analysisStages[locale] ?? "Sleep stages")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(MockTheme.textPrimary)

            hypnogramChart
                .frame(height: 130)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MockTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    /// Manually-drawn step hypnogram. Mirrors the iOS-17 Charts `LineMark`
    /// + `AreaMark` with `.stepEnd` interpolation in the real app, but
    /// done as `Path` so it renders through macOS ImageRenderer.
    private var hypnogramChart: some View {
        let points = MockHypnogram.lastNight
        // Stage values: 1=Deep (bottom), 2=Light, 3=REM, 4=Awake (top)
        // We want Awake at top, so visually invert: y = (4 - stage) / 3
        let stageLabels: [(Int, String, Color)] = [
            (4, LocalizedLabels.phaseAwake[locale] ?? "Awake", MockTheme.awake),
            (3, LocalizedLabels.phaseREM[locale] ?? "REM", MockTheme.remSleep),
            (2, LocalizedLabels.phaseLight[locale] ?? "Light", MockTheme.lightSleep),
            (1, LocalizedLabels.phaseDeep[locale] ?? "Deep", MockTheme.deepSleep)
        ]

        return HStack(alignment: .top, spacing: 8) {
            // Y-axis labels
            VStack(alignment: .trailing, spacing: 0) {
                ForEach(stageLabels, id: \.0) { _, label, color in
                    HStack(spacing: 4) {
                        Text(label)
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(color)
                    }
                    .frame(maxHeight: .infinity, alignment: .center)
                }
            }
            .frame(width: 42)

            // Chart area
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height

                ZStack {
                    // Gridlines (4 rows for 4 stages)
                    VStack(spacing: 0) {
                        ForEach(0..<4, id: \.self) { _ in
                            Rectangle()
                                .fill(MockTheme.surfaceSecondary.opacity(0.5))
                                .frame(height: 0.5)
                                .frame(maxHeight: .infinity, alignment: .top)
                        }
                    }

                    // Filled area under step path
                    hypnogramAreaPath(points: points, w: w, h: h)
                        .fill(
                            LinearGradient(
                                colors: [
                                    MockTheme.primary.opacity(0.32),
                                    MockTheme.primary.opacity(0.04)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )

                    // Step line
                    hypnogramLinePath(points: points, w: w, h: h)
                        .stroke(
                            LinearGradient(
                                colors: [MockTheme.primaryLight, MockTheme.accentSecondary],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round)
                        )
                }
            }
        }
    }

    /// Build a step-end line path. Y is inverted so stage 4 (Awake) is at top.
    private func hypnogramLinePath(points: [MockHypnogramPoint], w: CGFloat, h: CGFloat) -> Path {
        Path { path in
            guard let first = points.first else { return }
            path.move(to: stagePoint(first, w: w, h: h))
            for i in 1..<points.count {
                // step end: hold previous y, then jump to new y
                let prev = points[i - 1]
                let cur = points[i]
                let curX = CGFloat(cur.t) * w
                let prevY = stageY(prev.stage, h: h)
                let curY = stageY(cur.stage, h: h)
                path.addLine(to: CGPoint(x: curX, y: prevY))
                path.addLine(to: CGPoint(x: curX, y: curY))
            }
        }
    }

    private func hypnogramAreaPath(points: [MockHypnogramPoint], w: CGFloat, h: CGFloat) -> Path {
        Path { path in
            guard let first = points.first else { return }
            let startPt = stagePoint(first, w: w, h: h)
            path.move(to: CGPoint(x: 0, y: h))
            path.addLine(to: startPt)
            for i in 1..<points.count {
                let prev = points[i - 1]
                let cur = points[i]
                let curX = CGFloat(cur.t) * w
                let prevY = stageY(prev.stage, h: h)
                let curY = stageY(cur.stage, h: h)
                path.addLine(to: CGPoint(x: curX, y: prevY))
                path.addLine(to: CGPoint(x: curX, y: curY))
            }
            path.addLine(to: CGPoint(x: w, y: h))
            path.closeSubpath()
        }
    }

    private func stagePoint(_ p: MockHypnogramPoint, w: CGFloat, h: CGFloat) -> CGPoint {
        CGPoint(x: CGFloat(p.t) * w, y: stageY(p.stage, h: h))
    }

    /// Maps stage 1..4 to y. Awake (4) at top (small y), Deep (1) at bottom.
    /// Padded so the line never touches the chart edges.
    private func stageY(_ stage: Int, h: CGFloat) -> CGFloat {
        // Stage 4 → 0.10*h, Stage 3 → 0.36*h, Stage 2 → 0.62*h, Stage 1 → 0.88*h
        let normalized = CGFloat(4 - stage) / 3.0
        return 0.10 * h + normalized * 0.78 * h
    }

    // MARK: - Metrics Grid (2×2)
    private var metricsGrid: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                metricCard(
                    icon: "percent",
                    title: LocalizedLabels.metricEfficiency[locale] ?? "Efficiency",
                    value: "\(efficiencyPct)%",
                    subtitle: LocalizedLabels.metricOptimal[locale] ?? "Optimal",
                    color: MockTheme.success
                )
                metricCard(
                    icon: "clock.fill",
                    title: LocalizedLabels.metricTimeAsleep[locale] ?? "Time asleep",
                    value: durationLabel(minutes: asleepMin),
                    subtitle: LocalizedLabels.metricIdealRange[locale] ?? "Ideal range",
                    color: MockTheme.success
                )
            }
            HStack(spacing: 10) {
                metricCard(
                    icon: "moon.zzz.fill",
                    title: LocalizedLabels.metricDeepSleep[locale] ?? "Deep sleep",
                    value: durationLabel(minutes: sample.deepMinutes),
                    subtitle: "\(pct(sample.deepMinutes))% \(LocalizedLabels.metricOfTotal[locale] ?? "of total")",
                    color: MockTheme.deepSleep
                )
                metricCard(
                    icon: "sparkles",
                    title: LocalizedLabels.metricRemSleep[locale] ?? "REM sleep",
                    value: durationLabel(minutes: sample.remMinutes),
                    subtitle: "\(pct(sample.remMinutes))% \(LocalizedLabels.metricOfTotal[locale] ?? "of total")",
                    color: MockTheme.remSleep
                )
            }
        }
    }

    private func metricCard(icon: String, title: String, value: String, subtitle: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(color)
                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(MockTheme.textSecondary)
            }

            Text(value)
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundStyle(MockTheme.textPrimary)

            Text(subtitle)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(MockTheme.surfaceSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    // MARK: - Phases Card (stacked bar + 4 phase detail rows)
    private var phasesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(LocalizedLabels.analysisTimeInStages[locale] ?? "Time in stages")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(MockTheme.textPrimary)

            phaseStackedBar

            VStack(spacing: 8) {
                phaseDetailRow(color: MockTheme.deepSleep,
                               name: LocalizedLabels.phaseDeep[locale] ?? "Deep",
                               minutes: sample.deepMinutes)
                phaseDetailRow(color: MockTheme.lightSleep,
                               name: LocalizedLabels.phaseLight[locale] ?? "Light",
                               minutes: sample.lightMinutes)
                phaseDetailRow(color: MockTheme.remSleep,
                               name: LocalizedLabels.phaseREM[locale] ?? "REM",
                               minutes: sample.remMinutes)
                phaseDetailRow(color: MockTheme.awake,
                               name: LocalizedLabels.phaseAwake[locale] ?? "Awake",
                               minutes: sample.awakeMinutes)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MockTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

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

    private func phaseDetailRow(color: Color, name: String, minutes: Int) -> some View {
        let percentage = pct(minutes)
        let progress = CGFloat(minutes) / CGFloat(max(totalMin, 1))
        return HStack(spacing: 10) {
            Circle()
                .fill(color)
                .frame(width: 9, height: 9)

            Text(name)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(MockTheme.textPrimary)
                .frame(width: 64, alignment: .leading)

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(MockTheme.surfaceSecondary)
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: geo.size.width * progress)
                }
            }
            .frame(height: 6)

            Text(durationLabel(minutes: minutes))
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(MockTheme.textPrimary)
                .frame(width: 50, alignment: .trailing)

            Text("\(percentage)%")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(color)
                .frame(width: 34, alignment: .trailing)
        }
    }

    // MARK: - Helpers
    private func pct(_ minutes: Int) -> Int {
        Int(round(Double(minutes) / Double(max(totalMin, 1)) * 100))
    }

    private func durationLabel(minutes: Int) -> String {
        let h = minutes / 60
        let m = minutes % 60
        if h > 0 {
            return "\(h)h \(String(format: "%02d", m))m"
        } else {
            return "\(m)m"
        }
    }
}
