//
//  PremiumBadge.swift
//  soninho
//
//  Subscriber status shown in the navigation bar.
//

import SwiftUI

// MARK: - Premium Badge
/// Subscriber status for a navigation bar: a gold crown and the word, sized like a
/// bar button so it sits level with "+" on the other side.
struct PremiumBadge: View {
    // MARK: - Constants
    private static let gold = Color(hex: "FFC94A")

    // MARK: - View Body
    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: "crown.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Self.gold)
            Text("Premium")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(AppColors.textPrimary)
        }
        .padding(.horizontal, 4)
        .frame(minHeight: 44)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Premium"))
    }
}

// MARK: - Premium UI
/// Whether the premium look should show. `-QAPremiumUI` forces it in DEBUG builds so
/// the subscriber screens can be checked in the simulator without a purchase.
enum PremiumUI {
    static var isForced: Bool {
        #if DEBUG
        return ProcessInfo.processInfo.arguments.contains("-QAPremiumUI")
        #else
        return false
        #endif
    }
}
