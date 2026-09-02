import SwiftUI

// MARK: - Breakout Framing
//
// House look: the print's CORE component pops out over the device — scaled
// wider than the phone (overhangs both bezels), rounded, brand-orange border
// + glow, the SAME glow color on all five prints.

private let breakoutGlow = AppPalette.primary

func breakoutForeground<V: View>(
    _ view: V,
    authorWidth: CGFloat = 440,
    targetWidth: CGFloat = 1240,
    y: CGFloat,
    canvas: CGSize
) -> AnyView {
    AnyView(
        ZStack {
            view
                .frame(width: authorWidth)
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color(hex: 0x1A140F))
                )
                .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(breakoutGlow.opacity(0.85), lineWidth: 2)
                )
                // Glow as blurred plates BEHIND the opaque card — a .shadow()
                // here makes ImageRenderer stamp a shadow plate behind every
                // glyph (the known kit artifact).
                .background(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(breakoutGlow.opacity(0.60))
                        .padding(-6)
                        .blur(radius: 30)
                )
                .background(
                    RoundedRectangle(cornerRadius: 34, style: .continuous)
                        .fill(breakoutGlow.opacity(0.28))
                        .padding(-16)
                        .blur(radius: 70)
                )
                .scaleEffect(targetWidth / authorWidth, anchor: .center)
                .position(x: canvas.width / 2, y: y)
        }
        .frame(width: canvas.width, height: canvas.height)
    )
}

// MARK: - Alarm Card (slot 1 core — the smart alarm itself)
struct AlarmCardMock: View {
    let locale: String
    private func L(_ en: String, _ pt: String, _ es: String) -> String {
        locale == "pt-BR" ? pt : (locale.hasPrefix("es") ? es : en)
    }

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 5) {
                Text("06:30")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundStyle(AppPalette.textPrimary)

                Text(L("Every day", "Todos os dias", "Todos los días"))
                    .font(.system(size: 13))
                    .foregroundStyle(AppPalette.textSecondary)

                HStack(spacing: 8) {
                    GlassChip(icon: "brain.head.profile", text: L("30 min window", "Janela de 30 min", "Ventana de 30 min"))
                    GlassChip(icon: "puzzlepiece.fill", text: L("Math", "Matemática", "Cálculo"), tint: AppPalette.primaryLight)
                }
            }
            Spacer()
            Capsule()
                .fill(AppPalette.primary)
                .frame(width: 52, height: 32)
                .overlay(Circle().fill(.white).frame(width: 28, height: 28).offset(x: 10))
        }
        .padding(16)
    }
}

// MARK: - Mission Card (slot 2 core — solve to turn off)
struct MissionCardMock: View {
    let locale: String
    private func L(_ en: String, _ pt: String, _ es: String) -> String {
        locale == "pt-BR" ? pt : (locale.hasPrefix("es") ? es : en)
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(index == 0 ? AppPalette.primary : Color.white.opacity(0.18))
                        .frame(width: 9, height: 9)
                }
            }

            Text(L("Solve to turn off", "Resolva para desligar", "Resuelve para apagar"))
                .font(.system(size: 15))
                .foregroundStyle(AppPalette.textSecondary)

            Text("24 + 17")
                .font(.system(size: 52, weight: .bold, design: .rounded))
                .foregroundStyle(AppPalette.textPrimary)

            Text("4")
                .font(.system(size: 38, weight: .semibold, design: .rounded))
                .foregroundStyle(AppPalette.primary)

            VStack(spacing: 8) {
                keypadRow(["1", "2", "3"])
                keypadRow(["4", "5", "6"])
            }
        }
        .padding(18)
    }

    private func keypadRow(_ keys: [String]) -> some View {
        HStack(spacing: 8) {
            ForEach(keys, id: \.self) { key in
                Text(key)
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppPalette.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(Color.white.opacity(0.10))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                            )
                    )
            }
        }
    }
}

// MARK: - Hypnogram Card (slot 3 core — the phases chart)
struct HypnogramCardMock: View {
    let locale: String
    private func L(_ en: String, _ pt: String, _ es: String) -> String {
        locale == "pt-BR" ? pt : (locale.hasPrefix("es") ? es : en)
    }

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
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(L("Sleep score", "Nota do sono", "Puntuación"))
                        .font(.system(size: 13))
                        .foregroundStyle(AppPalette.textSecondary)
                    Text("86")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(AppPalette.success)
                }
                Spacer()
                Text(L("7h 42min asleep", "7h 42min dormindo", "7h 42min dormido"))
                    .font(.system(size: 14))
                    .foregroundStyle(AppPalette.textSecondary)
            }

            hypnogram

            HStack(spacing: 14) {
                legendDot(AppPalette.awake, L("Awake", "Acordado", "Despierto"))
                legendDot(AppPalette.lightSleep, L("Light", "Leve", "Ligero"))
                legendDot(AppPalette.remSleep, "REM")
                legendDot(AppPalette.deepSleep, L("Deep", "Profundo", "Profundo"))
            }
            .frame(maxWidth: .infinity)
        }
        .padding(18)
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
        .frame(height: 92)
    }

    private func legendDot(_ color: Color, _ label: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(AppPalette.textSecondary)
        }
    }
}

