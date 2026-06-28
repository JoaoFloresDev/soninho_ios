import SwiftUI
import GambitScreenshotKit

// MARK: - Feature 2 (Slot 3 — Anti-relapse step confirmation)
//
// Recreates WakeConfirmationView: after dismissing, walk a few steps to prove
// you actually got up, or the alarm re-rings.

struct Feature2Screen: View {
    let locale: String
    private func L(_ en: String, _ pt: String, _ es: String) -> String {
        locale == "pt-BR" ? pt : (locale.hasPrefix("es") ? es : en)
    }

    var body: some View {
        ZStack {
            MockTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                iOSStatusBar(foreground: .white)

                Spacer()

                VStack(spacing: 34) {
                    Image(systemName: "figure.walk.motion")
                        .font(.system(size: 62))
                        .foregroundStyle(MockTheme.success)

                    VStack(spacing: 10) {
                        Text(L("Prove you're out of bed", "Prove que saiu da cama", "Demuestra que te levantaste"))
                            .font(.system(size: 26, weight: .bold))
                            .foregroundStyle(MockTheme.textPrimary)
                            .multilineTextAlignment(.center)
                        Text(L("Take a few steps to clear the alarm for good",
                               "Dê alguns passos pra encerrar o alarme de vez",
                               "Camina unos pasos para apagar la alarma del todo"))
                            .font(.system(size: 16))
                            .foregroundStyle(MockTheme.textSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.horizontal, 12)

                    ZStack {
                        Circle().stroke(MockTheme.surfaceSecondary, lineWidth: 15)
                        Circle()
                            .trim(from: 0, to: 9.0 / 15.0)
                            .stroke(MockTheme.success, style: StrokeStyle(lineWidth: 15, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                        VStack(spacing: 2) {
                            Text("9/15")
                                .font(.system(size: 46, weight: .bold, design: .rounded))
                                .foregroundStyle(MockTheme.textPrimary)
                                .monospacedDigit()
                            Text(L("steps", "passos", "pasos"))
                                .font(.system(size: 15))
                                .foregroundStyle(MockTheme.textSecondary)
                        }
                    }
                    .frame(width: 240, height: 240)

                    Text(L("84s left", "Faltam 84s", "Quedan 84s"))
                        .font(.system(size: 15))
                        .foregroundStyle(MockTheme.textTertiary)
                        .monospacedDigit()
                }
                .padding(.horizontal, 30)

                Spacer()
            }
        }
    }
}
