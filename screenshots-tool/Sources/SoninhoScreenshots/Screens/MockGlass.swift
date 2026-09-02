import SwiftUI
import AppKit

// MARK: - App Palette (dark mode — the shipped look)
enum AppPalette {
    static let background = Color(hex: 0x000000)
    static let surface = Color.white.opacity(0.09)
    static let surfaceStroke = Color.white.opacity(0.16)
    static let primary = Color(hex: 0xFF6E40)
    static let primaryLight = Color(hex: 0xFF8A50)
    static let deepSleep = Color(hex: 0x3B82F6)
    static let lightSleep = Color(hex: 0x60A5FA)
    static let remSleep = Color(hex: 0xA855F7)
    static let awake = Color(hex: 0xF97316)
    static let success = Color(hex: 0x22C55E)
    static let textPrimary = Color.white
    static let textSecondary = Color(hex: 0xA1A1AA)
    static let textTertiary = Color(hex: 0x71717A)
}

extension Color {
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

// MARK: - Bundled Mascot Art
func mascotImage(_ name: String) -> Image {
    if let url = Bundle.module.url(forResource: name, withExtension: "png"),
       let ns = NSImage(contentsOf: url) {
        return Image(nsImage: ns)
    }
    return Image(systemName: "questionmark.circle")
}

// MARK: - Glass Backdrop (the app's dark backdrop with warm blobs)
struct GlassBackdropMock: View {
    var body: some View {
        ZStack {
            AppPalette.background

            RadialGradient(
                colors: [AppPalette.primary.opacity(0.28), .clear],
                center: .init(x: 0.85, y: 0.10), startRadius: 10, endRadius: 340
            )
            RadialGradient(
                colors: [Color(hex: 0x7C3AED).opacity(0.16), .clear],
                center: .init(x: 0.08, y: 0.55), startRadius: 10, endRadius: 300
            )
            RadialGradient(
                colors: [AppPalette.primaryLight.opacity(0.14), .clear],
                center: .init(x: 0.5, y: 1.0), startRadius: 10, endRadius: 380
            )
        }
        .ignoresSafeArea()
    }
}

// MARK: - Glass Card
struct GlassCard<Content: View>: View {
    var cornerRadius: CGFloat = 20
    var tint: Color? = nil
    @ViewBuilder var content: Content

    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(tint.map { AnyShapeStyle($0.opacity(0.14)) } ?? AnyShapeStyle(AppPalette.surface))
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .strokeBorder(AppPalette.surfaceStroke, lineWidth: 1)
                    )
            )
    }
}

// MARK: - Glass Capsule
struct GlassChip: View {
    let icon: String
    let text: String
    var tint: Color = AppPalette.primary

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
            Text(text)
                .font(.system(size: 12, weight: .semibold))
        }
        .foregroundStyle(tint)
        .padding(.horizontal, 11)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(tint.opacity(0.16))
                .overlay(Capsule().strokeBorder(tint.opacity(0.35), lineWidth: 1))
        )
    }
}
