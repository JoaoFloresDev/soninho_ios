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
    let totalSlots = 5
    // Each treatment renders on its own flat solid-color backdrop.
    let theme = solidTheme(for: treatment.id)

    // Slot 1: Main / Home
    let url1 = outputDir.appendingPathComponent("01_main_iphone.png")
    try render(view: marketing(device: device, slot: 0, totalSlots: totalSlots,
                                headline: treatment.home[locale], theme: theme) { MainScreen(locale: locale) },
                canvas: canvas, scale: 1.0, to: url1)

    // Slot 2: Feature 1
    let url2 = outputDir.appendingPathComponent("02_feature1_iphone.png")
    try render(view: marketing(device: device, slot: 1, totalSlots: totalSlots,
                                headline: treatment.feature1[locale], theme: theme) { Feature1Screen(locale: locale) },
                canvas: canvas, scale: 1.0, to: url2)

    // Slot 3: Feature 2
    let url3 = outputDir.appendingPathComponent("03_feature2_iphone.png")
    try render(view: marketing(device: device, slot: 2, totalSlots: totalSlots,
                                headline: treatment.feature2[locale], theme: theme) { Feature2Screen(locale: locale) },
                canvas: canvas, scale: 1.0, to: url3)

    // Slot 4: Settings
    let url4 = outputDir.appendingPathComponent("04_settings_iphone.png")
    try render(view: marketing(device: device, slot: 3, totalSlots: totalSlots,
                                headline: treatment.settings[locale], theme: theme) { SettingsScreen(locale: locale) },
                canvas: canvas, scale: 1.0, to: url4)

    // Slot 5: Onboarding
    let url5 = outputDir.appendingPathComponent("05_onboarding_iphone.png")
    try render(view: marketing(device: device, slot: 4, totalSlots: totalSlots,
                                headline: treatment.onboarding[locale], theme: theme) { OnboardingScreen(locale: locale) },
                canvas: canvas, scale: 1.0, to: url5)

    // Slot 6: App Store listing mockup (validation only, abtest mode only)
    if let validationDir = validationDir {
        let urlMockup = validationDir.appendingPathComponent("06_appstore_listing_\(outputLocale).png")
        try render(
            view: AppStoreListingMockup(
                appName: LocalizedListing.appName[locale] ?? "TODO: App Name",
                subtitle: LocalizedListing.subtitle[locale] ?? "TODO: Subtitle",
                searchQuery: searchKeyword(locale: locale),
                screenshotURLs: [url1, url2, url3]
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
