import SwiftUI
import GambitScreenshotKit

// MARK: - Feature 1 (Slot 2 — Alarm ringing + math mission)
//
// Faithful to AlarmRingingView (dark night gradient, mascot with baked halo,
// big clock) with MathMissionView's challenge card front and center.

struct Feature1Screen: View {
    let locale: String
    private func L(_ en: String, _ pt: String, _ es: String) -> String {
        locale == "pt-BR" ? pt : (locale.hasPrefix("es") ? es : en)
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0x000000), Color(hex: 0x140A05), Color(hex: 0x331507)],
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()

            VStack(spacing: 0) {
                iOSStatusBar(foreground: .white)

                Spacer().frame(height: 12)

                Text("06:30")
                    .font(.system(size: 74, weight: .thin, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()

                Text(L("Time to wake up", "Hora de acordar", "Hora de despertar"))
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))

                mascotImage("heroAlarm")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 190, height: 190)
                    .padding(.top, 6)

                // Mission card (MathMissionView)
                GlassCard(cornerRadius: 24) {
                    VStack(spacing: 14) {
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
                            .font(.system(size: 40, weight: .semibold, design: .rounded))
                            .foregroundStyle(AppPalette.primary)
                            .frame(height: 44)

                        VStack(spacing: 8) {
                            keypadRow(["1", "2", "3"])
                            keypadRow(["4", "5", "6"])
                        }
                    }
                    .padding(20)
                }
                .padding(.horizontal, 26)
                .padding(.top, 10)

                Spacer()
            }
        }
    }

    private func keypadRow(_ keys: [String]) -> some View {
        HStack(spacing: 8) {
            ForEach(keys, id: \.self) { key in
                Text(key)
                    .font(.system(size: 24, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppPalette.textPrimary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
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
