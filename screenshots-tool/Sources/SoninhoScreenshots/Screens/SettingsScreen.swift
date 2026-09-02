import SwiftUI
import GambitScreenshotKit

// MARK: - Slot 4 — Wake greeting with the sloth mascot
//
// Faithful to WakeGreetingView (morning gradient, glow circle, mascot pose,
// big greeting) — the charisma shot.

struct SettingsScreen: View {
    let locale: String
    private func L(_ en: String, _ pt: String, _ es: String) -> String {
        locale == "pt-BR" ? pt : (locale.hasPrefix("es") ? es : en)
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: 0xFBBF24), Color(hex: 0xF97316), Color(hex: 0x2B1206)],
                startPoint: .top, endPoint: .bottom
            ).ignoresSafeArea()

            VStack(spacing: 0) {
                iOSStatusBar(foreground: .white)

                Spacer()

                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.16))
                        .frame(width: 240, height: 240)

                    mascotImage("slothWakeMorning")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 235, height: 235)
                        .shadow(color: .black.opacity(0.25), radius: 12, y: 4)
                }

                VStack(spacing: 10) {
                    Text(L("Good morning!", "Bom dia!", "¡Buenos días!"))
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.2), radius: 8, y: 2)

                    Text(L("Your night was saved", "Sua noite foi salva", "Tu noche fue guardada"))
                        .font(.system(size: 17))
                        .foregroundStyle(.white.opacity(0.88))
                }
                .padding(.top, 26)

                Spacer()
                Spacer()
            }
        }
    }
}
