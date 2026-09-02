import SwiftUI
import AppKit
import GambitScreenshotKit

// MARK: - Render Pipeline (TEMPLATE — customize for your app)
//
// Two modes:
//   • initial → 1 set per locale at iPhone 6.9" → fastlane sync_screenshots_initial
//   • abtest  → 3 treatments × N locales × 5 screens at the display type that
//               matches the app's existing default product page → upload_ppo.py
//
// CHANGE the `outputBase` path below to match your app's fastlane folder.
// CHANGE `device` for the abtest case to match your default product page's
// display type (query ASC if unsure — see the /generate-a-b-test skill).

enum RenderMode { case abtest, initial }

struct PipelineError: Error, CustomStringConvertible {
    let description: String
}

/// Fail fast if any headline still contains a TODO placeholder. Without this,
/// the renderer will happily emit screenshots with literal "TODO:" text on
/// them — and the agent might miss it on a quick visual scan. Treatments
/// not used by the active mode are not validated.
@MainActor
func validateNoTODOs(in treatments: [TreatmentCopy], locales: [String]) throws {
    var problems: [String] = []
    for t in treatments {
        let slots: [(String, LocalizedHeadlines)] = [
            ("home",       t.home),
            ("feature1",   t.feature1),
            ("feature2",   t.feature2),
            ("settings",   t.settings),
            ("onboarding", t.onboarding)
        ]
        for (slotName, slot) in slots {
            for locale in locales {
                let headline = slot[locale]?.text ?? ""
                if headline.isEmpty || headline.uppercased().contains("TODO") {
                    problems.append("  treatment \(t.id) / \(slotName) / \(locale): \(headline.isEmpty ? "<empty>" : headline)")
                }
            }
        }
    }
    if !problems.isEmpty {
        throw PipelineError(description:
            "Headlines.swift still has \(problems.count) TODO/empty headline(s) for the active mode:\n" +
            problems.joined(separator: "\n") +
            "\nFill them in (with user-approved copy) before rendering."
        )
    }
}

@MainActor
func runFullRenderPipeline(mode: RenderMode) throws {
    let outputBase = URL(fileURLWithPath: NSString(string: "../fastlane/screenshots").expandingTildeInPath)
    try FileManager.default.createDirectory(at: outputBase, withIntermediateDirectories: true)

    // iPhone 6.9" (1320×2868) — the newest required App Store display size
    // (iPhone 16 Pro Max). This is the primary size Apple shows now.
    let device: DeviceKind = .iPhone6_9
    let canvas = device.canvasSize
    let locales = ["en-US", "pt-BR", "es-ES"]

    let contentLocaleMap: [String: String] = [:]

    let treatments: [TreatmentCopy] = (mode == .initial) ? [Headlines.treatmentA] : Headlines.all

    // Forcing function: never render placeholder copy.
    try validateNoTODOs(in: treatments, locales: locales)

    var totalRendered = 0

    for treatment in treatments {
        let baseDir: URL = (mode == .initial)
            ? outputBase.appendingPathComponent("initial")
            : outputBase.appendingPathComponent("treatment_\(treatment.id)")

        for locale in locales {
            let uploadDir = baseDir.appendingPathComponent(locale)
            try FileManager.default.createDirectory(at: uploadDir, withIntermediateDirectories: true)

            let contentLocale = contentLocaleMap[locale] ?? locale

            switch mode {
            case .initial:
                try renderLocaleSet(treatment: treatment, locale: contentLocale, outputLocale: locale,
                                    device: device, canvas: canvas, outputDir: uploadDir, validationDir: nil)
                totalRendered += 5
                print("✅ initial / \(locale) — 5 PNGs done")

            case .abtest:
                let validationDir = baseDir.appendingPathComponent("_validation")
                try FileManager.default.createDirectory(at: validationDir, withIntermediateDirectories: true)
                try renderLocaleSet(treatment: treatment, locale: contentLocale, outputLocale: locale,
                                    device: device, canvas: canvas, outputDir: uploadDir, validationDir: validationDir)
                totalRendered += 6
                print("✅ treatment_\(treatment.id) / \(locale) — 5 upload + 1 validation done")
            }
        }
    }

    print("\n\(totalRendered) PNGs rendered at: \(outputBase.path)")
}

// MARK: - Per-Locale Rendering
//
// Each treatment now differs in ORDER, LAYOUT and COPY — not just background:
//   A (orange): house look — verb-split + breakout, order main→smartwake→mission→sounds→report
//   B (violet): benefit — single-block headline + subheadline, NO breakout,
//               device scaled up bleeding off canvas + orange rim glow,
//               order report→smartwake→main→mission→sounds (outcome first)
//   C (navy):   specific — verb-split + breakout, 3D-tilted device (±7°),
//               order mission→smartwake→sounds→main→report (mission hook first)

