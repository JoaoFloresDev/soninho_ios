import SwiftUI
import GambitScreenshotKit

// MARK: - Slot 5 — Statistics (trends, goal, phases)
//
// Faithful to StatisticsView: period picker, overview card with score +
// trend chip, week duration bars against the goal line.

struct StatsScreen: View {
    let locale: String
    private func L(_ en: String, _ pt: String, _ es: String) -> String {
        locale == "pt-BR" ? pt : (locale.hasPrefix("es") ? es : en)
    }

    private let bars: [(day: String, hours: CGFloat, good: Bool)] = [
        ("S", 6.8, false), ("M", 7.6, true), ("T", 8.1, true), ("W", 7.2, true),
        ("T", 6.4, false), ("F", 7.9, true), ("S", 8.4, true),
    ]

    var body: some View {
        ZStack {
            GlassBackdropMock()

            VStack(spacing: 0) {
                iOSStatusBar(foreground: .white)

                HStack {
                    Text(L("Statistics", "Estatísticas", "Estadísticas"))
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(AppPalette.textPrimary)
                    Spacer()
                }
                .padding(.horizontal, 22)
                .padding(.top, 8)

                periodPicker
                    .padding(.horizontal, 22)
                    .padding(.top, 10)

                GlassCard {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(L("Average quality", "Qualidade média", "Calidad media"))
                                    .font(.system(size: 14))
                                    .foregroundStyle(AppPalette.textSecondary)
                                HStack(alignment: .lastTextBaseline, spacing: 4) {
                                    Text("82")
                                        .font(.system(size: 44, weight: .bold, design: .rounded))
                                        .foregroundStyle(AppPalette.primary)
                                    Text("/100")
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundStyle(AppPalette.textTertiary)
                                }
                                GlassChip(
                                    icon: "arrow.up.right",
                                    text: L("Improving", "Melhorando", "Mejorando"),
                                    tint: AppPalette.success
                                )
                            }
                            Spacer()
                            miniRing
                        }
                    }
                    .padding(18)
                }
                .padding(.horizontal, 22)
                .padding(.top, 14)

                GlassCard {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(L("Sleep duration", "Duração do sono", "Duración del sueño"))
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(AppPalette.textPrimary)
                            Spacer()
                            Text(L("Goal 8h", "Meta 8h", "Meta 8h"))
                                .font(.system(size: 12))
                                .foregroundStyle(AppPalette.textTertiary)
                        }
                        chart
                    }
                    .padding(18)
                }
                .padding(.horizontal, 22)
                .padding(.top, 12)

                Spacer()

                TabBarMock(activeIndex: 2)
            }
        }
    }

    private var periodPicker: some View {
        HStack(spacing: 4) {
            segment(L("Week", "Semana", "Semana"), selected: true)
            segment(L("Month", "Mês", "Mes"), selected: false)
            segment(L("Year", "Ano", "Año"), selected: false)
        }
        .padding(4)
        .background(Capsule().fill(Color.white.opacity(0.08)))
    }

    private func segment(_ label: String, selected: Bool) -> some View {
        Text(label)
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(selected ? .white : AppPalette.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(
                Capsule().fill(selected ? AppPalette.primary.opacity(0.85) : .clear)
            )
    }

    private var miniRing: some View {
        ZStack {
            Circle().stroke(Color.white.opacity(0.12), lineWidth: 9)
            Circle()
                .trim(from: 0, to: 0.82)
                .stroke(AppPalette.primary, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
        .frame(width: 74, height: 74)
    }

    private var chart: some View {
        GeometryReader { geo in
            let maxH = geo.size.height - 22
            ZStack(alignment: .bottom) {
                // Goal line at 8h of a 9h scale
                VStack {
                    Spacer().frame(height: 22 + maxH * (1 - 8.0 / 9.0))
                    Line()
                        .stroke(AppPalette.textTertiary, style: StrokeStyle(lineWidth: 1, dash: [5, 5]))
                        .frame(height: 1)
                    Spacer()
                }
                HStack(alignment: .bottom, spacing: 10) {
                    ForEach(Array(bars.enumerated()), id: \.offset) { _, bar in
                        VStack(spacing: 6) {
                            RoundedRectangle(cornerRadius: 5)
                                .fill(
                                    LinearGradient(
                                        colors: bar.good
                                            ? [AppPalette.primaryLight, AppPalette.primary]
                                            : [AppPalette.primary.opacity(0.45), AppPalette.primary.opacity(0.3)],
                                        startPoint: .top, endPoint: .bottom
                                    )
                                )
                                .frame(height: maxH * bar.hours / 9.0)
                            Text(bar.day)
                                .font(.system(size: 11))
                                .foregroundStyle(AppPalette.textTertiary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .frame(height: 170)
    }
}

private struct Line: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: .init(x: 0, y: rect.midY))
        p.addLine(to: .init(x: rect.width, y: rect.midY))
        return p
    }
}
