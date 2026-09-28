//
//  PremiumTag.swift
//  soninho
//
//  Small badge that tells a subscriber, at a glance, that Premium is on.
//

import SwiftUI

// MARK: - Premium Tag
struct PremiumTag: View {
    // MARK: - View Body
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "crown.fill")
                .font(.system(size: 10, weight: .bold))
            Text("PREMIUM")
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .tracking(0.6)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 9)
        .padding(.vertical, 5)
        .background(Capsule().fill(AppColors.primaryButtonGradient))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Premium"))
        .accessibilityIdentifier("premium.tag")
    }
}