struct SlotSpec {
    let fileName: String
    let headlineKey: String
    let split: Bool
    let tilt: Double
    let scaleMult: CGFloat
    let rimGlow: Bool
    let hasBreakout: Bool
    let breakoutY: CGFloat
}

@MainActor
func screenView(for key: String, locale: String) -> AnyView {
    switch key {
    case "home":     return AnyView(MainScreen(locale: locale))
    case "feature1": return AnyView(TrackingScreen(locale: locale))
    case "feature2": return AnyView(Feature1Screen(locale: locale))
    case "settings": return AnyView(SoundsScreen(locale: locale))
    default:         return AnyView(Feature2Screen(locale: locale))
    }
}

@MainActor
func breakoutView(for key: String, locale: String, y: CGFloat, canvas: CGSize) -> AnyView {
    switch key {
    case "home":     return breakoutForeground(AlarmCardMock(locale: locale), y: y, canvas: canvas)
    case "feature1": return breakoutForeground(WakeWindowCardMock(locale: locale), y: y, canvas: canvas)
    case "feature2": return breakoutForeground(MissionCardMock(locale: locale), y: y, canvas: canvas)
    case "settings": return breakoutForeground(GradualVolumeCardMock(locale: locale), y: y, canvas: canvas)
    default:         return breakoutForeground(HypnogramCardMock(locale: locale), y: y, canvas: canvas)
    }
}

func layoutSpecs(for treatmentID: String) -> [SlotSpec] {
    switch treatmentID {
    case "A":
        return [
            SlotSpec(fileName: "01_main_iphone.png",      headlineKey: "home",       split: true, tilt: 0, scaleMult: 1.0, rimGlow: false, hasBreakout: true, breakoutY: 2260),
            SlotSpec(fileName: "02_smartwake_iphone.png", headlineKey: "feature1",   split: true, tilt: 0, scaleMult: 1.0, rimGlow: false, hasBreakout: true, breakoutY: 2100),
            SlotSpec(fileName: "03_mission_iphone.png",   headlineKey: "feature2",   split: true, tilt: 0, scaleMult: 1.0, rimGlow: false, hasBreakout: true, breakoutY: 2080),
            SlotSpec(fileName: "04_sounds_iphone.png",    headlineKey: "settings",   split: true, tilt: 0, scaleMult: 1.0, rimGlow: false, hasBreakout: true, breakoutY: 2080),
            SlotSpec(fileName: "05_report_iphone.png",    headlineKey: "onboarding", split: true, tilt: 0, scaleMult: 1.0, rimGlow: false, hasBreakout: true, breakoutY: 1990)
        ]
    case "B":
        return [
            SlotSpec(fileName: "01_report_iphone.png",    headlineKey: "onboarding", split: false, tilt: 0, scaleMult: 1.18, rimGlow: true, hasBreakout: false, breakoutY: 0),
            SlotSpec(fileName: "02_smartwake_iphone.png", headlineKey: "feature1",   split: false, tilt: 0, scaleMult: 1.18, rimGlow: true, hasBreakout: false, breakoutY: 0),
            SlotSpec(fileName: "03_main_iphone.png",      headlineKey: "home",       split: false, tilt: 0, scaleMult: 1.18, rimGlow: true, hasBreakout: false, breakoutY: 0),
            SlotSpec(fileName: "04_mission_iphone.png",   headlineKey: "feature2",   split: false, tilt: 0, scaleMult: 1.18, rimGlow: true, hasBreakout: false, breakoutY: 0),
            SlotSpec(fileName: "05_sounds_iphone.png",    headlineKey: "settings",   split: false, tilt: 0, scaleMult: 1.18, rimGlow: true, hasBreakout: false, breakoutY: 0)
        ]
    default: // C
        return [
            SlotSpec(fileName: "01_mission_iphone.png",   headlineKey: "feature2",   split: true, tilt:  10, scaleMult: 1.0, rimGlow: false, hasBreakout: true, breakoutY: 2080),
            SlotSpec(fileName: "02_smartwake_iphone.png", headlineKey: "feature1",   split: true, tilt: -10, scaleMult: 1.0, rimGlow: false, hasBreakout: true, breakoutY: 2100),
            SlotSpec(fileName: "03_sounds_iphone.png",    headlineKey: "settings",   split: true, tilt:  10, scaleMult: 1.0, rimGlow: false, hasBreakout: true, breakoutY: 2080),
            SlotSpec(fileName: "04_main_iphone.png",      headlineKey: "home",       split: true, tilt: -10, scaleMult: 1.0, rimGlow: false, hasBreakout: true, breakoutY: 2260),
            SlotSpec(fileName: "05_report_iphone.png",    headlineKey: "onboarding", split: true, tilt:  10, scaleMult: 1.0, rimGlow: false, hasBreakout: true, breakoutY: 1990)
        ]
    }
}

