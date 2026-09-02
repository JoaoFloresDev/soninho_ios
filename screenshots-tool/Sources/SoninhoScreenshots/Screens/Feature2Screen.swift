import SwiftUI
import GambitScreenshotKit

// MARK: - Feature 2 (Slot 3 — Sleep analysis with the new hypnogram)
//
// Faithful to SleepAnalysisCard: score ring, per-span colored hypnogram
// blocks with the phase legend, and the efficiency/time-asleep metric cards.

struct Feature2Screen: View {
    let locale: String
    private func L(_ en: String, _ pt: String, _ es: String) -> String {
        locale == "pt-BR" ? pt : (locale.hasPrefix("es") ? es : en)
    }

    // (stage row 1=deep 2=light 3=rem 4=awake, relative width)
    private let spans: [(stage: Int, width: CGFloat)] = [
        (4, 1.2), (2, 2.0), (1, 3.4), (2, 1.2), (3, 2.2), (1, 2.6),
        (2, 1.0), (3, 2.8), (1, 2.2), (2, 1.4), (3, 1.8), (2, 1.0), (4, 1.4),
    ]

    private func stageColor(_ s: Int) -> Color {
        switch s {
        case 1: return AppPalette.deepSleep
        case 2: return AppPalette.lightSleep
        case 3: return AppPalette.remSleep
        default: return AppPalette.awake
        }
    }

    var body: some View {
        ZStack {
            GlassBackdropMock()

            VStack(spacing: 0) {
                iOSStatusBar(foreground: .white)

                HStack {
                    Text(L("Sleep Report", "Relatório do sono", "Informe de sueño"))
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(AppPalette.textPrimary)
                    Spacer()
                }
                .padding(.horizontal, 22)
                .padding(.top, 8)

                GlassCard {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(L("Sleep score", "Nota do sono", "Puntuación"))
                                    .font(.system(size: 14))
                                    .foregroundStyle(AppPalette.textSecondary)
                                Text("86")
                                    .font(.system(size: 44, weight: .bold, design: .rounded))
                                    .foregroundStyle(AppPalette.success)
                                Text(L("7h 42min asleep", "7h 42min dormindo", "7h 42min dormido"))
                                    .font(.system(size: 14))
                                    .foregroundStyle(AppPalette.textSecondary)
                            }
                            Spacer()
                            scoreRing
                        }

                        hypnogram
                        legend
                    }
                    .padding(18)
                }
                .padding(.horizontal, 22)
                .padding(.top, 12)

                HStack(spacing: 12) {
                    metricCard(
                        icon: "percent",
                        title: L("Efficiency", "Eficiência", "Eficiencia"),
                        value: "94%",
                        color: AppPalette.success
                    )
                    metricCard(
                        icon: "moon.zzz.fill",
                        title: L("Deep sleep", "Sono profundo", "Sueño profundo"),
                        value: "1h 38m",
                        color: AppPalette.deepSleep
                    )
                }
                .padding(.horizontal, 22)
                .padding(.top, 12)

                Spacer()

                TabBarMock(activeIndex: 1)
            }
        }
    }

    private var scoreRing: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.12), lineWidth: 10)
            Circle()
                .trim(from: 0, to: 0.86)
                .stroke(
                    AngularGradient(
                        colors: [AppPalette.primary, AppPalette.primaryLight],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 10, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
            Text("86")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(AppPalette.textPrimary)
        }
        .frame(width: 88, height: 88)
    }

    private var hypnogram: some View {
        GeometryReader { geo in
            let total = spans.reduce(0) { $0 + $1.width }
            let rowHeight: CGFloat = (geo.size.height - 9) / 4
            HStack(spacing: 1) {
                ForEach(Array(spans.enumerated()), id: \.offset) { _, span in
                    VStack(spacing: 0) {
                        Spacer()
                            .frame(height: CGFloat(span.stage - 1) * (rowHeight + 3))
                        RoundedRectangle(cornerRadius: 3)
                            .fill(stageColor(span.stage))
                            .frame(height: rowHeight)
                        Spacer(minLength: 0)
                    }
                    .frame(width: max(3, (geo.size.width - CGFloat(spans.count)) * span.width / total))
                }
            }
        }
        .frame(height: 96)
    }

    private var legend: some View {
        HStack(spacing: 14) {
            legendDot(AppPalette.awake, L("Awake", "Acordado", "Despierto"))
            legendDot(AppPalette.lightSleep, L("Light", "Leve", "Ligero"))
            legendDot(AppPalette.remSleep, "REM")
            legendDot(AppPalette.deepSleep, L("Deep", "Profundo", "Profundo"))
        }
        .frame(maxWidth: .infinity)
    }

    private func legendDot(_ color: Color, _ label: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(AppPalette.textSecondary)
        }
    }

    private func metricCard(icon: String, title: String, value: String, color: Color) -> some View {
        GlassCard(cornerRadius: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(color)
                    Text(title)
                        .font(.system(size: 13))
                        .foregroundStyle(AppPalette.textSecondary)
                }
                Text(value)
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(AppPalette.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
        }
    }
}
