//
//  LiquidGlass.swift
//  soninho
//
//  Liquid Glass compatibility layer. On iOS 26+ every helper maps to the
//  system material (glassEffect / .glass button style / GlassEffectContainer);
//  before that it falls back to the flat dark card look, so call sites stay
//  single-path.
//

import SwiftUI

// MARK: - Glass Surface
struct GlassSurfaceModifier: ViewModifier {
    let cornerRadius: CGFloat
    let tint: Color?
    let interactive: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            content.glassEffect(glass, in: .rect(cornerRadius: cornerRadius, style: .continuous))
        } else {
            fallback(content)
        }
        #else
        fallback(content)
        #endif
    }

    #if compiler(>=6.2)
    @available(iOS 26.0, *)
    private var glass: Glass {
        var g: Glass = .regular
        if let tint { g = g.tint(tint) }
        if interactive { g = g.interactive() }
        return g
    }
    #endif

    private func fallback(_ content: Content) -> some View {
        content.background(
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(tint?.opacity(0.18) ?? AppColors.surface)
        )
    }
}

// MARK: - Glass Capsule
struct GlassCapsuleModifier: ViewModifier {
    let tint: Color?
    let interactive: Bool

    @ViewBuilder
    func body(content: Content) -> some View {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            content.glassEffect(glass, in: .capsule)
        } else {
            fallback(content)
        }
        #else
        fallback(content)
        #endif
    }

    #if compiler(>=6.2)
    @available(iOS 26.0, *)
    private var glass: Glass {
        var g: Glass = .regular
        if let tint { g = g.tint(tint) }
        if interactive { g = g.interactive() }
        return g
    }
    #endif

    private func fallback(_ content: Content) -> some View {
        content.background(Capsule().fill(tint?.opacity(0.18) ?? AppColors.surface))
    }
}

// MARK: - Glass Button
/// `.buttonStyle(.glass)` on iOS 26, the app's scale-press style before that.
struct GlassButtonModifier: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            content.buttonStyle(.glass)
        } else {
            content.buttonStyle(ScaleButtonStyle())
        }
        #else
        content.buttonStyle(ScaleButtonStyle())
        #endif
    }
}

// MARK: - Glass Container
/// Groups sibling glass shapes so they merge/morph as one material (iOS 26);
/// plain group otherwise.
struct GlassContainer<Content: View>: View {
    var spacing: CGFloat = 12
    @ViewBuilder let content: () -> Content

    var body: some View {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            GlassEffectContainer(spacing: spacing) { content() }
        } else {
            content()
        }
        #else
        content()
        #endif
    }
}

// MARK: - Soft Scroll Edge
/// iOS 26 soft scroll-edge effect (content fades under the glass bar).
struct SoftScrollEdgeModifier: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            content.scrollEdgeEffectStyle(.soft, for: .top)
        } else {
            content
        }
        #else
        content
        #endif
    }
}

// MARK: - Glass List Row
/// List row background that is a pane of glass on iOS 26 and the flat surface before.
struct GlassListRowModifier: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        #if compiler(>=6.2)
        if #available(iOS 26.0, *) {
            content.listRowBackground(
                Color.clear.glassEffect(.regular, in: .rect(cornerRadius: 14, style: .continuous))
            )
        } else {
            content.listRowBackground(AppColors.surface)
        }
        #else
        content.listRowBackground(AppColors.surface)
        #endif
    }
}

// MARK: - View Extensions
extension View {
    /// Rounded-rect Liquid Glass pane behind the view.
    func glassSurface(
        cornerRadius: CGFloat = AppSpacing.cardCornerRadius,
        tint: Color? = nil,
        interactive: Bool = false
    ) -> some View {
        modifier(GlassSurfaceModifier(cornerRadius: cornerRadius, tint: tint, interactive: interactive))
    }

    /// Capsule Liquid Glass behind the view (chips, pills, small buttons).
    func glassCapsule(tint: Color? = nil, interactive: Bool = false) -> some View {
        modifier(GlassCapsuleModifier(tint: tint, interactive: interactive))
    }

    /// System glass button style (falls back to the scale-press style).
    func glassButton() -> some View {
        modifier(GlassButtonModifier())
    }

    /// Soft scroll-edge fade under the glass navigation bar.
    func softScrollEdge() -> some View {
        modifier(SoftScrollEdgeModifier())
    }

    /// Glass pane as a List row background.
    func glassListRow() -> some View {
        modifier(GlassListRowModifier())
    }
}

// MARK: - Glass Backdrop
/// Black + sunrise-orange backdrop behind every screen — the glass panes need
/// colour behind them to refract, and pure black shows nothing.
struct GlassBackdrop: View {
    var body: some View {
        ZStack {
            AppColors.background

            RadialGradient(
                colors: [AppColors.primary.opacity(0.40), .clear],
                center: UnitPoint(x: 0.9, y: 0.0),
                startRadius: 0,
                endRadius: 400
            )

            RadialGradient(
                colors: [Color(hex: "D84315").opacity(0.28), .clear],
                center: UnitPoint(x: 0.05, y: 1.0),
                startRadius: 0,
                endRadius: 440
            )

            RadialGradient(
                colors: [Color(hex: "FF8A50").opacity(0.10), .clear],
                center: UnitPoint(x: 0.2, y: 0.35),
                startRadius: 0,
                endRadius: 300
            )
        }
        .ignoresSafeArea()
    }
}
