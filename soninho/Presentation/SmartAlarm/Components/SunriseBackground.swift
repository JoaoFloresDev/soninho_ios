//
//  SunriseBackground.swift
//  soninho
//
//  Animated night → sunrise backdrop for the gradual wake. `progress` drives
//  a warm glow rising from the horizon as the alarm ramps up.
//

import SwiftUI

// MARK: - Sunrise Background
struct SunriseBackground: View {
    // MARK: - Properties
    /// 0 = deep night, 1 = full sunrise.
    var progress: Double

    // MARK: - View Body
    var body: some View {
        ZStack {
            // Night base — black with a faint warm ember low on the screen.
            LinearGradient(
                colors: [Color(hex: "000000"), Color(hex: "140A05"), Color(hex: "331507")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Sunrise wash, faded in by progress
            LinearGradient(
                colors: [Color(hex: "1A0C05"), Color(hex: "8A2E0C"), Color(hex: "F97316"), Color(hex: "FBBF24")],
                startPoint: .top,
                endPoint: .bottom
            )
            .opacity(progress)
            .ignoresSafeArea()

            // Sun glow rising from the horizon
            GeometryReader { geo in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(hex: "FFE8B0").opacity(0.9), Color(hex: "F59E0B").opacity(0.0)],
                            center: .center,
                            startRadius: 0,
                            endRadius: geo.size.width * 0.7
                        )
                    )
                    .frame(width: geo.size.width * 1.4, height: geo.size.width * 1.4)
                    .position(
                        x: geo.size.width / 2,
                        y: geo.size.height * (1.15 - 0.35 * progress)
                    )
                    .opacity(progress)
                    .blur(radius: 8)
            }
            .ignoresSafeArea()
        }
    }
}
