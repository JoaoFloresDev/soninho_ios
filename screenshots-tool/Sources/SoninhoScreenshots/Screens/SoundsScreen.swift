import SwiftUI
import GambitScreenshotKit

// MARK: - Slot 4 — Alarm sounds + gradual wake
//
// Faithful to AlarmEditSheet's sound section: sound list with selection,
// gradual-wake toggle with its duration, volume slider.

struct SoundsScreen: View {
    let locale: String
    private func L(_ en: String, _ pt: String, _ es: String) -> String {
        locale == "pt-BR" ? pt : (locale.hasPrefix("es") ? es : en)
    }

    var body: some View {
        ZStack {
            GlassBackdropMock()

            VStack(spacing: 0) {
                iOSStatusBar(foreground: .white)

                HStack {
                    Text(L("Edit alarm", "Editar alarme", "Editar alarma"))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundStyle(AppPalette.textPrimary)
                    Spacer()
                    Text(L("Save", "Salvar", "Guardar"))
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(AppPalette.primary)
                }
                .padding(.horizontal, 22)
                .padding(.top, 8)

                // Sound list
                GlassCard {
                    VStack(spacing: 0) {
                        soundRow(L("Sunrise", "Amanhecer", "Amanecer"), icon: "sunrise.fill", selected: true)
                        divider
                        soundRow(L("Birdsong", "Passarinhos", "Pájaros"), icon: "bird.fill", selected: false)
                        divider
                        soundRow(L("Ocean waves", "Ondas do mar", "Olas del mar"), icon: "water.waves", selected: false)
                        divider
                        soundRow(L("Soft piano", "Piano suave", "Piano suave"), icon: "pianokeys", selected: false)
                    }
                    .padding(.vertical, 4)
                }
                .padding(.horizontal, 22)
                .padding(.top, 16)

                // Gradual wake
                GlassCard {
                    VStack(spacing: 14) {
                        HStack {
                            VStack(alignment: .leading, spacing: 3) {
                                Text(L("Gradual wake", "Despertar gradual", "Despertar gradual"))
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(AppPalette.textPrimary)
                                Text(L("Volume rises over 2 min", "Volume sobe em 2 min", "El volumen sube en 2 min"))
                                    .font(.system(size: 13))
                                    .foregroundStyle(AppPalette.textSecondary)
                            }
                            Spacer()
                            Capsule()
                                .fill(AppPalette.primary)
                                .frame(width: 52, height: 32)
                                .overlay(Circle().fill(.white).frame(width: 28, height: 28).offset(x: 10))
                        }

                        rampBars(fillCount: 12)

                        HStack(spacing: 12) {
                            Image(systemName: "speaker.fill")
                                .font(.system(size: 13))
                                .foregroundStyle(AppPalette.textTertiary)
                            ZStack(alignment: .leading) {
                                Capsule().fill(Color.white.opacity(0.12)).frame(height: 5)
                                Capsule().fill(AppPalette.primary).frame(width: 190, height: 5)
                                Circle().fill(.white).frame(width: 22, height: 22).offset(x: 180)
                            }
                            Image(systemName: "speaker.wave.3.fill")
                                .font(.system(size: 13))
                                .foregroundStyle(AppPalette.textSecondary)
                        }
                    }
                    .padding(16)
                }
                .padding(.horizontal, 22)
                .padding(.top, 14)

                Spacer()
            }
        }
    }

    private var divider: some View {
        Rectangle().fill(Color.white.opacity(0.08)).frame(height: 1).padding(.leading, 54)
    }

    private func soundRow(_ name: String, icon: String, selected: Bool) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundStyle(selected ? AppPalette.primary : AppPalette.textSecondary)
                .frame(width: 26)
            Text(name)
                .font(.system(size: 16, weight: selected ? .semibold : .regular))
                .foregroundStyle(AppPalette.textPrimary)
            Spacer()
            if selected {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(AppPalette.primary)
            } else {
                Image(systemName: "play.circle")
                    .font(.system(size: 18))
                    .foregroundStyle(AppPalette.textTertiary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    func rampBars(fillCount: Int) -> some View {
        HStack(alignment: .bottom, spacing: 5) {
            ForEach(0..<16, id: \.self) { index in
                RoundedRectangle(cornerRadius: 2)
                    .fill(
                        index < fillCount
                            ? AnyShapeStyle(LinearGradient(
                                colors: [AppPalette.primaryLight, AppPalette.primary],
                                startPoint: .top, endPoint: .bottom))
                            : AnyShapeStyle(Color.white.opacity(0.12))
                    )
                    .frame(width: 14, height: 10 + CGFloat(index) * 3.4)
            }
        }
        .frame(maxWidth: .infinity)
    }
}
