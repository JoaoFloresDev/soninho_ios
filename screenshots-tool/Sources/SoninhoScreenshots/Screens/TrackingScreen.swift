import SwiftUI
import GambitScreenshotKit

// MARK: - Slot 2 — Night tracking + smart wake window
//
// Faithful to SleepTrackerView's tracking state (night gradient, elapsed
// timer, live phase pill, movement/sound bars); the breakout demonstrates
// the headline feature: waking inside the light-sleep window.

struct TrackingScreen: View {
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

                Spacer().frame(height: 26)

                Text(L("Tracking your sleep", "Monitorando seu sono", "Monitoreando tu sueño"))
                    .font(.system(size: 17, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))

                Text("06:47:12")
                    .font(.system(size: 64, weight: .thin, design: .rounded))
                    .foregroundStyle(.white)
                    .monospacedDigit()
                    .padding(.top, 4)

                // Live phase pill
                HStack(spacing: 8) {
                    Circle().fill(AppPalette.lightSleep).frame(width: 8, height: 8)
                    Image(systemName: "moon.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(AppPalette.lightSleep)
                    Text(L("Light Sleep", "Sono leve", "Sueño ligero"))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppPalette.lightSleep)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(AppPalette.lightSleep.opacity(0.16))
                        .overlay(Capsule().strokeBorder(AppPalette.lightSleep.opacity(0.35), lineWidth: 1))
                )
                .padding(.top, 16)

                mascotImage("slothSnooze")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                    .padding(.top, 18)

                // Live sensor bars
                HStack(spacing: 26) {
                    sensorIndicator(
                        icon: "waveform.path.ecg",
                        label: L("Movement", "Movimento", "Movimiento"),
                        fill: 0.18, color: AppPalette.deepSleep
                    )
                    sensorIndicator(
                        icon: "mic.fill",
                        label: L("Sound", "Som", "Sonido"),
                        fill: 0.10, color: AppPalette.deepSleep
                    )
                }
                .padding(.top, 22)

                Spacer()
            }
        }
    }

    private func sensorIndicator(icon: String, label: String, fill: CGFloat, color: Color) -> some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                    .foregroundStyle(AppPalette.textTertiary)
                Text(label)
                    .font(.system(size: 12))
                    .foregroundStyle(AppPalette.textTertiary)
            }
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.white.opacity(0.10))
                RoundedRectangle(cornerRadius: 3)
                    .fill(color)
                    .frame(width: 120 * fill)
            }
            .frame(width: 120, height: 6)
        }
    }
}
