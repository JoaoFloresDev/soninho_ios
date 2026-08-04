//
//  AppColors.swift
//  soninho
//
//  Created by João Flores on 28/01/26.
//

import SwiftUI

// MARK: - App Colors
/// Alarm-app palette: sunrise orange + amber sun, light-first with adaptive dark.
enum AppColors {
    // MARK: - Background Colors
    static let background = Color(light: "FFF8F1", dark: "000000")
    static let surface = Color(light: "FFFFFF", dark: "1C1C1E")
    static let surfaceSecondary = Color(light: "F6EDE2", dark: "2C2C2E")
    static let surfaceTertiary = Color(light: "EDE1D2", dark: "3A3A3C")

    // MARK: - Primary Colors
    static let primary = Color(light: "F4511E", dark: "FF6E40") // Sunrise orange
    static let primaryLight = Color(hex: "FF8A50")
    static let primaryDark = Color(hex: "D84315")

    // MARK: - Accent Colors
    // Single interactive color across the app — same sunrise orange as primary
    // (mixing amber and orange buttons read as inconsistent).
    static let accent = Color(light: "F4511E", dark: "FF6E40")
    static let accentSecondary = Color(hex: "FF8A50")

    // MARK: - Sleep Phase Colors
    static let deepSleep = Color(light: "2563EB", dark: "3B82F6") // Blue
    static let lightSleep = Color(hex: "60A5FA") // Light Blue
    static let remSleep = Color(light: "7C3AED", dark: "A855F7") // Purple
    static let awake = Color(hex: "F97316") // Orange

    // MARK: - Semantic Colors
    static let success = Color(light: "16A34A", dark: "22C55E")
    static let warning = Color(hex: "F59E0B")
    static let error = Color(light: "DC2626", dark: "EF4444")

    // MARK: - Text Colors
    static let textPrimary = Color(light: "231A12", dark: "FFFFFF")
    static let textSecondary = Color(light: "6E6259", dark: "A1A1AA")
    static let textTertiary = Color(light: "9C9088", dark: "71717A")

    // MARK: - Gradient
    static let sleepGradient = LinearGradient(
        colors: [primary, primaryLight],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let nightGradient = LinearGradient(
        colors: [Color(light: "FFE8D1", dark: "1A1A1C"), Color(light: "FFF8F1", dark: "000000")],
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

    /// Trait-adaptive color from light/dark hex pairs.
    init(light: String, dark: String) {
        self.init(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(Color(hex: dark))
                : UIColor(Color(hex: light))
        })
    }
}