// MARK: - Duration Chart Card (slot 5 core — week vs goal)
struct DurationChartCardMock: View {
    let locale: String
    private func L(_ en: String, _ pt: String, _ es: String) -> String {
        locale == "pt-BR" ? pt : (locale.hasPrefix("es") ? es : en)
    }

    private let bars: [(day: String, hours: CGFloat, good: Bool)] = [
        ("S", 6.8, false), ("M", 7.6, true), ("T", 8.1, true), ("W", 7.2, true),
        ("T", 6.4, false), ("F", 7.9, true), ("S", 8.4, true),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(L("Sleep duration", "Duração do sono", "Duración del sueño"))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppPalette.textPrimary)
                Spacer()
                GlassChip(icon: "target", text: L("Goal 8h", "Meta 8h", "Meta 8h"), tint: AppPalette.success)
            }

            GeometryReader { geo in
                let maxH = geo.size.height - 22
                ZStack(alignment: .bottom) {
                    VStack(spacing: 0) {
                        Spacer().frame(height: maxH * (1 - 8.0 / 9.0))
                        Rectangle()
                            .fill(Color.clear)
                            .frame(height: 1)
                            .overlay(
                                Rectangle()
                                    .fill(AppPalette.textTertiary)
                                    .frame(height: 1)
                                    .mask(dashMask(width: geo.size.width))
                            )
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
            .frame(height: 150)
        }
        .padding(18)
    }

    private func dashMask(width: CGFloat) -> some View {
        HStack(spacing: 5) {
            ForEach(0..<Int(width / 10), id: \.self) { _ in
                Rectangle().frame(width: 5, height: 1)
            }
        }
    }
}

// MARK: - Wake Window Card (slot 2 core — the smart wake itself)
struct WakeWindowCardMock: View {
    let locale: String
    private func L(_ en: String, _ pt: String, _ es: String) -> String {
        locale == "pt-BR" ? pt : (locale.hasPrefix("es") ? es : en)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "brain.head.profile")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(AppPalette.primary)
                Text(L("Smart wake window", "Janela de despertar", "Ventana inteligente"))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(AppPalette.textPrimary)
                Spacer()
                Text("07:00 – 07:30")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(AppPalette.textSecondary)
                    .monospacedDigit()
            }

            // Window timeline: deep → light, ring marker inside the light zone
            ZStack(alignment: .leading) {
                GeometryReader { geo in
                    let w = geo.size.width
                    HStack(spacing: 0) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(AppPalette.deepSleep.opacity(0.85))
                            .frame(width: w * 0.34)
                        Rectangle()
                            .fill(AppPalette.lightSleep.opacity(0.9))
                            .frame(width: w * 0.46)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white.opacity(0.10))
                            .frame(width: w * 0.20)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 6))

                    // Ring marker at 07:22 — inside the light zone
                    VStack(spacing: 3) {
                        Image(systemName: "sunrise.fill")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundStyle(.white)
                            .padding(7)
                            .background(Circle().fill(AppPalette.primary))
                        Rectangle()
                            .fill(AppPalette.primary)
                            .frame(width: 3, height: 12)
                    }
                    .position(x: w * 0.72, y: 2)
                }
            }
            .frame(height: 44)
            .padding(.top, 16)

            HStack {
                HStack(spacing: 6) {
                    Circle().fill(AppPalette.lightSleep).frame(width: 8, height: 8)
                    Text(L("Woke at 7:22 — light sleep", "Acordou 7:22 — sono leve", "Despertó 7:22 — sueño ligero"))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppPalette.textPrimary)
                }
                Spacer()
                Text(L("8 min early", "8 min antes", "8 min antes"))
                    .font(.system(size: 13))
                    .foregroundStyle(AppPalette.success)
            }
        }
        .padding(18)
    }
}

// MARK: - Gradual Volume Card (slot 4 core — gentle rising sound)
struct GradualVolumeCardMock: View {
    let locale: String
    private func L(_ en: String, _ pt: String, _ es: String) -> String {
        locale == "pt-BR" ? pt : (locale.hasPrefix("es") ? es : en)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "sunrise.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppPalette.primary)
                    Text(L("Sunrise · gradual wake", "Amanhecer · despertar gradual", "Amanecer · despertar gradual"))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppPalette.textPrimary)
                }
                Spacer()
                GlassChip(icon: "checkmark", text: L("On", "Ativo", "Activo"), tint: AppPalette.success)
            }

            HStack(alignment: .bottom, spacing: 5) {
                ForEach(0..<18, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2)
                        .fill(
                            LinearGradient(
                                colors: [AppPalette.primaryLight, AppPalette.primary],
                                startPoint: .top, endPoint: .bottom
                            )
                        )
                        .frame(width: 15, height: 8 + CGFloat(index) * 3.6)
                        .opacity(0.45 + Double(index) * 0.03)
                }
            }
            .frame(maxWidth: .infinity)

            HStack {
                Text(L("Starts at a whisper", "Começa num sussurro", "Empieza en un susurro"))
                    .font(.system(size: 13))
                    .foregroundStyle(AppPalette.textSecondary)
                Spacer()
                Text(L("Full volume in 2 min", "Volume cheio em 2 min", "Volumen total en 2 min"))
                    .font(.system(size: 13))
                    .foregroundStyle(AppPalette.textSecondary)
            }
        }
        .padding(18)
    }
}
