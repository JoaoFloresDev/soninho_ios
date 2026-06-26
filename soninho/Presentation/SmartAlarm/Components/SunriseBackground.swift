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
            // Night base
            LinearGradient(
                colors: [Color(hex: "0B1026"), Color(hex: "1E1B4B"), Color(hex: "312E81")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            // Sunrise wash, faded in by progress
            LinearGradient(
                colors: [Color(hex: "1E1B4B"), Color(hex: "7C3AED"), Color(hex: "F97316"), Color(hex: "FBBF24")],
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
