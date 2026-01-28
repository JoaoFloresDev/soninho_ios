//
//  View+Extensions.swift
//  soninho
//
//  Created by João Flores on 28/01/26.
//

import SwiftUI

// MARK: - View Extensions
extension View {
    // MARK: - Card Style
    func cardStyle(
        padding: CGFloat = AppSpacing.cardPadding,
        cornerRadius: CGFloat = AppSpacing.cardCornerRadius
    ) -> some View {
        self
            .padding(padding)
            .background(AppColors.surface)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    // MARK: - Gradient Card Style
    func gradientCardStyle(
        padding: CGFloat = AppSpacing.cardPadding,
        cornerRadius: CGFloat = AppSpacing.cardCornerRadius
    ) -> some View {
        self
            .padding(padding)
            .background(AppColors.cardGradient)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    // MARK: - Glass Morphism
    func glassStyle(
        cornerRadius: CGFloat = AppSpacing.cardCornerRadius
    ) -> some View {
        self
            .background(.ultraThinMaterial.opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    // MARK: - Shadow
    func softShadow(
        color: Color = .black.opacity(0.15),
        radius: CGFloat = 10,
        x: CGFloat = 0,
        y: CGFloat = 5
    ) -> some View {
        self.shadow(color: color, radius: radius, x: x, y: y)
    }

    // MARK: - Glow Effect (Black shadows only per design guidelines)
    func glowEffect(radius: CGFloat = 20) -> some View {
        self
            .shadow(color: .black.opacity(0.2), radius: radius)
            .shadow(color: .black.opacity(0.1), radius: radius * 2)
    }

    // MARK: - Shimmer Loading
    func shimmer(isActive: Bool = true) -> some View {
        self.modifier(ShimmerModifier(isActive: isActive))
    }

    // MARK: - Animated Button
    func animatedButton(scale: CGFloat = 0.95) -> some View {
        self.modifier(AnimatedButtonModifier(scale: scale))
    }

    // MARK: - Conditional Modifier
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    // MARK: - Hide Keyboard
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    // MARK: - On First Appear
    func onFirstAppear(perform action: @escaping () -> Void) -> some View {
        self.modifier(FirstAppearModifier(action: action))
    }

    // MARK: - Screen Padding
    func screenPadding() -> some View {
        self.padding(.horizontal, AppSpacing.screenHorizontal)
    }
}

// MARK: - Shimmer Modifier
struct ShimmerModifier: ViewModifier {
    let isActive: Bool
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        if isActive {
            content
                .overlay(
                    GeometryReader { geometry in
                        LinearGradient(
                            colors: [
                                .clear,
                                .white.opacity(0.3),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: geometry.size.width * 2)
                        .offset(x: -geometry.size.width + phase * geometry.size.width * 2)
                    }
                    .mask(content)
                )
                .onAppear {
                    withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                        phase = 1
                    }
                }
        } else {
            content
        }
    }
}

// MARK: - Animated Button Modifier
struct AnimatedButtonModifier: ViewModifier {
    let scale: CGFloat

    func body(content: Content) -> some View {
        content
            .buttonStyle(ScaleButtonStyle(scale: scale))
    }
}

// MARK: - Scale Button Style
struct ScaleButtonStyle: ButtonStyle {
    let scale: CGFloat

    init(scale: CGFloat = 0.95) {
        self.scale = scale
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - First Appear Modifier
struct FirstAppearModifier: ViewModifier {
    let action: () -> Void
    @State private var hasAppeared = false

    func body(content: Content) -> some View {
        content
            .onAppear {
                guard !hasAppeared else { return }
                hasAppeared = true
                action()
            }
    }
}
