//
//  WakeGreetingView.swift
//  soninho
//
//  Full-screen animated greeting shown when a sleep session ends — wishes the
//  user a good morning or a good rest of the day depending on the time.
//

import SwiftUI
import UIKit

// MARK: - Wake Greeting View
struct WakeGreetingView: View {
    // MARK: - Properties
    let onDismiss: () -> Void

    @State private var appeared = false
    @State private var glow = false

    private let hour = Calendar.current.component(.hour, from: Date())

    // MARK: - Computed Properties
    private var isMorning: Bool { (5..<12).contains(hour) }

    private var icon: String {
        if isMorning { return "sunrise.fill" }
        if (12..<18).contains(hour) { return "sun.max.fill" }
        return "moon.stars.fill"
    }

    private var greeting: String {
        isMorning
            ? String(localized: "wake_greeting_morning")
            : String(localized: "wake_greeting_rest")
    }

    private var gradientColors: [Color] {
        if isMorning {
            return [Color(hex: "FFD194"), Color(hex: "F97316"), Color(hex: "4F46E5")]
        }
        if (12..<18).contains(hour) {
            return [Color(hex: "60A5FA"), Color(hex: "4F46E5"), Color(hex: "312E81")]
        }
        return [Color(hex: "312E81"), Color(hex: "4C1D95"), Color(hex: "0B1026")]
    }

    // MARK: - View Body
    var body: some View {
        ZStack {
            LinearGradient(colors: gradientColors, startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()

            VStack(spacing: 28) {
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.16))
                        .frame(width: 150, height: 150)
                        .scaleEffect(glow ? 1.12 : 0.95)

                    Image(systemName: icon)
                        .font(.system(size: 76))
                        .foregroundStyle(.white)
                        .shadow(color: .black.opacity(0.25), radius: 12, y: 4)
                }
                .scaleEffect(appeared ? 1 : 0.5)
                .opacity(appeared ? 1 : 0)

                VStack(spacing: 10) {
                    Text(greeting)
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .multilineTextAlignment(.center)
                        .shadow(color: .black.opacity(0.2), radius: 8, y: 2)

                    Text(String(localized: "wake_greeting_subtitle"))
                        .font(AppFonts.body())
                        .foregroundStyle(.white.opacity(0.85))
                        .multilineTextAlignment(.center)
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 24)
            }
            .padding(.horizontal, 40)
        }
        .contentShape(Rectangle())
        .onTapGesture { onDismiss() }
        .onAppear { start() }
    }

    // MARK: - Private Methods
    private func start() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        withAnimation(.spring(response: 0.7, dampingFraction: 0.7)) {
            appeared = true
        }
        withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
            glow = true
        }
        // Auto-dismiss after a few seconds.
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            onDismiss()
        }
    }
}
