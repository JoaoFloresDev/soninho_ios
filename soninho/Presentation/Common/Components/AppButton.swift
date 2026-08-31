//
//  AppButton.swift
//  soninho
//
//  Created by João Flores on 28/01/26.
//

import SwiftUI

// MARK: - Button Style
enum AppButtonStyle {
    case primary
    case secondary
    case outline
    case ghost
    case destructive
}

// MARK: - App Button
struct AppButton: View {
    // MARK: - Properties
    let title: String
    let style: AppButtonStyle
    let icon: String?
    let isLoading: Bool
    let isDisabled: Bool
    let action: () -> Void

    // MARK: - Init
    init(
        title: String,
        style: AppButtonStyle = .primary,
        icon: String? = nil,
        isLoading: Bool = false,
        isDisabled: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.icon = icon
        self.isLoading = isLoading
        self.isDisabled = isDisabled
        self.action = action
    }

    // MARK: - View Body
    var body: some View {
        Button(action: {
            guard !isLoading && !isDisabled else { return }
            action()
        }) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: textColor))
                        .scaleEffect(0.8)
                } else {
                    if let icon = icon {
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .semibold))
                    }
                    Text(title)
                        .font(AppFonts.headline())
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: AppSpacing.buttonHeight)
            .foregroundStyle(textColor)
            .background(backgroundStyle)
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.buttonCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppSpacing.buttonCornerRadius, style: .continuous)
                    .stroke(borderColor, lineWidth: style == .outline ? 2 : 0)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(ScaleButtonStyle())
        .if(style == .secondary) { button in
            // Secondary actions sit on a pane of glass instead of a flat surface.
            button.glassSurface(cornerRadius: AppSpacing.buttonCornerRadius, interactive: true)
        }
        .disabled(isDisabled || isLoading)
        .opacity(isDisabled ? 0.5 : 1.0)
    }

    // MARK: - Computed Properties
    private var backgroundStyle: AnyShapeStyle {
        switch style {
        case .primary:
            return AnyShapeStyle(AppColors.primaryButtonGradient)
        case .secondary, .outline, .ghost:
            return AnyShapeStyle(Color.clear)
        case .destructive:
            return AnyShapeStyle(AppColors.destructiveButtonGradient)
        }
    }

    private var textColor: Color {
        switch style {
        case .primary:
            return .white
        case .secondary:
            return AppColors.textPrimary
        case .outline:
            return AppColors.primary
        case .ghost:
            return AppColors.primary
        case .destructive:
            return .white
        }
    }

    private var borderColor: Color {
        switch style {
        case .outline:
            return AppColors.primary
        default:
            return .clear
        }
    }
}

// MARK: - Small Button
struct SmallButton: View {
    // MARK: - Properties
    let title: String
    let icon: String?
    let action: () -> Void

    // MARK: - Init
    init(title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    // MARK: - View Body
    var body: some View {
        Button(action: {
            action()
        }) {
            HStack(spacing: 4) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 12, weight: .semibold))
                }
                Text(title)
                    .font(AppFonts.caption())
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, 12)
            .frame(minHeight: 44)
            .foregroundStyle(AppColors.primary)
            .contentShape(Capsule())
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.97))
        .glassCapsule(tint: AppColors.primary.opacity(0.3), interactive: true)
    }
}

// MARK: - Icon Button
struct IconButton: View {
    // MARK: - Properties
    let icon: String
    let size: CGFloat
    let action: () -> Void

    // MARK: - Init
    init(icon: String, size: CGFloat = 44, action: @escaping () -> Void) {
        self.icon = icon
        self.size = size
        self.action = action
    }

    // MARK: - View Body
    var body: some View {
        Button(action: {
            action()
        }) {
            Image(systemName: icon)
                .font(.system(size: size * 0.45, weight: .medium))
                .foregroundStyle(AppColors.textPrimary)
                .frame(width: size, height: size)
                .contentShape(Circle())
        }
        .buttonStyle(ScaleButtonStyle())
        .glassCapsule(interactive: true)
    }
}