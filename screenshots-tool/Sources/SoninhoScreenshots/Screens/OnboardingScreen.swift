import SwiftUI
import GambitScreenshotKit

// MARK: - Onboarding/Stats Screen (Slot 5 — Sleep cycle hypnogram + summary)
//
// The tracking payoff: a hypnogram of last night's cycle (Awake/REM/Light/Deep)
// plus the headline numbers. Mirrors the Statistics tab.

struct OnboardingScreen: View {
    let locale: String
    private func L(_ en: String, _ pt: String, _ es: String) -> String {
        locale == "pt-BR" ? pt : (locale.hasPrefix("es") ? es : en)
    }

    // Phase level per time slot: 0 Awake (top) · 1 REM · 2 Light · 3 Deep (bottom)
    private let hypno: [Int] = [2, 3, 3, 2, 1, 2, 3, 3, 2, 1, 1, 2, 2, 1, 0, 2, 1, 0]
    private let phaseColors: [Color] = [MockTheme.awake, MockTheme.remSleep, MockTheme.lightSleep, MockTheme.deepSleep]

    var body: some View {
        ZStack {
            MockTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                iOSStatusBar(foreground: .white)

                HStack {
                    Text(L("Sleep cycle", "Ciclo de sono", "Ciclo de sueño"))
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(.white)
                    Spacer()
                }
                .padding(.horizontal, 22)
                .padding(.top, 10)
                .padding(.bottom, 16)

                VStack(spacing: 16) {
                    summaryRow
                    hypnogramCard
                }
                .padding(.horizontal, 18)

                Spacer(minLength: 0)
            }
        }
    }

    private var summaryRow: some View {
        HStack(spacing: 12) {
            metric(L("Duration", "Duração", "Duración"), "7h 32m", MockTheme.primaryLight)
            metric(L("Score", "Nota", "Nota"), "86", MockTheme.accentSecondary)
            metric(L("Deep", "Profundo", "Profundo"), "1h 28m", MockTheme.deepSleep)
        }
    }

    private func metric(_ title: String, _ value: String, _ tint: Color) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundStyle(MockTheme.textPrimary)
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(MockTheme.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(MockTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(alignment: .top) {
            Capsule().fill(tint).frame(width: 32, height: 3).padding(.top, 8)
        }
    }

    private var hypnogramCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(L("Last night", "Última noite", "Anoche"))
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(MockTheme.textPrimary)
                Spacer()
                Text("23:18 → 06:50")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(MockTheme.textTertiary)
            }

            HStack(spacing: 10) {
                VStack(alignment: .leading, spacing: 0) {
                    phaseLabel(L("Awake", "Acordado", "Despierto"), MockTheme.awake)
                    Spacer()
                    phaseLabel("REM", MockTheme.remSleep)
                    Spacer()
                    phaseLabel(L("Light", "Leve", "Ligero"), MockTheme.lightSleep)
                    Spacer()
                    phaseLabel(L("Deep", "Profundo", "Profundo"), MockTheme.deepSleep)
                }
                .frame(width: 84, height: 360)

                hypnogram.frame(height: 360)
            }

            HStack(spacing: 16) {
                legend(MockTheme.deepSleep, L("Deep", "Profundo", "Profundo"))
                legend(MockTheme.lightSleep, L("Light", "Leve", "Ligero"))
                legend(MockTheme.remSleep, "REM")
                Spacer()
            }

            Rectangle().fill(MockTheme.surfaceSecondary).frame(height: 1).padding(.vertical, 2)

            HStack {
                Text(L("7-night average", "Média de 7 noites", "Promedio de 7 noches"))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(MockTheme.textSecondary)
                Spacer()
                Text("7h 18m · 5 \(L("cycles", "ciclos", "ciclos"))")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(MockTheme.primaryLight)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(MockTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func phaseLabel(_ text: String, _ tint: Color) -> some View {
        HStack(spacing: 5) {
            Circle().fill(tint).frame(width: 7, height: 7)
            Text(text)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(MockTheme.textSecondary)
        }
    }

    private func legend(_ color: Color, _ text: String) -> some View {
        HStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 2).fill(color).frame(width: 12, height: 4)
            Text(text).font(.system(size: 11, weight: .medium)).foregroundStyle(MockTheme.textTertiary)
        }
    }

    private func yFor(_ level: Int, _ h: CGFloat) -> CGFloat { (CGFloat(level) + 0.5) / 4.0 * h }

    private var hypnogram: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            let stepX = w / CGFloat(hypno.count)

            ZStack {
                ForEach(0..<4, id: \.self) { lvl in
                    Path { p in
                        let yy = (CGFloat(lvl) + 0.5) / 4.0 * h
                        p.move(to: CGPoint(x: 0, y: yy))
                        p.addLine(to: CGPoint(x: w, y: yy))
                    }
                    .stroke(MockTheme.surfaceSecondary.opacity(0.6), lineWidth: 1)
                }
                Path { p in
                    for (i, lvl) in hypno.enumerated() {
                        let x0 = CGFloat(i) * stepX
                        let x1 = x0 + stepX
                        let yy = yFor(lvl, h)
                        if i == 0 {
                            p.move(to: CGPoint(x: x0, y: yy))
                        } else {
                            p.addLine(to: CGPoint(x: x0, y: yFor(hypno[i - 1], h)))
                            p.addLine(to: CGPoint(x: x0, y: yy))
                        }
                        p.addLine(to: CGPoint(x: x1, y: yy))
                    }
                }
                .stroke(
                    LinearGradient(colors: [MockTheme.deepSleep, MockTheme.accentSecondary], startPoint: .leading, endPoint: .trailing),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round)
                )
            }
        }
    }
}
