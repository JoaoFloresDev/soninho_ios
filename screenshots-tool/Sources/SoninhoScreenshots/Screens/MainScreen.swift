import SwiftUI
import GambitScreenshotKit

// MARK: - Main Screen (Slot 1 — Alarm ringing + gradual sunrise wake)
//
// Recreates AlarmRingingView's ringing phase: big clock, pulsing rings around
// a sunrise bell, Wake up / Snooze actions, over a sunrise gradient backdrop.

struct MainScreen: View {
    let locale: String
    private func L(_ en: String, _ pt: String, _ es: String) -> String {
        locale == "pt-BR" ? pt : (locale.hasPrefix("es") ? es : en)
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.97, green: 0.65, blue: 0.16),
                    Color(red: 0.97, green: 0.45, blue: 0.20),
                    Color(red: 0.36, green: 0.30, blue: 0.62),
                    Color(red: 0.09, green: 0.08, blue: 0.22)
                ],
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()

            VStack(spacing: 0) {
                iOSStatusBar(foreground: .white)

                Spacer().frame(height: 36)

                Text("07:00")
                    .font(.system(size: 92, weight: .thin, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                    .shadow(color: .black.opacity(0.25), radius: 10, y: 2)

                Text(L("Time to wake up", "Hora de acordar", "Hora de despertar"))
                    .font(.system(size: 19, weight: .medium))
                    .foregroundStyle(.white.opacity(0.92))
                    .padding(.top, 4)

                Spacer()

                ZStack {
                    ForEach(0..<3, id: \.self) { i in
                        Circle()
                            .stroke(Color.white.opacity(0.16), lineWidth: 2)
                            .frame(width: 184 + CGFloat(i) * 50, height: 184 + CGFloat(i) * 50)
                    }
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color(red: 0.99, green: 0.70, blue: 0.20), Color(red: 0.97, green: 0.45, blue: 0.20)],
                            startPoint: .top, endPoint: .bottom))
                        .frame(width: 168, height: 168)
                        .shadow(color: .black.opacity(0.22), radius: 18, y: 6)
                    Image(systemName: "sunrise.fill")
                        .font(.system(size: 70))
                        .foregroundStyle(.white)
                }

                Spacer()

                VStack(spacing: 14) {
                    actionButton(icon: "sunrise.fill",
                                 text: L("Wake up", "Despertar", "Despertar"),
                                 fg: Color(red: 0.30, green: 0.26, blue: 0.55), bg: .white)
                    actionButton(icon: "clock.arrow.circlepath",
                                 text: L("Snooze", "Soneca", "Posponer"),
                                 fg: .white, bg: Color.white.opacity(0.18))
                }
                .padding(.horizontal, 34)
                .padding(.bottom, 52)
            }
        }
    }

    private func actionButton(icon: String, text: String, fg: Color, bg: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 18, weight: .semibold))
            Text(text).font(.system(size: 19, weight: .semibold))
        }
        .foregroundStyle(fg)
        .frame(maxWidth: .infinity)
        .frame(height: 60)
        .background(bg)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}
