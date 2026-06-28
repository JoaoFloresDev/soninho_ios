import SwiftUI
import GambitScreenshotKit

// MARK: - Settings Screen (Slot 4 — Pleasant alarm sounds + loud volume)
//
// Mirrors the alarm sound picker: a volume slider near max plus the list of
// gentle wake sounds, the selected one checked.

struct SettingsScreen: View {
    let locale: String
    private func L(_ en: String, _ pt: String, _ es: String) -> String {
        locale == "pt-BR" ? pt : (locale.hasPrefix("es") ? es : en)
    }

    var body: some View {
        ZStack {
            MockTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                iOSStatusBar(foreground: .white)

                HStack {
                    Text(L("Alarm sound", "Som do alarme", "Sonido de alarma"))
                        .font(.system(size: 30, weight: .bold))
                        .foregroundStyle(.white)
                    Spacer()
                }
                .padding(.horizontal, 22)
                .padding(.top, 10)
                .padding(.bottom, 16)

                VStack(spacing: 13) {
                    volumeCard

                    soundRow("sunrise.fill", L("Sunrise", "Nascer do sol", "Amanecer"), MockTheme.warning, selected: true)
                    soundRow("bird.fill", L("Birds", "Pássaros", "Pájaros"), MockTheme.lightSleep, selected: false)
                    soundRow("water.waves", L("Ocean", "Oceano", "Océano"), MockTheme.deepSleep, selected: false)
                    soundRow("wind.snow", L("Chimes", "Sinos de vento", "Campanillas"), MockTheme.accentSecondary, selected: false)
                    soundRow("music.quarternote.3", L("Harp", "Harpa", "Arpa"), MockTheme.remSleep, selected: false)
                    soundRow("cloud.rain.fill", L("Rain", "Chuva", "Lluvia"), MockTheme.primaryLight, selected: false)
                    soundRow("music.note", L("Marimba", "Marimba", "Marimba"), MockTheme.accent, selected: false)
                }
                .padding(.horizontal, 18)

                Spacer(minLength: 0)
            }
        }
    }

    private var volumeCard: some View {
        VStack(spacing: 12) {
            HStack {
                Text(L("Volume", "Volume", "Volumen"))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(MockTheme.textPrimary)
                Spacer()
                Text("100%")
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(MockTheme.warning)
            }
            HStack(spacing: 12) {
                Image(systemName: "speaker.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(MockTheme.textSecondary)
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(MockTheme.surfaceSecondary).frame(height: 7)
                        Capsule().fill(MockTheme.warning).frame(width: geo.size.width, height: 7)
                        Circle().fill(.white).frame(width: 22, height: 22)
                            .shadow(color: .black.opacity(0.3), radius: 3, y: 1)
                            .offset(x: geo.size.width - 22)
                    }
                    .frame(height: 22)
                }
                .frame(height: 22)
                Image(systemName: "speaker.wave.3.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(MockTheme.warning)
            }
        }
        .padding(16)
        .background(MockTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func soundRow(_ icon: String, _ name: String, _ tint: Color, selected: Bool) -> some View {
        HStack(spacing: 13) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(tint)
                .frame(width: 42, height: 42)
                .background(tint.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
            Text(name)
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(MockTheme.textPrimary)
            Spacer()
            if selected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(MockTheme.warning)
            }
        }
        .padding(14)
        .background(selected ? MockTheme.warning.opacity(0.12) : MockTheme.surface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
