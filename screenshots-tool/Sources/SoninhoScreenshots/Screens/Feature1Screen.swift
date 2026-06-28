import SwiftUI
import GambitScreenshotKit

// MARK: - Feature 1 (Slot 2 — Math dismiss mission)
//
// Recreates MathMissionView: progress dots, a question card, and the custom
// keypad you must solve before the alarm can be silenced.

struct Feature1Screen: View {
    let locale: String
    private func L(_ en: String, _ pt: String, _ es: String) -> String {
        locale == "pt-BR" ? pt : (locale.hasPrefix("es") ? es : en)
    }

    private let keypad: [[String]] = [["1", "2", "3"], ["4", "5", "6"], ["7", "8", "9"], ["⌫", "0", "OK"]]

    var body: some View {
        ZStack {
            MockTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                iOSStatusBar(foreground: .white)

                VStack(spacing: 26) {
                    Spacer()

                    HStack(spacing: 9) {
                        ForEach(0..<3, id: \.self) { i in
                            Circle()
                                .fill(i == 0 ? MockTheme.accent : MockTheme.surfaceSecondary)
                                .frame(width: 10, height: 10)
                        }
                    }

                    Text(L("Solve to turn off the alarm", "Resolva pra desligar o alarme", "Resuelve para apagar la alarma"))
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(MockTheme.textSecondary)

                    VStack(spacing: 12) {
                        Text("7 × 8")
                            .font(.system(size: 60, weight: .bold, design: .rounded))
                            .foregroundStyle(MockTheme.textPrimary)
                        Text("56")
                            .font(.system(size: 44, weight: .semibold, design: .rounded))
                            .foregroundStyle(MockTheme.accent)
                            .monospacedDigit()
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
                    .background(MockTheme.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

                    VStack(spacing: 14) {
                        ForEach(keypad, id: \.self) { row in
                            HStack(spacing: 14) {
                                ForEach(row, id: \.self) { key in keypadButton(key) }
                            }
                        }
                    }

                    Spacer()
                }
                .padding(.horizontal, 30)
            }
        }
    }

    private func keypadButton(_ key: String) -> some View {
        let isOK = key == "OK"
        return ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(isOK ? MockTheme.accent : MockTheme.surface)
                .frame(height: 66)
            Group {
                if key == "⌫" {
                    Image(systemName: "delete.left.fill").foregroundStyle(MockTheme.textSecondary)
                } else if isOK {
                    Image(systemName: "checkmark").foregroundStyle(.white)
                } else {
                    Text(key).foregroundStyle(MockTheme.textPrimary)
                }
            }
            .font(.system(size: 26, weight: .semibold, design: .rounded))
        }
    }
}
