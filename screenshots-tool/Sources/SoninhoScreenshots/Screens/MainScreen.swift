import SwiftUI
import GambitScreenshotKit

// MARK: - Main Screen (Slot 1 — Smart Alarm home, Liquid Glass dark)
//
// Faithful to SmartAlarmView: mascot next-alarm card (heroAlarm art with its
// baked halo), smart badge, alarm cards with mission/window chips, glass tab bar.

struct MainScreen: View {
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
                    Text(L("Alarms", "Alarmes", "Alarmas"))
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(AppPalette.textPrimary)
                    Spacer()
                    Image(systemName: "plus")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(AppPalette.primary)
                        .frame(width: 38, height: 38)
                        .background(Circle().fill(AppPalette.surface))
                }
                .padding(.horizontal, 22)
                .padding(.top, 8)

                // Next alarm card
                GlassCard(tint: AppPalette.primary) {
                    VStack(spacing: 10) {
                        mascotImage("heroAlarm")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 150, height: 150)

                        VStack(spacing: 3) {
                            Text(L("Next alarm", "Próximo alarme", "Próxima alarma"))
                                .font(.system(size: 15))
                                .foregroundStyle(AppPalette.textSecondary)

                            Text(L("In 8h 12min", "Em 8h 12min", "En 8h 12min"))
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(AppPalette.textPrimary)
                        }

                        GlassChip(
                            icon: "brain.head.profile",
                            text: L("Smart wake-up on", "Despertar inteligente ativo", "Despertar inteligente activo")
                        )
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
                .padding(.horizontal, 22)
                .padding(.top, 14)

                // Alarms list
                HStack {
                    Text(L("Your alarms", "Seus alarmes", "Tus alarmas"))
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(AppPalette.textPrimary)
                    Spacer()
                }
                .padding(.horizontal, 22)
                .padding(.top, 20)

                VStack(spacing: 12) {
                    alarmCard(
                        time: "06:30",
                        days: L("Every day", "Todos os dias", "Todos los días"),
                        window: L("30 min window", "Janela de 30 min", "Ventana de 30 min"),
                        mission: L("Math", "Matemática", "Cálculo"),
                        on: true
                    )
                    alarmCard(
                        time: "09:15",
                        days: L("Weekends", "Fins de semana", "Fines de semana"),
                        window: L("15 min window", "Janela de 15 min", "Ventana de 15 min"),
                        mission: L("Shake", "Chacoalhar", "Agitar"),
                        on: false
                    )
                }
                .padding(.horizontal, 22)
                .padding(.top, 10)

                Spacer()

                TabBarMock(activeIndex: 0)
            }
        }
    }

    private func alarmCard(time: String, days: String, window: String, mission: String, on: Bool) -> some View {
        GlassCard {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(time)
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(on ? AppPalette.textPrimary : AppPalette.textTertiary)

                    Text(days)
                        .font(.system(size: 13))
                        .foregroundStyle(AppPalette.textSecondary)

                    HStack(spacing: 8) {
                        GlassChip(icon: "brain.head.profile", text: window, tint: on ? AppPalette.primary : AppPalette.textTertiary)
                        GlassChip(icon: "puzzlepiece.fill", text: mission, tint: on ? AppPalette.primaryLight : AppPalette.textTertiary)
                    }
                }
                Spacer()
                toggleMock(on: on)
            }
            .padding(16)
        }
        .opacity(on ? 1 : 0.7)
    }

    private func toggleMock(on: Bool) -> some View {
        Capsule()
            .fill(on ? AppPalette.primary : Color.white.opacity(0.18))
            .frame(width: 52, height: 32)
            .overlay(
                Circle()
                    .fill(.white)
                    .frame(width: 28, height: 28)
                    .offset(x: on ? 10 : -10)
            )
    }
}
