//
//  AppColors.swift
//  soninho
//
//  Created by João Flores on 28/01/26.
//

import SwiftUI

// MARK: - App Colors
/// App color palette following iOS design guidelines with dark theme focus.
enum AppColors {
    // MARK: - Background Colors
    static let background = Color(hex: "000000")
    static let surface = Color(hex: "1C1C1E")
    static let surfaceSecondary = Color(hex: "2C2C2E")
    static let surfaceTertiary = Color(hex: "3A3A3C")

    // MARK: - Primary Colors
    static let primary = Color(hex: "6366F1") // Indigo - sleep themed
    static let primaryLight = Color(hex: "818CF8")
    static let primaryDark = Color(hex: "4F46E5")

    // MARK: - Accent Colors
    static let accent = Color(hex: "8B5CF6") // Purple
    static let accentSecondary = Color(hex: "A78BFA")

    // MARK: - Sleep Phase Colors
    static let deepSleep = Color(hex: "3B82F6") // Blue
    static let lightSleep = Color(hex: "60A5FA") // Light Blue
    static let remSleep = Color(hex: "A855F7") // Purple
    static let awake = Color(hex: "F97316") // Orange

    // MARK: - Semantic Colors
    static let success = Color(hex: "22C55E")
    static let warning = Color(hex: "F59E0B")
    static let error = Color(hex: "EF4444")

    // MARK: - Text Colors
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: "A1A1AA")
    static let textTertiary = Color(hex: "71717A")

    // MARK: - Gradient
    static let sleepGradient = LinearGradient(
        colors: [primary, accent],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let nightGradient = LinearGradient(
        colors: [Color(hex: "0F172A"), Color(hex: "1E1B4B")],
        startPoint: .top,
        endPoint: .bottom
    )

    static let cardGradient = LinearGradient(
        colors: [surface, surfaceSecondary],
        startPoint: .top,
        endPoint: .bottom
    )
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
