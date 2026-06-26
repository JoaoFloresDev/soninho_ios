import SwiftUI
import GambitScreenshotKit

// MARK: - Mock Theme
//
// Mirrors soninho/Core/Theme/AppColors.swift (dark indigo/purple sleep
// theme). Keep RGB in sync if the real AppColors change.

enum MockTheme {
    // MARK: - Background Colors
    static let background = Color(red: 0.00, green: 0.00, blue: 0.00)
    static let surface = Color(red: 0.110, green: 0.110, blue: 0.118)       // #1C1C1E
    static let surfaceSecondary = Color(red: 0.173, green: 0.173, blue: 0.180) // #2C2C2E
    static let surfaceTertiary = Color(red: 0.227, green: 0.227, blue: 0.235) // #3A3A3C

    // MARK: - Primary Colors
    static let primary = Color(red: 0.388, green: 0.400, blue: 0.945)       // #6366F1
    static let primaryLight = Color(red: 0.506, green: 0.549, blue: 0.973)  // #818CF8
    static let primaryDark = Color(red: 0.310, green: 0.275, blue: 0.898)   // #4F46E5

    // MARK: - Accent Colors
    static let accent = Color(red: 0.545, green: 0.361, blue: 0.965)        // #8B5CF6
    static let accentSecondary = Color(red: 0.655, green: 0.545, blue: 0.980) // #A78BFA

    // MARK: - Sleep Phase Colors
    static let deepSleep = Color(red: 0.231, green: 0.510, blue: 0.965)     // #3B82F6
    static let lightSleep = Color(red: 0.376, green: 0.647, blue: 0.980)    // #60A5FA
    static let remSleep = Color(red: 0.659, green: 0.333, blue: 0.969)      // #A855F7
    static let awake = Color(red: 0.976, green: 0.451, blue: 0.086)         // #F97316

    // MARK: - Semantic Colors
    static let success = Color(red: 0.133, green: 0.773, blue: 0.369)       // #22C55E
    static let warning = Color(red: 0.961, green: 0.620, blue: 0.043)       // #F59E0B
    static let error = Color(red: 0.937, green: 0.267, blue: 0.267)         // #EF4444

    // MARK: - Text Colors
    static let textPrimary = Color.white
    static let textSecondary = Color(red: 0.631, green: 0.631, blue: 0.667) // #A1A1AA
    static let textTertiary = Color(red: 0.443, green: 0.443, blue: 0.478)  // #71717A

    // MARK: - Gradients
    static let sleepGradient = LinearGradient(
        colors: [primary, accent],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let phaseGradient = LinearGradient(
        colors: [deepSleep, lightSleep, remSleep],
        startPoint: .leading,
        endPoint: .trailing
    )
}

// MARK: - Marketing Theme
//
// Deep-indigo "starry-night" backdrop used by the MarketingScreen wrapper.

extension MarketingTheme {
    static let soninho = MarketingTheme(
        baseColor: Color(red: 0.05, green: 0.04, blue: 0.18),
        blobBright: Color(red: 0.22, green: 0.18, blue: 0.55),
        blobMid:    Color(red: 0.16, green: 0.12, blue: 0.45),
        blobDeep:   Color(red: 0.10, green: 0.08, blue: 0.32),
        rayLeft:    Color(red: 0.55, green: 0.45, blue: 1.00).opacity(0.20),
        rayRight:   Color(red: 0.65, green: 0.40, blue: 0.95).opacity(0.16),
        highlightGlow: Color(red: 0.55, green: 0.42, blue: 1.00).opacity(0.50)
    )
}

// MARK: - Solid-Color Marketing Themes (A/B test)
//
// Flat single-color backdrops (no blobs, rays, or vignette) — one solid
// night-tone per treatment so the three creatives read as visually distinct
// at a glance. White headline keeps a soft glow + black depth shadow for
// legibility on the solid fill.

extension MarketingTheme {
    /// Builds a flat solid-color backdrop: kills every atmospheric layer
    /// (blobs/rays/vignette) so only `base` shows behind the device.
    static func soninhoSolid(_ base: Color, glow: Color) -> MarketingTheme {
        MarketingTheme(
            baseColor: base,
            blobBright: .clear,
            blobMid: .clear,
            blobDeep: .clear,
            rayLeft: .clear,
            rayRight: .clear,
            highlightGlow: glow,
            headlineTop: .white,
            headlineBottom: Color(red: 0.96, green: 0.94, blue: 1.00),
            headlineDepthShadow: Color.black.opacity(0.35),
            blobBlendMode: .screen,
            vignetteColor: .clear,
            deviceContactShadow: Color.black.opacity(0.55)
        )
    }

    /// Treatment A — striking vivid violet (#7C3AED). Pops on the App Store
    /// grid without losing the night/sleep association; white heavy headline
    /// stays legible thanks to the depth shadow.
    static let soninhoSolidA = soninhoSolid(
        Color(red: 0.486, green: 0.227, blue: 0.929),
        glow: Color(red: 0.75, green: 0.55, blue: 1.00).opacity(0.40)
    )

    /// Treatment B — royal violet (#2D0E5F).
    static let soninhoSolidB = soninhoSolid(
        Color(red: 0.176, green: 0.055, blue: 0.373),
        glow: Color(red: 0.60, green: 0.42, blue: 1.00).opacity(0.35)
    )

    /// Treatment C — midnight navy (#0C1733).
    static let soninhoSolidC = soninhoSolid(
        Color(red: 0.047, green: 0.090, blue: 0.200),
        glow: Color(red: 0.35, green: 0.55, blue: 1.00).opacity(0.32)
    )
}