@MainActor
func renderLocaleSet(
    treatment: TreatmentCopy,
    locale: String,
    outputLocale: String,
    device: DeviceKind,
    canvas: CGSize,
    outputDir: URL,
    validationDir: URL?
) throws {
    let theme = solidTheme(for: treatment.id)
    let specs = layoutSpecs(for: treatment.id)
    var firstThree: [URL] = []

    for (index, spec) in specs.enumerated() {
        let url = outputDir.appendingPathComponent(spec.fileName)
        let headline = treatment.headlines(for: spec.headlineKey)[locale] ?? Headline(text: "", highlight: nil)
        let subheadline = treatment.subtitles[spec.headlineKey]?[locale]
        let foreground: AnyView? = spec.hasBreakout
            ? breakoutView(for: spec.headlineKey, locale: locale, y: spec.breakoutY, canvas: canvas)
            : nil

        let view = MarketingScreen(
            device: device,
            headline: headline.text,
            highlightWord: nil,
            slotIndex: index,
            totalSlots: specs.count,
            theme: theme,
            foreground: foreground,
            subheadline: subheadline,
            deviceTilt: spec.tilt,
            splitFirstWord: spec.split,
            deviceScaleMultiplier: spec.scaleMult,
            deviceRimGlow: spec.rimGlow ? AppPalette.primary.opacity(0.55) : nil
        ) { screenView(for: spec.headlineKey, locale: locale) }

        try render(view: view, canvas: canvas, scale: 1.0, to: url)
        if index < 3 { firstThree.append(url) }
    }

    // App Store listing mockup (validation only, abtest mode only)
    if let validationDir = validationDir {
        let urlMockup = validationDir.appendingPathComponent("06_appstore_listing_\(outputLocale).png")
        try render(
            view: AppStoreListingMockup(
                appName: LocalizedListing.appName[locale] ?? "TODO: App Name",
                subtitle: LocalizedListing.subtitle[locale] ?? "TODO: Subtitle",
                searchQuery: searchKeyword(locale: locale),
                screenshotURLs: firstThree
            ) {
                DefaultAppIcon(size: 110)
            },
            canvas: device.screenPointSize,
            scale: 3.0,
            to: urlMockup
        )
    }
}

// MARK: - Search Keyword for App Store Mockup

func searchKeyword(locale: String) -> String {
    switch locale {
    case "pt-BR":          return "sono"
    case "es-ES", "es-MX": return "sueño"
    default:               return "sleep tracker"
    }
}

// MARK: - Per-Treatment Solid Theme

/// Maps each treatment to its flat solid-color backdrop.
func solidTheme(for treatmentID: String) -> MarketingTheme {
    switch treatmentID {
    case "A": return .soninhoSolidA
    case "B": return .soninhoSolidB
    default:  return .soninhoSolidC
    }
}

// MARK: - Marketing Wrapper Helper

@MainActor
@ViewBuilder
func marketing<Content: View>(
    device: DeviceKind,
    slot: Int,
    totalSlots: Int,
    headline: Headline?,
    theme: MarketingTheme,
    foreground: AnyView? = nil,
    @ViewBuilder content: () -> Content
) -> some View {
    let h = headline ?? Headline(text: "", highlight: nil)
    MarketingScreen(
        device: device,
        headline: h.text,
        highlightWord: nil,
        slotIndex: slot,
        totalSlots: totalSlots,
        theme: theme,
        foreground: foreground,
        splitFirstWord: true,   // big first word + smaller ≤3-word line (steps pattern)
        content: content
    )
}

// MARK: - Render Helper

@MainActor
func render<V: View>(view: V, canvas: CGSize, scale: CGFloat, to url: URL) throws {
    let sized = view.frame(width: canvas.width, height: canvas.height)
    let renderer = ImageRenderer(content: sized)
    renderer.scale = scale
    renderer.proposedSize = ProposedViewSize(width: canvas.width, height: canvas.height)

    guard let cg = renderer.cgImage else {
        throw NSError(domain: "Screenshots", code: 1,
                      userInfo: [NSLocalizedDescriptionKey: "ImageRenderer returned nil for \(url.lastPathComponent)"])
    }
    let bitmap = NSBitmapImageRep(cgImage: cg)
    bitmap.size = NSSize(width: cg.width, height: cg.height)
    guard let data = bitmap.representation(using: .png, properties: [:]) else {
        throw NSError(domain: "Screenshots", code: 2,
                      userInfo: [NSLocalizedDescriptionKey: "PNG encoding failed for \(url.lastPathComponent)"])
    }
    try data.write(to: url)
}

MainActor.assumeIsolated {
    let mode: RenderMode = CommandLine.arguments.contains("initial") ? .initial : .abtest
    print(mode == .initial
          ? "🎬 Mode: INITIAL — single set per locale at 6.9\" (default product page)"
          : "🧪 Mode: A/B TEST — 3 treatments × N locales (PPO experiment)")
    do {
        try runFullRenderPipeline(mode: mode)
    } catch {
        print("❌ Pipeline failed: \(error)")
        exit(1)
    }
}
