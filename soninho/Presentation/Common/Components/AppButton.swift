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
            HapticManager.mediumImpact()
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
            .foregroundColor(textColor)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: AppSpacing.buttonCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppSpacing.buttonCornerRadius, style: .continuous)
                    .stroke(borderColor, lineWidth: style == .outline ? 2 : 0)
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(isDisabled || isLoading)
        .opacity(isDisabled ? 0.5 : 1.0)
    }

    // MARK: - Computed Properties
    private var backgroundColor: Color {
        switch style {
        case .primary:
            return AppColors.primary
        case .secondary:
            return AppColors.surface
        case .outline:
            return .clear
        case .ghost:
            return .clear
        case .destructive:
            return AppColors.error
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
            HapticManager.lightImpact()
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
            .padding(.vertical, 8)
            .foregroundColor(AppColors.primary)
            .background(AppColors.primary.opacity(0.15))
            .clipShape(Capsule())
        }
        .buttonStyle(ScaleButtonStyle(scale: 0.97))
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
            HapticManager.lightImpact()
            action()
        }) {
            Image(systemName: icon)
                .font(.system(size: size * 0.45, weight: .medium))
                .foregroundColor(AppColors.textPrimary)
                .frame(width: size, height: size)
                .background(AppColors.surface)
                .clipShape(Circle())
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 16) {
        AppButton(title: "Start Sleep", style: .primary, icon: "moon.fill") {}
        AppButton(title: "Secondary", style: .secondary) {}
        AppButton(title: "Outline", style: .outline) {}
        AppButton(title: "Loading", style: .primary, isLoading: true) {}
        AppButton(title: "Disabled", style: .primary, isDisabled: true) {}

        HStack {
            SmallButton(title: "Filter", icon: "line.3.horizontal.decrease") {}
            IconButton(icon: "gearshape.fill") {}
        }
    }
    .padding()
    .background(AppColors.background)
}
